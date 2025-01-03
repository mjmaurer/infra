{
  inputs = {
    python-flake.url = "github:mjmaurer/infra?dir=flakes/python";
  };
  outputs = { self, python-flake }:
    {
      lib = python-flake.lib // {
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
