{
  description = "Korri plugins published by miniArray (@miniarray)";

  inputs = {
    # The Core pin korri-os/plugins builds against; supplies mkPlugin and the contract.
    korri.url = "github:korri-os/korri/1e5f6b8b432d3970b9814884769503827d0c8629";
    eggshell.url = "github:miniArray/eggshell/ad88b03";
    nixpkgs.follows = "eggshell/nixpkgs";
  };

  outputs =
    {
      korri,
      nixpkgs,
      eggshell,
      ...
    }:
    import ./nix { inherit korri nixpkgs eggshell; };
}
