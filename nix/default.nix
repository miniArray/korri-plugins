{
  korri,
  nixpkgs,
  eggshell,
  bad-culture,
  credence,
  rot-and-light,
}:
let
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  eachSystem = nixpkgs.lib.genAttrs systems;
in
rec {
  packages = eachSystem (
    system:
    let
      pkgs = import nixpkgs { inherit system; };
      mkPlugin = korri.lib.${system}.mkPlugin { inherit pkgs; };
      eggshellPackage = eggshell.packages.${system}.eggshell;
      badCulturePackage = bad-culture.packages.${system}.default;
      credencePackage = credence.packages.${system}.credence;
      rotAndLightPackage = import ./rot-and-light.nix {
        source = rot-and-light;
        inherit system;
      };
      gamePlugin =
        name: gamePackage: source: runtime: cargoLock:
        import ./native-game.nix {
          inherit
            pkgs
            mkPlugin
            name
            gamePackage
            ;
          notices = import ./game-notices.nix {
            pkgs = source.inputs.nixpkgs.legacyPackages.${system};
            inherit
              source
              runtime
              name
              cargoLock
              ;
          };
        };
    in
    {
      inherit
        eggshellPackage
        badCulturePackage
        credencePackage
        rotAndLightPackage
        ;
      korri-plugin-bad-culture =
        gamePlugin "bad-culture" badCulturePackage bad-culture
          bad-culture.inputs.nixpkgs.legacyPackages.${system}.godot_4
          (bad-culture + "/Cargo.lock");
      korri-plugin-credence = gamePlugin "credence" credencePackage credence credencePackage.runtime null;
      korri-plugin-rot-and-light =
        gamePlugin "rot-and-light" rotAndLightPackage rot-and-light rotAndLightPackage.runtime
          (rot-and-light + "/Cargo.lock");
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
  checks = eachSystem (
    system:
    let
      pkgs = import nixpkgs { inherit system; };
      selected = packages.${system};
    in
    {
      native-games =
        pkgs.runCommand "miniarray-native-game-checks"
          {
            nativeBuildInputs = [ pkgs.python3 ];
          }
          ''
            python3 ${./check-native-games.py} \
              ${korri.packages.${system}.korri-plugin-host}/bin/korri-plugin \
              ${korri.packages.${system}.korrid}/bin/korrid \
              ${selected.korri-plugin-bad-culture} \
              ${selected.korri-plugin-credence} \
              ${selected.korri-plugin-rot-and-light}
            touch "$out"
          '';
    }
  );
}
