{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    coq-nix-toolbox = {
      url = "github:lweqx/coq-nix-toolbox/allow-passing-nixpkgs-directly";
      flake = false;
    };
  };

  outputs =
    {
      coq-nix-toolbox,
      nixpkgs,
      self,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
        in
        pkgs.callPackage ./packages.nix {
          inherit (pkgs.ocaml-ng)
            ocamlPackages_4_14
            ocamlPackages_5_5
            ;
        }
      );

      apps = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };

          selfPath = "path:${self.outPath}?narHash=${self.narHash}";

          update-ci = pkgs.callPackage ./update-ci.nix {
            inherit coq-nix-toolbox selfPath;
          };
        in
        {
          update-ci = {
            type = "app";
            program = toString update-ci;

            meta.description = "Update the GitHub CI files of this repository.";
          };
        }
      );

      formatter = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        pkgs.nixfmt-tree
      );
    };
}
