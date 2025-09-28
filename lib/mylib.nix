{ lib, sysTags }:
let
  possibleSysTags = [
    "linux"
    "darwin"
    # Full-featured client machine (laptop/desktop)
    # Implies `dev-client`
    "full-client"
    # Machine where development might occur (i.e. git usage, vim, ai, etc)
    "dev-client"
  ];
  # Validate sysTags
  _ = lib.assertMessage (lib.all (tag: lib.elem tag possibleSysTags) sysTags) (
    "Invalid sysTag in " + lib.toString sysTags + ". Must be one of " + lib.toString possibleSysTags
  );
in
{
  # Check if any of the system tags are in the passed tags
  # See flake.nix for tagging
  sysTagsIn = tags: builtins.any (tag: builtins.elem tag tags) sysTags;

  # builtins.toString is equivalent
  nullToEmpty = x: if x == null then "" else x;

  sops = rec {
    hasSopsTemplate = name: osConfig: osConfig ? sops && builtins.hasAttr name osConfig.sops.templates;
    hasSopsSecret = name: osConfig: osConfig ? sops && builtins.hasAttr name osConfig.sops.secret;
    sopsTemplatePath = name: osConfig: osConfig.sops.templates.${name}.path;
    sopsSecretPath = name: osConfig: osConfig.sops.templates.${name}.path;

    maybeSopsTemplate =
      name: osConfig: config:
      lib.mkIf (hasSopsTemplate name osConfig) {
        source = sopsTemplatePath name osConfig;
      };
    maybeSopsTemplateSymlink =
      name: osConfig: config:
      lib.mkIf (hasSopsTemplate name osConfig) {
        source = config.lib.file.mkOutOfStoreSymlink (sopsTemplatePath name osConfig);
      };
    maybeSopsSecret =
      name: osConfig: config:
      lib.mkIf (hasSopsSecret name osConfig) {
        source = (sopsSecretPath name osConfig);
      };
    maybeSopsSecretSymlink =
      name: osConfig: config:
      lib.mkIf (hasSopsSecret name osConfig) {
        source = config.lib.file.mkOutOfStoreSymlink (sopsSecretPath name osConfig);
      };
    maybeSopsSecretList =
      name: osConfig: config:
      lib.mkIf (hasSopsSecret name osConfig) [
        {
          source = (sopsSecretPath name osConfig);
        }
      ];
  };
}
