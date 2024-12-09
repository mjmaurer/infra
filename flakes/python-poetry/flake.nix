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

        mkInitReadme = pkgs: with pkgs; ''
          Add the following to `poetry.toml`:
          ```toml
          [virtualenvs]
          in-project = true
          prefer-active-python = true
          ```
        '';

        mkPoetry = pkgs: pkgs.poetry.override { python3 = python-flake.lib.mkPython pkgs; };
        mkPackages = pkgs: (python-flake.lib.mkPackages pkgs) ++ [
          (self.lib.mkPoetry pkgs)
        ];
      };
    };
}
