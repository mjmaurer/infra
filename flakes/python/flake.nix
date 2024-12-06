{
  outputs = { self }:
    {
      lib = {
        readme = ''
          Debugging:
          ```zsh
          pydb / pydbw
          ```
        '';

        overlays = [ ];

        mkPython = pkgs: pkgs.python312;
        mkLang = self.lib.mkPython;
        mkPackages = pkgs: with pkgs; [
          (self.lib.mkPython pkgs)
          (self.lib.mkPython pkgs).pkgs.debugpy

        ];
      };
    };
}
