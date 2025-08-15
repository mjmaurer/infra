{
  lib,
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
  defaultModel = "gemini-2.5-flash";
  flash = "gemini-2.5-flash";
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
      customPackages.llm-fragments-github
      customPackages.llm-fragments-site-text
      customPackages.llm-cmd-comp
      customPackages.streamdown
    ]
  );
  mdFragPath = "$XDG_CONFIG_HOME/llm/fragments/markdown-output.md";
  conciseFragPath = "$XDG_CONFIG_HOME/llm/fragments/concise.md";
  keysPath =
    if osConfig != null then
      if builtins.hasAttr "llm-keys-full" osConfig.sops.templates then
        osConfig.sops.templates.llm-keys-full.path
      else if builtins.hasAttr "llm-keys-minimal" osConfig.sops.templates then
        osConfig.sops.templates.llm-keys-minimal.path
      else
        null
    else
      null;
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
      (pkgs.writeShellScriptBin "llmweb" ''
        llm -f site:$1 -f ${mdFragPath} "$${@:2}" | sd
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
        llm -f github:$1 -f ${mdFragPath} "$${@:2}" | sd
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
      (pkgs.writeShellScriptBin "llmfollowup" ''
        llm -f ${conciseFragPath} -f ${mdFragPath} -c "$@" | sd
      '')
      (pkgs.writeShellScriptBin "llmbar" ''
        llm -f ${conciseFragPath} -f ${mdFragPath} "$@" | sd
      '')
      (pkgs.writeShellScriptBin "llmhistory" ''
        llm logs --json -n 20 \
          | jq -r '.[].prompt | gsub("\n"; " ") | .[0:250]' \
          | awk '!seen[$0]++ { print $0; print "" }'
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
      "llm/keys.json" = lib.mkIf (keysPath != null) {
        source = config.lib.file.mkOutOfStoreSymlink keysPath;
      };
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

    modules.commonShell = {
      shellAliases = {
        a = "llmcmd";
        ac = "sd --exec \"llm chat -t quick\"";
        ai = "llm -t quick";
        af = "llmfollowup";
        aiw = "llmweb";
        aiws = "llmwebsummarize";
        aig = "llmgithub";
        aigs = "llmgithubsummarize";
        ah = "llmhistory";
      };
    };
  };
}
