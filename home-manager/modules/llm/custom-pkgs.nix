{
  pkgs,
  lib,
  pythonPkg,
  # llmPkg,
  ...
}:
let
  # Define all packages in a recursive attribute set
  pythonPackages = rec {

    streamdown = pythonPkg.pkgs.buildPythonPackage rec {
      pname = "streamdown";
      version = "0.34.0";
      format = "pyproject";

      src = pkgs.fetchurl {
        url = "https://github.com/day50-dev/Streamdown/archive/refs/tags/v0.34.0.tar.gz";
        sha256 = "sha256-+ow5FxuZuk7H9IA3cxW47GlozKomidsjMJVtlH12Ri4=";
      };

      nativeBuildInputs = with pythonPkg.pkgs; [
        setuptools
        wheel
        hatchling
      ];
      # Dependencies
      propagatedBuildInputs = with pythonPkg.pkgs; [
        pygments
        appdirs
        toml
        wcwidth
        pylatexenc
        term-image
      ];

      doCheck = false;

      pythonImportsCheck = [ "streamdown" ];

      meta = with lib; {
        description = "Stream markdown from llm";
        homepage = "https://github.com/day50-dev/Streamdown";
        license = licenses.mit;
      };
    };

    llm-cmd-comp = pythonPkg.pkgs.buildPythonPackage rec {
      pname = "llm-cmd-comp";
      version = "1.2.0";
      format = "pyproject";

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/source/l/llm_cmd_comp/llm_cmd_comp-1.2.0.tar.gz";
        sha256 = "sha256-bsczL/o4cXUgumCYGwQPF+TMTKT9jXFbcgra/NSngyM=";
      };

      nativeBuildInputs = with pythonPkg.pkgs; [
        setuptools
        wheel
      ];
      # Dependencies
      propagatedBuildInputs = with pythonPkg.pkgs; [
        llm
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
        llm
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
        llm
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

    llm-openrouter = pythonPkg.pkgs.buildPythonPackage rec {
      pname = "llm-openrouter";
      version = "0.5";
      format = "pyproject";

      src = pkgs.fetchurl {
        url = "https://github.com/simonw/llm-openrouter/archive/refs/tags/0.5.tar.gz";
        sha256 = "sha256-MkXobkACveEd+pACYr0RQICaPlxC1M6S9S9HRQ4/Eag=";
      };

      nativeBuildInputs = with pythonPkg.pkgs; [
        setuptools
        wheel
      ];
      # Dependencies
      propagatedBuildInputs = with pythonPkg.pkgs; [
        llm
        httpx
        openai
      ];

      # Disable tests - enable if you have specific test dependencies
      doCheck = false;

      # Basic import check
      pythonImportsCheck = [ "llm_openrouter" ];

      meta = with lib; {
        description = "LLM fragments for OpenRouter";
        homepage = "https://github.com/simonw/llm-openrouter";
        license = licenses.asl20;
      };
    };

    llm-cerebras = pythonPkg.pkgs.buildPythonPackage rec {
      pname = "llm-cerebras";
      version = "0.1.8";
      format = "pyproject";

      src = pkgs.fetchurl {
        url = "https://github.com/mjmaurer/llm-cerebras/archive/c68a2be342d18850fa4ba9df7b4e2b40ed4d7d68.tar.gz";
        sha256 = "sha256-UutwqIc7IwwEtM/qFVfXVoL8p8csuK8gN9W1651Sw90=";
      };

      nativeBuildInputs = with pythonPkg.pkgs; [
        setuptools
        wheel
      ];
      # Dependencies
      propagatedBuildInputs = with pythonPkg.pkgs; [
        llm
        httpx
      ];

      # Disable tests - enable if you have specific test dependencies
      doCheck = false;

      # Basic import check
      pythonImportsCheck = [ "llm_cerebras" ];

      meta = with lib; {
        description = "LLM fragments for Gemini";
        homepage = "https://github.com/irthomasthomas/llm-cerebras";
        license = licenses.asl20;
      };
    };

    llm-gemini = pythonPkg.pkgs.buildPythonPackage rec {
      pname = "llm-gemini";
      version = "0.27";
      format = "pyproject";

      src = pkgs.fetchurl {
        url = "https://github.com/simonw/llm-gemini/archive/refs/tags/0.27.tar.gz";
        sha256 = "sha256-YWUVITM/h1LLrG+UCtnDkokD2MWKVw5vQi2deyjsFIQ=";
      };

      nativeBuildInputs = with pythonPkg.pkgs; [
        setuptools
        wheel
      ];
      # Dependencies
      propagatedBuildInputs = with pythonPkg.pkgs; [
        llm
        httpx
        ijson
      ];

      # Disable tests - enable if you have specific test dependencies
      doCheck = false;

      # Basic import check
      pythonImportsCheck = [ "llm_gemini" ];

      meta = with lib; {
        description = "LLM fragments for Gemini";
        homepage = "https://github.com/simonw/llm-gemini";
        license = licenses.asl20;
      };
    };
  };
in
pythonPackages
