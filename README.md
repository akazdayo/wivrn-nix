# wivrn-nix

A Nix flake that provides the latest stable WiVRn release for `x86_64-linux`.

## Usage

Add the flake input and import its NixOS module.

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    wivrn-nix.url = "github:akazdayo/wivrn-nix";
  };

  outputs =
    { nixpkgs, wivrn-nix, ... }:
    {
      nixosConfigurations.example = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          wivrn-nix.nixosModules.default
          {
            services.wivrn = {
              enable = true;
              openFirewall = true;
            };
          }
        ];
      };
    };
}
```

### Overlay

You can use the overlay to replace `pkgs.wivrn` instead of importing the NixOS module.

```nix
{
  nixpkgs.overlays = [ wivrn-nix.overlays.default ];

  services.wivrn = {
    enable = true;
    openFirewall = true;
  };
}
```

### Package

You can also set only the package.

```nix
services.wivrn.package = wivrn-nix.packages.x86_64-linux.wivrn;
```

WiVRn updates are submitted automatically as pull requests by GitHub Actions.

## License

This repository is licensed under the [MIT License](./LICENSE). WiVRn itself is licensed under [GPL-3.0-only](https://github.com/WiVRn/WiVRn/blob/master/COPYING).
