{ ... }:
{
  sops = {
    age.keyFile = "/var/lib/sops-nix/key.txt";
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      rootPassword = {
        neededForUsers = true;
        path = "/etc/passwords/root";
      };
      mjmaurerPassword = {
        neededForUsers = true;
        path = "/etc/passwords/mjmaurer";
      };
      mjmaurerOpenvpnCA = {
        path = "/etc/vpn/mjmaurer/ca.crt";
      };
      mjmaurerOpenvpnCert = {
        path = "/etc/vpn/mjmaurer/mjmaurer.crt";
      };
      mjmaurerOpenvpnKey = {
        path = "/etc/vpn/mjmaurer/mjmaurer.key";
      };
      mjmaurerPritunlConfig = {
        path = "/etc/vpn/mjmaurer/pritunl.ovpn";
      };
    };
  };
}
