{
  inputs = {
    python-flake.url = "path:../python";
  };
  outputs = { self, python-flake }:
    {
      lib = python-flake.lib // {
        readme = ''
          ${python-flake.lib.readme}
        '';

        mkPackages = pkgs: (python-flake.lib.mkPackages pkgs) ++ [
          (pkgs.poetry.override { python3 = python-flake.lib.mkPython pkgs; })
        ];
      };
    };
}
