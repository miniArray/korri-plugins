# Native games

These plugins package the existing public Linux games. They change no game
rules, art, renderer configuration, input maps or installed data.

| Game | Public source pin | Native package |
|---|---|---|
| Bad Culture | `miniArray/bad-culture` at `6da264ca818822e4741083cd9e161bda681deb35` | Its existing `packages.<system>.default`. |
| Credence | `miniArray/credence` at `55be122f9be0ed4bdf6f2723e8da1511701bc565` | Its existing `packages.<system>.credence`. |
| Rot and Light | `miniArray/rot-and-light` at `c99f0b3a08fcc0d21e8b771bb6037086ffd54886` | `nix/rot-and-light.nix` builds its existing native binding and preserves its Godot project layout. |

## Existing contract

Core `1e5f6b8b432d3970b9814884769503827d0c8629` already defines
`RunnerRecord.releases` in `services/korrid/src/plugin.rs`. A native runner
can name whole-file release hashes instead of claiming a content system.
ADR 0016 already supports declared games from a named file directory in
the declaring plugin's own package. These plugins use those contracts.
They introduce no system, content format, wire type or persisted schema.

The actual packaged launcher is the release file. Its immutable Nix paths
reference the game and runtime closure. `nix/native-game.nix` computes its
SHA256 during the build and materializes that value into both the declared
game and runner. It generates the manifest through Core's existing builder.
The `launchers` manifest file names the real `bin/` directory. The `game`
file names its executable. Neither is a synthetic content marker.

Each runner accepts only its own packaged launcher. It rejects emulator
cores and unsupported overrides. It returns a launch declaration and does
not create directories or spawn a process. Godot's data uses the account
root, as in the existing Eggshell plugin. These prototypes add no save-root
flag or automatic migration of old app data.

## Binary notices and source

Original work remains all rights reserved. The public-source audits remain
scoped evidence, not legal or trademark clearance. Private references,
research projects, Android tooling, keys, captures and old installed games
are not part of these packages.

Each plugin carries `packages.notices` and a `files.notices` directory.
`nix/game-notices.nix` preserves the source tree's license/copyright files
and third-party notice. It queries the actual runtime with Godot's
`Engine.get_license_text()`, `Engine.get_copyright_info()` and
`Engine.get_license_info()`. The resulting readable files include the
engine's bundled component, default-font and logo notices. The package
does not represent the entire engine as MIT-only.

For Bad Culture and Rot and Light, `covered-source/*.crate` contains the
unchanged Rust dependency archives, checked against the exact public
`Cargo.lock` checksums. It includes the MPL-covered gdext source and other
locked dependency notices. The original-work restriction does not apply
to those files. The compiled bindings also carry the exact Rust compiler's
standard-library copyright inventory and MIT/Apache license texts from its
prebuilt documentation output. The complete MPL-2.0 text accompanies them. Its primary
source is <https://www.mozilla.org/media/MPL/2.0/index.815ca599c9df.txt>,
SHA256 `fab3dd6bdab226f1c08630b1dd917e11fcb4ec5e1e020e2c16f83a0a13863e85`.
Mozilla's [binary distribution guidance](https://www.mozilla.org/en-US/MPL/2.0/FAQ/#distribute-my-binaries)
requires informing recipients where to obtain the covered source. The
source and that notice are included with these plugins.

The publisher omits runtime paths already available from cache.nixos.org.
Any custom runtime output not covered there needs its own redistribution
review before upload. Source availability and an original-work copyright
notice alone are not a binary-compliance guarantee.

## Verification boundary

`checks.<system>.native-games` uses the real host's effect-free `seed`
validation and the pinned korrid's supported `plugin-run` command. A real
temporary capture program records arguments, environment and working
directory after sandbox preparation and execution. The host separately
validates the actual game package and its materialized hash. Tests cover
notice/source files, launch behavior and refusal cases. They then run each
actual packaged game headlessly on that build architecture. This does not verify graphical output, controller handling,
performance or physical devices.

Build only on workstations or configured build servers. Publication uses
the existing miniArray signing key, Pages metadata and release NARs. No
device install, update, binding change or receipt migration is authorized.
