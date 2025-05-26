{ config, lib, ... }:

let
  currentDirEntries = builtins.readDir ./.;

  # Filter for regular files, excluding default.nix itself
  dataFiles = lib.attrsets.filterAttrs (
    name: type: type == "regular" && name != "default.nix"
  ) currentDirEntries;
in
{
  config = lib.mkIf (lib.attrsets.attrNames dataFiles != [ ]) {
    home.file = lib.mapAttrs' (
      fileName: fileType:
      let
        targetPath = "${config.xdg.dataHome}/${fileName}";
        sourcePath = ./${fileName};
      in
      lib.nameValuePair targetPath { source = sourcePath; }
    ) dataFiles;
  };
}
