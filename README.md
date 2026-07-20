# wivrn-nix

WiVRnの最新stable releaseへ自動追従する、`x86_64-linux`向けNix flakeです。

WiVRnはヘッドセットとサーバーのversionが一致している必要があります。このリポジトリはnixpkgsのWiVRn packageを土台に、WiVRn sourceと、releaseが指定するMonado sourceだけを上書きします。6時間ごとのGitHub Actionsで新しいstable releaseを確認し、実ビルドに成功した更新だけをpull requestにします。

## 直接利用する

```console
nix build github:akazdayo/wivrn-nix
```

任意でローカルのflake registryに短い名前を登録できます。

```console
nix registry add wivrn github:akazdayo/wivrn-nix
nix build wivrn
```

このリポジトリ自体は独自registry JSONを提供しません。

## NixOSで利用する

既存の`services.wivrn` moduleへ、このflakeでビルドしたpackageを設定します。

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

packageだけを直接指定することもできます。

```nix
services.wivrn.package = wivrn-nix.packages.x86_64-linux.wivrn;
```

また、overlayを使うと利用側の`pkgs.wivrn`を同じpackageへ差し替えられます。

```nix
nixpkgs.overlays = [ wivrn-nix.overlays.default ];
```

nixpkgs側のWiVRn recipeが`cudaSupport`引数を提供しているrevisionでは、明示的なoverrideも利用できます。

```nix
services.wivrn.package = wivrn-nix.packages.x86_64-linux.wivrn.override {
  cudaSupport = true;
};
```

## 更新

`scripts/update-wivrn.sh`はlatest stable releaseを検出し、WiVRnとMonadoの固定出力hashを更新します。特定のstable versionを検証したい場合はversionを渡せます。

```console
nix develop
bash scripts/update-wivrn.sh
bash scripts/update-wivrn.sh 26.6.2
nix flake check
```

WiVRn更新は6時間ごと、flakeのnixpkgs input更新は週1回、それぞれ別のpull requestとして作成されます。ビルドに失敗した場合はpull requestを作成せず、workflowを失敗させます。自動mergeは行いません。各workflowのNix build結果はMagic Nix CacheによってGitHub Actions cache内で共有されます。

自動PRを有効にするには、GitHubリポジトリのSettings → Actions → Generalでworkflowのwrite権限と、GitHub Actionsによるpull request作成を許可してください。追加のPATやsecretは不要です。

## ライセンス

このリポジトリのNix式と自動化コードは[MIT License](./LICENSE)です。ビルドされるWiVRn本体にはupstreamのGPL-3.0-only licenseが適用されます。
