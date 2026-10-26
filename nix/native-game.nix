# Grounding: Core 1e5f6b8's RunnerRecord.releases and ADR 0016 package files.
# The content identity is the actual packaged launcher. Its immutable Nix paths
# bind the game and runtime closure; the host admits only this whole-file hash.
{
  pkgs,
  mkPlugin,
  name,
  gamePackage,
  notices,
}:
let
  program = "${gamePackage}/bin/${name}";
  declaration = pkgs.runCommand "${name}-plugin-source" { } ''
    mkdir -p "$out"
    hash="$(sha256sum ${program} | cut -d ' ' -f 1)"
    substitute ${../plugins + "/${name}/plugin.ts"} "$out/plugin.ts" \
      --replace-fail '@GAME_HASH@' "sha256:$hash"
  '';
in
mkPlugin {
  publisher.namespace = "@miniarray";
  source = declaration;
  plugin = _: {
    packages = {
      game = gamePackage;
      inherit notices;
    };
    files = {
      game = program;
      launchers = "${gamePackage}/bin";
      notices = "${notices}/share/notices";
    };
  };
}
