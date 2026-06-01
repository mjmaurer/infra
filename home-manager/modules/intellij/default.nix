{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.intellij;
in
{
  options.modules.intellij = {
    enable = lib.mkEnableOption "intellij";

    ideaVersion = lib.mkOption {
      type = lib.types.str;
      default = "2025.1";
      description = "IntelliJ IDEA version string (e.g. '2025.1') for the config directory path.";
    };

    keymapName = lib.mkOption {
      type = lib.types.str;
      default = "NixManaged";
      description = "Name for the custom keymap. Must be selected in IntelliJ Settings > Keymap after first deploy.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.file.".ideavimrc".text = import ./ideavimrc.nix;

    home.file."Library/Application Support/JetBrains/IntelliJIdea${cfg.ideaVersion}/keymaps/${cfg.keymapName}.xml".text =
      import ./keymap.nix { keymapName = cfg.keymapName; };
  };
}
