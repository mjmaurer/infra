{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.global = {
    # TODO: remove
    maybeImpermPrefix = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default =
        if (builtins.hasAttr "impermanence" config.modules) && config.modules.impermanence.enabled then
          "${config.modules.impermanence.impermanenceMntPath}"
        else
          "";
      description = "Path to the impermanence mount point if enabled.";
    };
  };
}
