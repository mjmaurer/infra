For VScode extensions that require a future verison,
you need to configure config.toml as appropriate
and then run the following:

```
nix run github:nix-community/nix4vscode -- ./home-manager/modules/vscode/config.toml
```
