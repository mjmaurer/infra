{
  outputs = { self }:
    {
      lib = {
        readme = ''
        '';
        mkInit = pkgs: with pkgs; ''
        '';
        overlays = [ ];
        mkLang = pkgs: pkgs;
        mkPackages = pkgs: with pkgs; [
        ];
      };
    };
}
