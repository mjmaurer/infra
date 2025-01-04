{ lib, ... }:
{
  # Keep up to 10 previous generations in GRUB boot menu
  # They will get garbage collected after
  boot.loader.grub.configurationLimit = lib.mkDefault 10;
}

