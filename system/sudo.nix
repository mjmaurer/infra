{ pkgs, config, ... }:
{
  security.sudo = {
    enable = true;
    extraRules = [{
      # 'wheel' users will be able to suspend, reboot, and poweroff without a password
      commands = [
        {
          command = "${pkgs.systemd}/bin/systemctl suspend";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.systemd}/bin/reboot";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.systemd}/bin/poweroff";
          options = [ "NOPASSWD" ];
        }
      ];
      groups = [ "wheel" ];
    }];
    # extraConfig = with pkgs; ''
    #   Defaults:picloud secure_path="${lib.makeBinPath [
    #     systemd
    #   ]}:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin"
    # '';
  };
}
