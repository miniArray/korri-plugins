{
  korri,
  nixpkgs,
  eggshell,
}:
let
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  eachSystem = nixpkgs.lib.genAttrs systems;
in
{
  packages = eachSystem (
    system:
    let
      pkgs = import nixpkgs { inherit system; };
      mkPlugin = korri.lib.${system}.mkPlugin { inherit pkgs; };
      eggshellPackage = eggshell.packages.${system}.eggshell;
    in
    {
      inherit eggshellPackage;
      korri-plugin-eggshell = mkPlugin {
        publisher.namespace = "@miniarray";
        source = pkgs.lib.fileset.toSource {
          root = ../plugins/eggshell;
          fileset = ../plugins/eggshell/plugin.ts;
        };
        plugin = _: import ../plugins/eggshell/plugin.nix { inherit eggshellPackage; };
      };
    }
  );
}
