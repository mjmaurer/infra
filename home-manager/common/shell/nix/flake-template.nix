{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    base-flake.url = "github:mjmaurer/infra?dir=flakes/<BASE_FLAKE>";
  };
  outputs = { self, nixpkgs, flake-utils, base-flake }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = base-flake.lib.overlays;
          };
          readme = pkgs.writeText "readme" ''
            # Commands

            ${base-flake.lib.readme}

            Some command description:
            ```zsh
            command
            ```

            # Initialization (can delete if not needed)

            ${base-flake.lib.mkInitReadme pkgs}
          '';
        in
        with pkgs;
        {
          devShells.default = mkShell {
            buildInputs = with pkgs; (base-flake.lib.mkPackages pkgs) ++ [
              (pkgs.writeShellScriptBin "my_script" ''
                echo "Hello, world!"
              '')
            ];
            shellHook = ''
              glow ${readme}

              # Hooks (can delete if not needed)
              ${base-flake.lib.mkInitHook pkgs}
            '';
          };
        }
      );
}
