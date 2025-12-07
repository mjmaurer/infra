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
      lib
      pythonPkg
      # llmPkg
      ;
    pkgs = pkgs-latest;
  };
  llmPyEnv = pythonPkg.withPackages (
    ps: with ps; [
      llm
      # llm-anthropic
      llm-jq
      customPackages.llm-gemini # this is available, but just outdated
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
        set -o pipefail

        if [ "$#" -gt 1 ]; then
          # All but last arg become pre-args, preserve original word boundaries
          # Store as an array so JSON or spaced values remain single args
          # LLM_ARGS_ARR=("''${@:1:$#-1}")
          LLM_ARGS_ARR=("''${@:1:$(( $# - 1 ))}")
          # for logging/debug:
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

        if [ -n "''${LLM_SESSION_DIR:-}" ] && [ -n "''${LLM_AGENT_NAME:-}" ]; then
          AGENT_DIR="$LLM_SESSION_DIR/$LLM_AGENT_NAME"
          mkdir -p "$AGENT_DIR"

          # Replay mode: if recorded turns exist, render them and exit
          if ls "$AGENT_DIR"/[0-9][0-9]_*.md >/dev/null 2>&1; then
            # Set .turn to last recorded turn so llm-followup appends correctly
            last_turn="$(
              ls -1 "$AGENT_DIR"/[0-9][0-9]_*.md 2>/dev/null \
                | sed -E 's#.*/([0-9][0-9])_.*#\1#' \
                | sort -n | tail -n1
            )"
            if [ -n "$last_turn" ]; then
              printf '%s\n' "$((10#$last_turn))" > "$AGENT_DIR/.turn"
            fi

            # Concatenate in numeric then name order (01_prompt, 01_response, 02_prompt, …)
            for f in "$AGENT_DIR"/[0-9][0-9]_*.md; do
              [ -f "$f" ] || continue
              cat "$f"
              printf '\n'
            done | sd
            sync || true
            # If sourced, return; if executed, exit
            if [ -n "''${ZSH_EVAL_CONTEXT:-}" ]; then
              return 0
            elif [ "''${BASH_SOURCE[0]:-}" != "$0" ]; then
              return 0
            else
              exit 0
            fi
          fi

          # Fresh session: initialize and run first inference
          echo 1 > "$AGENT_DIR/.turn"
          llm -f ${mdFragPath} "$@" | tee "$AGENT_DIR/01_response.md" | sd; sync || true
        else
          echo "Dir or agent variable not provided ('$LLM_SESSION_DIR/$LLM_AGENT_NAME'); running standard llmmd"
          # Fallback to standard rendering
          llmmd "$@"
        fi

        # Preserve CID extraction
        export LLM_CID=$(llm logs --json -n 1 | jq -r '.[0].conversation_id')
        printf '%s\ncid=%s\n' "$LLM_ARGS" "$LLM_CID"
      '')
      (pkgs.writeShellScriptBin "llm-followup" ''
        set -o pipefail
        # Require session + agent for logging; otherwise, fall back
        if [ -z "''${LLM_SESSION_DIR:-}" ] || [ -z "''${LLM_AGENT_NAME:-}" ]; then
          echo "LLM_SESSION_DIR or LLM_AGENT_NAME not set. Not saving response history."
          # Fall back to continuing current conversation if possible
          if [ -n "''${LLM_CID:-}" ]; then
            exec llm -f ${mdFragPath} --cid "$LLM_CID" "$@" | sd
          else
            echo "No LLM_CID, can't use follow-up"
            exec llm -f ${mdFragPath} "$@" | sd
          fi
        fi

        AGENT_DIR="$LLM_SESSION_DIR/$LLM_AGENT_NAME"
        mkdir -p "$AGENT_DIR"

        # Read and increment turn
        if [ -s "$AGENT_DIR/.turn" ]; then
          CURRENT_TURN="$(cat "$AGENT_DIR/.turn")"
        else
          CURRENT_TURN=1
        fi
        NEXT_TURN=$(( CURRENT_TURN + 1 ))

        PROMPT_FILE="$(printf "%s/%02d_prompt.md" "$AGENT_DIR" "$NEXT_TURN")"
        RESP_FILE="$(printf "%s/%02d_response.md" "$AGENT_DIR" "$NEXT_TURN")"

        # Save the prompt exactly as provided
        printf '%s\n' "$*" > "$PROMPT_FILE"

        if [ -n "''${LLM_CID:-}" ]; then
          llm -f ${mdFragPath} --cid "$LLM_CID" "$@" | tee "$RESP_FILE" | sd
        else
          echo "No LLM_CID, can't use follow-up"
          llm -f ${mdFragPath} "$@" | tee "$RESP_FILE" | sd
        fi

        # Ensure response is flushed to disk
        sync || true

        # Update turn counter
        echo "$NEXT_TURN" > "$AGENT_DIR/.turn"
      '')
      (pkgs.writeShellScriptBin "llmhistory" ''
        llm logs --json -n 20 \
          | jq -r '.[].prompt | gsub("\n"; " ") | .[0:250]' \
          | awk '!seen[$0]++ { print $0; print "" }'
      '')
      (pkgs.writeShellScriptBin "llmweb" ''
        llm -f site:$1 -f ${mdFragPath} "''${@:2}" | sd
      '')
      (pkgs.writeShellScriptBin "llmsave" ''
        tmux capture-pane -S -32768 \; save-buffer ${cfgHome}/saved/$1 \; delete-buffer
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

    home.sessionVariables = {
      LLM_SESSION_ROOT =
        if config.modules.obsidian.enable then
          "$HOME/${config.modules.obsidian.vaultPath}/_llm_sessions"
        else
          "${cfgHome}/sessions";
    };

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
      "llm/state/keep" = {
        text = "";
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
              cerebras = "-o provider '{\"order\": [\"cerebras\"], \"allow_fallbacks\": true, \"sort\": \"throughput\"}'";
            };
            fragDir = "$XDG_CONFIG_HOME/llm/fragments";
            tmplDir = "$XDG_CONFIG_HOME/llm/templates";
          in
          {
            lfs = "-f ${fragDir}/succinct.md";
            lfc = "-f ${fragDir}/code.md";
            lft = "-f ${fragDir}/thinking-high.md";

            ltblend = "-t ${tmplDir}/blender.yaml";

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
            lgp = "-m gemini-3-pro-preview ${web.goog}";

            SD = "| sd";
          };
      };
      commonShell = {
        shellAliases = {
          asave = "llmsave";
          a = "llmcmd";
          ai = "llm -t quick";
          ac = "sd --exec \"llm chat -t quick\"";
          af = "llm-followup";
          air = "ai-recall.sh";
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
