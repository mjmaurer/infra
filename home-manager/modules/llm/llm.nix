# TROUBLESHOOTING
# For SQL issues, delete ~/.config/llm/logs.db
{
  lib,
  mylib,
  config,
  osConfig ? null,
  pkgs,
  pkgs-latest,
  isDarwin,
  ...
}:
let
  cfg = config.modules.llm;
  cfgHome = "${config.xdg.configHome}/llm";
  defaultModel = "openrouter/openai/gpt-oss-120b";
  pythonPkg = pkgs-latest.python312;
  llmPkg = pkgs-latest.llm;
  customPackages = import ./custom-pkgs.nix {
    inherit
      pkgs
      lib
      pythonPkg
      # llmPkg
      ;
  };
  llmPyEnv = pythonPkg.withPackages (
    ps: with ps; [
      llm
      # llm-anthropic
      llm-gemini
      llm-jq
      customPackages.llm-openrouter # this is available, but just outdated
      customPackages.llm-fragments-github
      customPackages.llm-fragments-site-text
      customPackages.llm-cmd-comp
      customPackages.streamdown
    ]
  );
  mdFragPath = "$XDG_CONFIG_HOME/llm/fragments/markdown-output.md";
  succinctFragPath = "$XDG_CONFIG_HOME/llm/fragments/succinct.md";
  streamdownConfig = ''
    [features]
    CodeSpaces = false
    Clipboard  = true
    Logging    = false
    Timeout    = 0.1
    Savebrace  = true

    [style]
    Margin          = 2 
    ListIndent      = 2
    PrettyPad       = true
    PrettyBroken    = true
    Width           = 0

    HSV = [0.147, 0.137, 0.976]

    # Code blocks / dark surfaces: darker so blocks stand out (~1.9:1 vs page)
    # For gruvbox-light (currently broken see https://github.com/day50-dev/Streamdown/issues/26)
    # Dark = { H = 1.2, S = 1.5, V = 1.1 }
    # for 'native':
    Dark = { H = 0.0, S = 0.0, V = 0.13 }

    # Blockquotes / small headings: much higher contrast for readability (≥4.5:1)
    Grey   = { H = 1.00, S = 1.15, V = 0.46 }

    # Inline code & table headers: a bit richer but still “chip-y”
    # (good contrast for text on the chip, ~1.64 vs page, ~4.65 for #654735 text)
    Mid    = { H = 1.57, S = 1.4, V = 0.84 }

    # Bullets / links / rules: a touch more saturated blue but still accessible (≥4.6:1)
    Symbol = { H = 3.60, S = 3.60, V = 0.52 }

    # Headers (keep strong contrast)
    Head   = { H = 0.43, S = 3.50, V = 0.41 }

    # H1/H2 accent (slightly richer, still ≥5.8:1)
    Bright = { H = 0.43, S = 3.60, V = 0.50 }

    # Code token colors (unchanged)
    # Syntax = "gruvbox-light"
    Syntax = "native"
  '';
in
{
  options.modules.llm = {
    enable = lib.mkEnableOption "llm";
  };

  config = lib.mkIf cfg.enable {
    modules.commonShell.initExtraLast = lib.mkAfter ''
      ${builtins.readFile ./llm_helpers.sh}
    '';

    home.packages = [

      (pkgs.writeShellScriptBin "llm" ''
        export LLM_USER_PATH="${cfgHome}"
        exec "${llmPyEnv}/bin/llm" "$@"
      '')
      (pkgs.writeShellScriptBin "sd" ''
        exec "${llmPyEnv}/bin/sd" "$@"
      '')
      (pkgs.writeShellScriptBin "llmmd" ''
        llm -f ${mdFragPath} "$@" | sd
      '')
      # Exports LLM_ARGS for use in llmchat sessions
      (pkgs.writeShellScriptBin "llmchat" ''
        # Don't use set -e when script might be sourced
        # Don't use set -u as it can break zsh widgets when sourced
        set -o pipefail

        if [ "$#" -gt 1 ]; then
          # All but last arg become pre-args, preserve original word boundaries
          # Store as an array so JSON or spaced values remain single args
          # LLM_ARGS_ARR=("''${@:1:$#-1}")
          LLM_ARGS_ARR=("''${@:1:$(( $# - 1 ))}")
          # Optional: keep a printable string for logging/debug
          LLM_ARGS=""
          for _arg in "''${LLM_ARGS_ARR[@]}"; do
            if [ -z "$LLM_ARGS" ]; then
              LLM_ARGS="$_arg"
            else
              LLM_ARGS="$LLM_ARGS $_arg"
            fi
          done
          export LLM_ARGS
        else
          unset LLM_ARGS_ARR
          export LLM_ARGS=""
        fi

        llmmd "$@"
        export LLM_CID=$(llm logs --json -n 1 | jq -r '.[0].conversation_id')
        printf '%s\ncid=%s\n' "$LLM_ARGS" "$LLM_CID"
      '')
      (pkgs.writeShellScriptBin "llmhistory" ''
        llm logs --json -n 20 \
          | jq -r '.[].prompt | gsub("\n"; " ") | .[0:250]' \
          | awk '!seen[$0]++ { print $0; print "" }'
      '')
      (pkgs.writeShellScriptBin "llmweb" ''
        llm -f site:$1 -f ${mdFragPath} "''${@:2}" | sd
      '')
      (pkgs.writeShellScriptBin "llmwebsummarize" ''
        llm -f site:$1 -f ${mdFragPath} "${
          builtins.concatStringsSep " " [
            "Summarize this web page"
            "by providing the most interesting details."
          ]
        }"
      '')
      (pkgs.writeShellScriptBin "llmgithub" ''
        llm -f github:$1 -f ${mdFragPath} "''${@:2}" | sd
      '')
      (pkgs.writeShellScriptBin "llmgithubsummarize" ''
        llm -f github:$1 -f ${mdFragPath} "${
          builtins.concatStringsSep " " [
            "Summarize this GitHub repository."
            "Give a brief overview of its purpose,"
            "key features,"
            "any listed comparison to other tools,"
            "and any notable aspects."
          ]
        }" | sd
      '')
    ];

    home.file = {
      ".local/bin/git-commit-ai.sh" = {
        source = ./git-commit-ai.sh;
        executable = true;
      };
      ".local/state/llm/keep" = {
        text = "";
      };
      "Library/Application Support/streamdown/config.toml" = lib.mkIf (isDarwin) {
        text = streamdownConfig;
      };
    };

    xdg.configFile = {
      "llm/keys.json" = mylib.sops.maybeSopsTemplateSymlink "llm-keys" osConfig config;
      "llm/templates" = {
        source = ./templates;
      };
      "llm/fragments" = {
        source = ./fragments;
      };
      "llm/default_model.txt" = {
        text = defaultModel;
      };
      "streamdown/config.toml" = lib.mkIf (!isDarwin) {
        text = streamdownConfig;
      };
    };

    modules = {
      zsh = {
        shellGlobalAliases =
          let
            reason = {
              high = "-o reasoning_effort high";
              medium = "-o reasoning_effort medium";
              low = "-o reasoning_effort low";
            };
            web = {
              exa = "-o online 1"; # Openrouter provided Exa search
              goog = "-o google_search 1";
              # Openai resposnes api does support web, but llm doesn't support that
              # openai = "-o extra_body '{\"only\": [\"cerebras\"]}'"
            };
            provider = {
              cerebras = "-o provider '{\"only\": [\"cerebras\"]}'";
            };
            fragDir = "$XDG_CONFIG_HOME/llm/fragments";
          in
          {
            lfs = "-f ${fragDir}/succinct.md";
            lfc = "-f ${fragDir}/code.md";
            lft = "-f ${fragDir}/thinking-high.md";

            lonline = web.exa;

            lfh = "-m gpt-5 ${reason.high}";
            lfm = "-m gpt-5 ${reason.medium}";
            lfl = "-m gpt-5 ${reason.low}";
            lth = "-m o3 ${reason.high}";
            ltm = "-m o3 ${reason.medium}";
            ltl = "-m o3 ${reason.low}";
            loh = "-m openrouter/openai/gpt-oss-120b ${reason.high} ${provider.cerebras}";
            lom = "-m openrouter/openai/gpt-oss-120b ${reason.medium} ${provider.cerebras}";
            lol = "-m openrouter/openai/gpt-oss-120b ${reason.low} ${provider.cerebras}";
            lqc = "-m openrouter/qwen/qwen3-coder ${reason.high} ${provider.cerebras}";
            lqt = "-m openrouter/qwen/qwen3-235b-a22b-thinking-2507 ${reason.high} ${provider.cerebras}";
            lgf = "-m gemini-2.5-flash ${web.goog}";
            lgp = "-m gemini-2.5-pro ${web.goog}";

            SD = "| sd";
          };
      };
      commonShell = {
        shellAliases = {
          a = "llmcmd";
          ai = "llm -t quick";
          ac = "sd --exec \"llm chat -t quick\"";
          af = ''llmmd --cid "$LLM_CID" "''${(@)LLM_ARGS_ARR}"'';
          aiw = "llmweb";
          aiws = "llmwebsummarize";
          aig = "llmgithub";
          aigs = "llmgithubsummarize";
          ah = "llmhistory";

          # i.e. openrouter/openai/gpt-oss-120b
          aioptions = "llm models --options -q ";
        };
      };
    };
  };
}
