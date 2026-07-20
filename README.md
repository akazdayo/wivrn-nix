# wivrn-nix

WiVRnの最新stable releaseを提供する、`x86_64-linux`向けNix flakeです。

## Usage

flake inputを追加し、NixOS moduleを読み込みます。

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

NixOS moduleを直接読み込まず、overlayで`pkgs.wivrn`を差し替えることもできます。

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

packageだけを指定することもできます。

```nix
services.wivrn.package = wivrn-nix.packages.x86_64-linux.wivrn;
```

WiVRnの更新はGitHub Actionsによって自動的にpull requestとして作成されます。

## License

MIT
