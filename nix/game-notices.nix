# Preserve source notices, query the actual runtime, and ship covered Rust source.
# Registry archive identities come directly from the published Cargo.lock.
{
  pkgs,
  source,
  runtime,
  name,
  cargoLock ? null,
}:
let
  sourceRoot = builtins.toPath source.outPath;
  crates =
    if cargoLock == null then
      [ ]
    else
      builtins.filter (package: package ? source)
        (builtins.fromTOML (builtins.readFile cargoLock)).package;
  archives = map (
    package:
    assert package.source == "registry+https://github.com/rust-lang/crates.io-index";
    {
      filename = "${package.name}-${package.version}.crate";
      archive = pkgs.fetchurl {
        url = "https://static.crates.io/crates/${package.name}/${package.name}-${package.version}.crate";
        sha256 = package.checksum;
      };
    }
  ) crates;
in
pkgs.runCommand "${name}-binary-notices"
  {
    nativeBuildInputs = [ runtime ];
  }
  ''
    export HOME="$TMPDIR/home"
    export XDG_CONFIG_HOME="$HOME/config"
    export XDG_DATA_HOME="$HOME/data"
    export XDG_CACHE_HOME="$HOME/cache"
    mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$out/share/notices/source"
    cd ${sourceRoot}
    find . -type f \( -iname '*license*' -o -iname '*copyright*' -o -name THIRD_PARTY_NOTICES.md \) \
      -exec cp --parents '{}' "$out/share/notices/source/" \;
    cd "$TMPDIR"
  godot --headless --script ${./godot-notices.gd} -- "$out/share/notices" > "$TMPDIR/engine.log" 2>&1
    cat "$TMPDIR/engine.log"
    if grep -E 'SCRIPT ERROR:|^ERROR:' "$TMPDIR/engine.log"; then exit 1; fi
    test -s "$out/share/notices/GODOT-LICENSE.txt"
    test -s "$out/share/notices/GODOT-COPYRIGHT.json"
    test -s "$out/share/notices/GODOT-LICENSES.json"
    ${pkgs.lib.optionalString (cargoLock != null) ''
      mkdir -p "$out/share/notices/covered-source"
      cp ${./licenses/MPL-2.0.txt} "$out/share/notices/MPL-2.0.txt"
      cp ${cargoLock} "$out/share/notices/covered-source/Cargo.lock"
      ${pkgs.lib.concatMapStringsSep "\n" (entry: ''
        cp ${entry.archive} "$out/share/notices/covered-source/${entry.filename}"
      '') archives}
      printf '%s\n' \
        'Covered Rust dependency source is included in covered-source/*.crate.' \
        'These are unchanged registry archives verified against Cargo.lock checksums.' \
        'Each archive retains its source, copyright headers and license declarations.' \
        'MPL-covered files remain under MPL-2.0. Original-work restrictions do not apply to them.' \
        'MPL terms: https://www.mozilla.org/MPL/2.0/' \
        'Distribution guidance: https://www.mozilla.org/en-US/MPL/2.0/FAQ/#distribute-my-binaries' \
        > "$out/share/notices/COVERED-SOURCE.txt"
    ''}
  ''
