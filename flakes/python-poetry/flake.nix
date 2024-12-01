{
  inputs = {
    python-flake.url = "path:../python";
  };
  outputs = { self, python-flake }:
    {
      lib = python-flake.lib // {
        overlays = [ ];

        readme = ''
          ${python-flake.lib.readme}
        '';

        mkPoetry = pkgs: pkgs.poetry.override { python3 = python-flake.lib.mkPython pkgs; };
        mkPackages = pkgs: (python-flake.lib.mkPackages pkgs) ++ [
          (self.lib.mkPoetry pkgs)
        ];
      };
    };
}
