{ lib, config, pkgs, ... }:
let cfg = config.modules.repomix;
in {
  options.modules.repomix = { enable = lib.mkEnableOption "repomix"; };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.repomix ];

    home.file = {
      ".config/repomix/repomix.config.json".text = builtins.toJSON {
        output = {
          filePath = "repomix-output.txt";
          style = "plain";
          parsableStyle = false;
          compress = false;
          # headerText = "Custom header text";
          # instructionFilePath = "repomix-instruction.md";
          fileSummary = false;
          directoryStructure = false;
          removeComments = false;
          removeEmptyLines = false;
          topFilesLength = 5;
          showLineNumbers = false;
          copyToClipboard = false;
          includeEmptyDirectories = false;
        };
        # include = [ "**/*" ];
        ignore = {
          useGitignore = true;
          useDefaultPatterns = true;
          customPatterns = [
            ".venv"
            "tmp/"
            "**/*.log"
            # Exclude everything except specific file types
            "**/*.!(js|ts|jsx|tsx|py|nix|java|go|md)"
            # But keep README files
            "!README"
            "!**/README*"
          ];
        };
        security = { enableSecurityCheck = true; };
      };
    };

    modules.commonShell = { shellAliases = { rpmxr = "repomix --remote"; }; };
  };
}
