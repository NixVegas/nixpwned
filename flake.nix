{
  description = "Installing NixOS on the nixplay";
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-patcher.url = "github:gepbird/nixpkgs-patcher";
  };

  outputs =
    inputs@{
      self,
      flake-parts,
      nixpkgs,
      nixpkgs-patcher,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.flake-parts.flakeModules.easyOverlay
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      flake = {
        nixosConfigurations.nixplay = nixpkgs-patcher.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./nixplay
            self.nixosModules.default
          ];
          specialArgs = inputs;
        };

        nixosModules.default = {
          nixpkgs.overlays = [ self.overlays.default ];
        };
      };

      perSystem =
        {
          config,
          system,
          pkgs,
          final,
          lib,
          ...
        }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              self.overlays.default
            ];

            config = { };
          };

          overlayAttrs = with pkgs; {
            nixplaySystem = callPackage ./pkgs/build-support/nixplay-system.nix {
              inherit nixpkgs;
            };
          };

          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [
              rkflashtool
              rkdeveloptool
              usbutils
              dtc
            ];
          };
        };
    };
}
