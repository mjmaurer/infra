{
  inputs = {
    base-flake.url = "github:mjmaurer/infra?dir=flakes/base";
  };
  outputs = { self, base-flake }:
    {
      lib = base-flake.lib // {
        readme = ''
        '';

        mkInitHook = pkgs: with pkgs; ''
          export DISPLAY=$(netstat -rn | grep default | grep -v utun | head -n1 | awk '{print $2}'):0
        '';

        mkInitReadme = pkgs: with pkgs; ''
          ## mkInitHook
          ```bash
          export DISPLAY=$(netstat -rn | grep default | grep -v utun | head -n1 | awk '{print $2}'):0
          ```
        '';

        mkJava = pkgs: pkgs.jdk17;
        mkLang = self.lib.mkJava;

        mkPackages = pkgs: with pkgs; [
          (self.lib.mkLang pkgs)
          maven
        ];
      };
    };
}
