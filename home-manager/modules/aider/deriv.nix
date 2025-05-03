{
  lib,
  pkgs,
  ...
}:
let
  # NOTE(mjmaurer): I added these
  python3 = pkgs.python3.override {};
  sentry-sdk-no-tests = python3.pkgs.sentry-sdk.overridePythonAttrs (oldAttrs: {
    # Disable the check phase
    doCheck = false;
    # Remove check inputs to avoid unnecessary dependencies
    nativeCheckInputs = [ ];
    checkInputs = [ ];
    # You might potentially need to remove pytest hooks if they cause issues
    pytestCheckHook = null; # Uncomment if needed
    disabledTestPaths = [
      "tests/profiler/test_continuous_profiler.py"
    ];
  });
  # End personal changes 

  aider-nltk-data = pkgs.symlinkJoin {
    name = "aider-nltk-data";
    paths = [
      pkgs.nltk-data.punkt_tab
      pkgs.nltk-data.stopwords
    ];
  };
  version = "0.82.1";
  aider-chat = python3.pkgs.buildPythonPackage {
    pname = "aider-chat";
    inherit version;
    pyproject = true;

    # needs exactly Python 3.12
    disabled = python3.pkgs.pythonOlder "3.12" || python3.pkgs.pythonAtLeast "3.13";

    src = pkgs.fetchFromGitHub {
      owner = "Aider-AI";
      repo = "aider";
      tag = "v${version}";
      hash = "sha256-J9znZfPcg1cLINFOCSQ6mpr/slL/jQXqenyi3a++VVE=";
    };

    pythonRelaxDeps = true;

    build-system = with python3.pkgs; [ setuptools-scm ];

    dependencies = with python3.pkgs; [
      aiohappyeyeballs
      aiohttp
      aiosignal
      annotated-types
      anyio
      attrs
      backoff
      beautifulsoup4
      certifi
      cffi
      charset-normalizer
      click
      configargparse
      diff-match-patch
      diskcache
      distro
      filelock
      flake8
      frozenlist
      fsspec
      gitdb
      gitpython
      grep-ast
      h11
      httpcore
      httpx
      huggingface-hub
      idna
      importlib-resources
      jinja2
      jiter
      json5
      jsonschema
      jsonschema-specifications
      litellm
      markdown-it-py
      markupsafe
      mccabe
      mdurl
      multidict
      networkx
      numpy
      openai
      packaging
      pathspec
      pexpect
      pillow
      prompt-toolkit
      psutil
      ptyprocess
      pycodestyle
      pycparser
      pydantic
      pydantic-core
      pydub
      pyflakes
      pygments
      pypandoc
      pyperclip
      python-dotenv
      pyyaml
      referencing
      regex
      requests
      rich
      rpds-py
      scipy
      smmap
      sniffio
      sounddevice
      socksio
      soundfile
      soupsieve
      tiktoken
      tokenizers
      tqdm
      tree-sitter
      tree-sitter-language-pack
      typing-extensions
      typing-inspection
      urllib3
      watchfiles
      wcwidth
      yarl
      zipp
      pip

      # Not listed in requirements
      mixpanel
      monotonic
      posthog
      propcache
      python-dateutil

      # NOTE(mjmaurer): Added Gemini deps
      google-generativeai
    ];

    buildInputs = [ pkgs.portaudio ];

    postPatch = ''
      substituteInPlace aider/linter.py --replace-fail "\"flake8\"" "\"${python3.pkgs.flake8}\""
    '';

    disabledTestPaths = [
      # Tests require network access
      "tests/scrape/test_scrape.py"
      # Expected 'mock' to have been called once
      "tests/help/test_help.py"
    ];

    nativeCheckInputs = [
      python3.pkgs.pytestCheckHook
      pkgs.gitMinimal
    ];

    disabledTests =
      [
        # Tests require network
        "test_urls"
        "test_get_commit_message_with_custom_prompt"
        # FileNotFoundError
        "test_get_commit_message"
        # Expected 'launch_gui' to have been called once
        "test_browser_flag_imports_streamlit"
        # AttributeError
        "test_simple_send_with_retries"
        # Expected 'check_version' to have been called once
        "test_main_exit_calls_version_check"
        # AssertionError: assert 2 == 1
        "test_simple_send_non_retryable_error"
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        # Tests fails on darwin
        "test_dark_mode_sets_code_theme"
        "test_default_env_file_sets_automatic_variable"
        # FileNotFoundError: [Errno 2] No such file or directory: 'vim'
        "test_pipe_editor"
      ];

    makeWrapperArgs = [
      "--set"
      "AIDER_CHECK_UPDATE"
      "false"
      "--set"
      "AIDER_ANALYTICS"
      "false"
    ];

    preCheck = ''
      export HOME=$(mktemp -d)
      export AIDER_ANALYTICS="false"
    '';

    optional-dependencies = with python3.pkgs; {
      playwright = [
        greenlet
        playwright
        pyee
        typing-extensions
      ];
      browser = [
        streamlit
      ];
      help = [
        llama-index-core
        llama-index-embeddings-huggingface
        torch
        nltk
      ];
      bedrock = [
        boto3
      ];
    };

    passthru = {
      withOptional =
        {
          withPlaywright ? false,
          withBrowser ? false,
          withHelp ? false,
          withBedrock ? false,
          withAll ? false,
          ...
        }:
        aider-chat.overridePythonAttrs (
          {
            dependencies,
            makeWrapperArgs,
            propagatedBuildInputs ? [ ],
            ...
          }:

          {
            dependencies =
              dependencies
              ++ lib.optionals (withAll || withPlaywright) aider-chat.optional-dependencies.playwright
              ++ lib.optionals (withAll || withBrowser) aider-chat.optional-dependencies.browser
              ++ lib.optionals (withAll || withHelp) aider-chat.optional-dependencies.help
              ++ lib.optionals (withAll || withBedrock) aider-chat.optional-dependencies.bedrock;

            propagatedBuildInputs =
              propagatedBuildInputs
              ++ lib.optionals (withAll || withPlaywright) [ pkgs.playwright-driver.browsers ];

            makeWrapperArgs =
              makeWrapperArgs
              ++ lib.optionals (withAll || withPlaywright) [
                "--set"
                "PLAYWRIGHT_BROWSERS_PATH"
                "${pkgs.playwright-driver.browsers}"
                "--set"
                "PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS"
                "true"
              ]
              ++ lib.optionals (withAll || withHelp) [
                "--set"
                "NLTK_DATA"
                "${aider-nltk-data}"
              ];
          }
        );

      updateScript = lib.nix-update-script {
        extraArgs = [
          "--version-regex"
          "^v([0-9.]+)$"
        ];
      };
    };

    meta = {
      description = "AI pair programming in your terminal";
      homepage = "https://github.com/paul-gauthier/aider";
      changelog = "https://github.com/paul-gauthier/aider/blob/v${version}/HISTORY.md";
      license = lib.licenses.asl20;
      maintainers = with lib.maintainers; [ happysalada ];
      mainProgram = "aider";
    };
  };
in
aider-chat
