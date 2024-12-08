{
  inputs = {
    python-flake.url = "path:../python";
  };
  outputs = { self, python-flake }:
    {
      lib = python-flake.lib // {

        overlays = [ ];

        readme = ''
          ${python-flake.lib.readme}}

          Create a new virtual environment:
          ```zsh
          python -m venv .venv
          ```

          Install requirements:
          ```zsh
          pip install -r requirements.txt
          ```
        '';

        mkPackages = pkgs: (python-flake.lib.mkPackages pkgs) ++ [
          (python-flake.lib.mkPython pkgs).pkgs.pip
        ];
      };
    };
}
