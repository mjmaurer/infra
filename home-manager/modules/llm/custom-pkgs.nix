{
  pkgs,
  lib,
  pythonPkg,
  llmPkg,
  ...
}:
let
  # Define all packages in a recursive attribute set
  pythonPackages = rec {

    llm-cmd-comp = pythonPkg.pkgs.buildPythonPackage rec {
      pname = "llm-cmd-comp";
      version = "1.1.1";
      format = "pyproject";

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/source/l/llm_cmd_comp/llm_cmd_comp-1.1.1.tar.gz";
        sha256 = "sha256-YyqVN53AG8C41UlX3zY8Lv+ApueCorNUZUalf87Rht8=";
      };

      nativeBuildInputs = with pythonPkg.pkgs; [
        setuptools
        wheel
      ];
      # Dependencies
      propagatedBuildInputs = with pythonPkg.pkgs; [
        llmPkg
        prompt-toolkit
      ];

      # Disable tests - enable if you have specific test dependencies
      doCheck = false;

      # Basic import check
      pythonImportsCheck = [ "llm_cmd_comp" ];

      meta = with lib; {
        description = "Use LLM to generate commands for your shell";
        homepage = "https://github.com/CGamesPlay/llm-cmd-comp";
        license = licenses.asl20;
      };
    };

    llm-fragments-site-text = pythonPkg.pkgs.buildPythonPackage rec {
      pname = "llm-fragments-site-text";
      version = "0.1.0";
      format = "pyproject";

      src = pkgs.fetchurl {
        url = "https://github.com/daturkel/llm-fragments-site-text/archive/refs/tags/0.1.0.tar.gz";
        sha256 = "sha256-6oFcdb51ICMqRJoLNC1eua7mysyObNsXYEL31Vv7aVY=";
      };

      nativeBuildInputs = with pythonPkg.pkgs; [
        setuptools
        wheel
      ];
      # Dependencies
      propagatedBuildInputs = with pythonPkg.pkgs; [
        llmPkg
        trafilatura
      ];

      # Disable tests - enable if you have specific test dependencies
      doCheck = false;

      # Basic import check
      pythonImportsCheck = [ "llm_fragments_site_text" ];

      meta = with lib; {
        description = "LLM fragments for site text";
        homepage = "https://github.com/daturkel/llm-fragments-site-text";
        license = licenses.asl20;
      };
    };

    llm-fragments-github = pythonPkg.pkgs.buildPythonPackage rec {
      pname = "llm-fragments-github";
      version = "0.4";
      format = "pyproject";

      src = pkgs.fetchurl {
        url = "https://github.com/simonw/llm-fragments-github/archive/refs/tags/0.4.tar.gz";
        sha256 = "sha256-vpl+MakghfR4vns+PqU9y0P+q0OtitaqpErKh8gcU40=";
      };

      nativeBuildInputs = with pythonPkg.pkgs; [
        setuptools
        wheel
      ];
      # Dependencies
      propagatedBuildInputs = with pythonPkg.pkgs; [
        llmPkg
      ];

      # Disable tests - enable if you have specific test dependencies
      doCheck = false;

      # Basic import check
      pythonImportsCheck = [ "llm_fragments_github" ];

      meta = with lib; {
        description = "LLM fragments for GitHub";
        homepage = "https://github.com/simonw/llm-fragments-github";
        license = licenses.asl20;
      };
    };
  };
in
pythonPackages
