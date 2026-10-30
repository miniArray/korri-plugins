{
  description = "Korri plugins published by miniArray (@miniarray)";

  inputs = {
    # The Core pin korri-os/plugins builds against; supplies mkPlugin and the contract.
    korri.url = "github:korri-os/korri/62432aa04b199caf47399bee23e25ae949efdb92";
    eggshell.url = "github:miniArray/eggshell/ad88b03";
    bad-culture.url = "github:miniArray/bad-culture/6da264ca818822e4741083cd9e161bda681deb35";
    credence.url = "github:miniArray/credence/55be122f9be0ed4bdf6f2723e8da1511701bc565";
    rot-and-light.url = "github:miniArray/rot-and-light/c99f0b3a08fcc0d21e8b771bb6037086ffd54886";
    nixpkgs.follows = "eggshell/nixpkgs";
  };

  outputs =
    {
      korri,
      nixpkgs,
      eggshell,
      bad-culture,
      credence,
      rot-and-light,
      ...
    }:
    import ./nix {
      inherit
        korri
        nixpkgs
        eggshell
        bad-culture
        credence
        rot-and-light
        ;
    };
}
