{
  inputs = {
    base-flake.url = "github:mjmaurer/infra?dir=flakes/base";
  };
  outputs = { self, base-flake }:
    {
      lib = base-flake.lib // {
        readme = ''
          Debugging:
          ```zsh
          pydb / pydbw
          ```
        '';

        mkPython = pkgs: pkgs.python312;
        mkLang = self.lib.mkPython;

        mkPackages = pkgs: with pkgs; [
          (self.lib.mkPython pkgs)
          (self.lib.mkPython pkgs).pkgs.debugpy

        ];
      };
    };
}
