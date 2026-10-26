#!/usr/bin/env -S nix shell nixpkgs#python3 -c python3
"""Exercise real host checks and pinned korrid's supported plugin-run path."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

host, korrid, *packages = sys.argv[1:]
cache = 'https://miniarray.github.io/korri-plugins/'
checks = 0
for package in packages:
    root = Path(package)
    manifest = json.loads((root / 'manifest.json').read_text())
    program = Path(manifest['files']['game'])
    slug = program.name
    runner = f'@miniarray:{slug}/{slug}'
    digest = 'sha256:' + hashlib.sha256(program.read_bytes()).hexdigest()
    declaration = (root / 'plugin.ts').read_text()
    assert '@GAME_HASH@' not in declaration and digest in declaration
    receipt = json.loads(subprocess.check_output([host, 'seed', package, cache], text=True))
    assert receipt['id'] == f'@miniarray:{slug}'
    assert manifest['publisher'] == {'namespace': '@miniarray'}
    assert manifest['services'] == {} and manifest['ports'] == {}
    notices = Path(manifest['files']['notices'])
    for filename in ['GODOT-LICENSE.txt', 'GODOT-COPYRIGHT.json', 'GODOT-LICENSES.json']:
        assert (notices / filename).stat().st_size > 0
    if slug != 'credence':
        assert list((notices / 'covered-source').glob('godot-*.crate'))
        assert (notices / 'MPL-2.0.txt').stat().st_size > 0
        assert (notices / 'rust-standard-library' / 'COPYRIGHT-library.html').stat().st_size > 0
        assert list((notices / 'rust-standard-library').glob('LICENSE-MIT-*.txt'))
        assert list((notices / 'rust-standard-library').glob('LICENSE-APACHE-*.txt'))
    checks += 1
    with tempfile.TemporaryDirectory(prefix='native-launch-check-') as temporary:
        account = str(Path(temporary) / 'account')
        save = str(Path(temporary) / 'save')
        # Pinned Core exposes plugin-run, not the later plugin-prepare CLI.
        # A real capture executable records its argv/environment/cwd after
        # production sandbox preparation and execution. No game/display starts.
        capture = Path(temporary) / 'capture.py'
        capture.write_text('#!' + sys.executable + '\n' +
            'import json, os, sys\n' +
            'print(json.dumps({"args":sys.argv[1:],"home":os.environ.get("HOME"),"cwd":os.getcwd(),"xdg":[os.environ.get(key) for key in ["XDG_DATA_HOME","XDG_CONFIG_HOME","XDG_CACHE_HOME"]]}))\n')
        capture.chmod(0o755)
        input_data = {
            'runnerId': runner, 'program': str(capture), 'contentPath': str(capture),
            'accountRoot': account, 'saveRoot': save, 'cacheRoot': str(Path(temporary) / 'cache'),
            'files': manifest['files'], 'artifacts': {},
        }
        command = [korrid, 'plugin-run', str(root / 'plugin.ts'), json.dumps(input_data), '{"modifiers":[]}', digest]
        environment = os.environ | {key: '/must-be-unset' for key in ['XDG_DATA_HOME', 'XDG_CONFIG_HOME', 'XDG_CACHE_HOME']}
        captured = json.loads(subprocess.check_output(command, env=environment, text=True))
        assert captured['args'] == ['--fullscreen']
        assert captured['home'] == account and captured['cwd'] == account
        assert captured['xdg'] == [None, None, None]
        assert Path(account).is_dir() and not Path(save).exists()
        checks += 1
        for change in [
            {'runnerId': '@miniarray:other/other'},
            {'corePath': '/nix/store/unexpected/core.so'},
            {'contentPath': '/tmp/different-launcher'},
            {'contentPath': None},
            {'accountRoot': 'relative'},
            {'accountRoot': '/tmp/with\0nul'},
            {'overrides': {'settings': {'unknown': True}}},
            {'overrides': {'config': {}}},
        ]:
            altered = input_data | change
            result = subprocess.run(command[:3] + [json.dumps(altered)] + command[4:], env=environment, capture_output=True, text=True)
            assert result.returncode != 0, f'{slug} accepted {change}'
            checks += 1
    with tempfile.TemporaryDirectory(prefix='native-game-smoke-') as temporary:
        environment = os.environ | {
            'HOME': temporary,
            'XDG_CONFIG_HOME': temporary + '/config',
            'XDG_DATA_HOME': temporary + '/data',
            'XDG_CACHE_HOME': temporary + '/cache',
        }
        result = subprocess.run([str(program), '--headless', '--quit-after', '8'], env=environment, capture_output=True, text=True, timeout=120)
        print(result.stdout, end='')
        print(result.stderr, end='', file=sys.stderr)
        assert result.returncode == 0, f'{slug} headless smoke failed'
        assert 'SCRIPT ERROR:' not in result.stdout + result.stderr
        assert '\nERROR:' not in '\n' + result.stdout + result.stderr
        checks += 1
    print(f'NATIVE-CONTRACT-VERIFIED {slug}: {digest}', flush=True)
print(f'{checks} real host/sandbox checks passed', flush=True)
