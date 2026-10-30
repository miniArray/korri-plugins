{
  pkgs,
  packages,
  contract,
  hostPackage,
  korridPackage,
}:
let
  names = [
    "bad-culture"
    "credence"
    "eggshell"
    "rot-and-light"
  ];
  tsconfig = pkgs.writeText "plugin-tsconfig.json" (
    builtins.toJSON {
      compilerOptions = {
        target = "ES2022";
        module = "ESNext";
        moduleResolution = "Bundler";
        strict = true;
        noEmit = true;
        skipLibCheck = true;
        types = [ ];
      };
      include = [ "plugins/*/plugin.ts" ];
    }
  );
  recordArguments = pkgs.writeShellScript "record-eggshell-arguments" ''
    printf '%s\0' "$@"
  '';
in
pkgs.runCommand "miniarray-plugin-contracts-check"
  {
    nativeBuildInputs = [
      pkgs.bun
      pkgs.typescript
    ];
  }
  ''
    mkdir -p work/contracts/generated work/nix
    cp ${contract} work/contracts/generated/korrid.ts
    ${pkgs.lib.concatMapStringsSep "\n" (name: ''
      mkdir -p work/plugins/${name}
      cp ${packages.${"korri-plugin-${name}"}}/plugin.ts work/plugins/${name}/plugin.ts
    '') names}
    cp ${./plugin-contracts-check.ts} work/nix/plugin-contracts-check.ts
    cp ${tsconfig} work/tsconfig.json
    cd work
    tsc --project tsconfig.json
    bun nix/plugin-contracts-check.ts \
      ${hostPackage}/bin/korri-plugin ${korridPackage}/bin/korrid ${recordArguments} \
      ${pkgs.lib.concatMapStringsSep " " (name: toString packages.${"korri-plugin-${name}"}) names}
    touch "$out"
  ''
