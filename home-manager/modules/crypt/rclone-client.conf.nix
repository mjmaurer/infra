{ pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellScriptBin "rclone-sftp" ''
      echo "NOTE: For destination, must use an sftp configured remote (i.e. 'willow-sftp:/path/on/willow')"
      read -r -p "Enter keyfile path: " RCLONE_SFTP_KEY_FILE
      read -s -p "Enter keyfile password: " keyfilepass
      echo
      export RCLONE_SFTP_KEY_FILE
      export RCLONE_SFTP_KEY_FILE_PASS=$(echo -n "$keyfilepass" | ${pkgs.rclone}/bin/rclone obscure -)

      # We use the full path to rclone to be explicit and robust
      ${pkgs.rclone}/bin/rclone "$@"
    '')
  ];

  xdg.configFile."rclone/rclone.conf".text = ''
    [willow-sftp]
    type = sftp
    host = willow
    port = 2222
    user = mjmaurer
  '';
}
