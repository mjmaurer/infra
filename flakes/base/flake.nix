{
  outputs = { self }:
    {
      lib = {
        readme = ''
        '';
        # For hooks / scripts that go in the template entry (and can be deleted)
        # Should document hooks in mkInitReadme
        mkInitHook = pkgs: with pkgs; ''
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
