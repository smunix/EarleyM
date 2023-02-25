{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixpkgs-unstable";
    devenv.url = "github:cachix/devenv";
    nix-utils.url = "github:smunix/nix-utils";
    nix-filter.url = "github:numtide/nix-filter";
    cracklib.url = "github:cracklib/cracklib";
    cracklib.flake = false;
  };

  outputs = { self, nixpkgs, devenv, ... }@inputs:
    let
      systems = [
        "x86_64-linux"
        "i686-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = f:
        builtins.listToAttrs (map (name: {
          inherit name;
          value = f name;
        }) systems);
    in {
      devShells = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          default = devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [ (import ./devenv.nix { inherit inputs pkgs; }) ];
          };
        });
    };
}
