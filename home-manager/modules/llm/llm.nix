{
  lib,
  config,
  osConfig ? null,
  pkgs,
  pkgs-latest,
  ...
}:
let
  cfg = config.modules.llm;
  cfgHome = "${config.xdg.configHome}/llm";
  defaultModel = "gemini-2.5-flash-preview-05-20";
  flash = "gemini-2.5-flash-preview-05-20";
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
 
