{
  outputs = { self }:
    {
      lib = {
        readme = ''
        '';
        # For entry point scripts that go in the template entry (and can be deleted)
        mkInitScript = pkgs: with pkgs; ''
        '';
        # For readme messages that go in the template readme (and can be deleted)
        mkInitReadme = pkgs: with pkgs; ''
        '';
        overlays = [ ];
        mkLang = pkgs: pkgs;
        mkPackages = pkgs: with pkgs; [
        ];
      };
    };
}
