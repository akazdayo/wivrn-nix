{
  description = "An automatically updated WiVRn package for NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      sources = builtins.fromJSON (builtins.readFile ./nix/sources.json);
      wivrn = import ./nix/package.nix { inherit pkgs sources; };

      moduleEvaluation = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          self.nixosModules.default
          {
            boot.loader.grub.enable = false;
            fileSystems."/" = {
              device = "nodev";
              fsType = "tmpfs";
            };
            services.wivrn.enable = true;
            system.stateVersion = "26.05";
          }
        ];
      };
    in
    {
      packages.${system} = {
        inherit wivrn;
        default = wivrn;
      };

      overlays.default = _final: _prev: {
        inherit wivrn;
      };

      nixosModules.default =
        { lib, pkgs, ... }:
        {
          assertions = [
            {
              assertion = pkgs.stdenv.hostPlatform.system == system;
              message = "wivrn-nix currently supports x86_64-linux only";
            }
          ];

          services.wivrn.package = lib.mkDefault wivrn;
        };

      checks.${system} = {
        package = wivrn;

        package-shape =
          assert wivrn.version == sources.version;
          pkgs.runCommand "wivrn-package-shape" { } ''
            test -x ${wivrn}/bin/wivrn-server
            test -x ${wivrn}/bin/wivrn-dashboard
            touch "$out"
          '';

        module =
          assert moduleEvaluation.config.services.wivrn.package == wivrn;
          assert builtins.hasAttr "wivrn" moduleEvaluation.config.systemd.user.services;
          pkgs.runCommand "wivrn-module-check" { } ''
            touch "$out"
          '';

        formatting = pkgs.runCommand "wivrn-formatting" { nativeBuildInputs = [ pkgs.nixfmt ]; } ''
          nixfmt --check ${./flake.nix} ${./nix/package.nix}
          touch "$out"
        '';

        shellcheck = pkgs.runCommand "wivrn-shellcheck" { nativeBuildInputs = [ pkgs.shellcheck ]; } ''
          shellcheck ${./scripts/update-wivrn.sh}
          touch "$out"
        '';

        workflows = pkgs.runCommand "wivrn-workflows" { nativeBuildInputs = [ pkgs.actionlint ]; } ''
          actionlint \
            ${./.github/workflows/ci.yml} \
            ${./.github/workflows/update-nixpkgs.yml} \
            ${./.github/workflows/update-wivrn.yml}
          touch "$out"
        '';
      };

      formatter.${system} = pkgs.nixfmt;

      devShells.${system}.default = pkgs.mkShellNoCC {
        packages = with pkgs; [
          actionlint
          curl
          jq
          nixfmt
          shellcheck
        ];
      };
    };
}
