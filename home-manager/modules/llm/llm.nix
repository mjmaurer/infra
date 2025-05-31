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
      llmPkg
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
    ]
  );
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
      (pkgs.writeShellScriptBin "llmweb" ''
        llm chat -f site:$1 "$${@:2}"
      '')
      (pkgs.writeShellScriptBin "llmwebsummarize" ''
        llm chat -f site:$1 "${
          builtins.concatStringsSep " " [
            "Summarize this web page"
            "by providing the most interesting details."
          ]
        }"
      '')
      (pkgs.writeShellScriptBin "llmgithub" ''
        llm chat -f github:$1 "$${@:2}"
      '')
      (pkgs.writeShellScriptBin "llmgithubsummarize" ''
        llm chat -f github:$1 "${
          builtins.concatStringsSep " " [
            "Summarize this GitHub repository."
            "Give a brief overview of its purpose,"
            "key features,"
            "any listed comparison to other tools,"
            "and any notable aspects."
          ]
        }"
      '')
    ];

    home.file = {
      ".local/bin/git-commit-ai.sh" = {
        source = ./git-commit-ai.sh;
        executable = true;
      };
    };

    xdg.configFile = {
      "llm/keys.json" = lib.mkIf (keysPath != null) {
        source = config.lib.file.mkOutOfStoreSymlink keysPath;
      };
      "llm/templates" = {
        source = ./templates;
      };
      "llm/default_model.txt" = {
        text = defaultModel;
      };
    };

    modules.commonShell = {
      shellAliases = {
        # Only flash supports search
        a = "llm chat -t quick";
        ai = "llm -t quick";
        ac = "llmcmd";
        ais = "llm -m ${flash} -o google_search 1";
        aiw = "llmweb";
        aiws = "llmwebsummarize";
        aig = "llmgithub";
        aigs = "llmgithubsummarize";
      };
    };
  };
}
