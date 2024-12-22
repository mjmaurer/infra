{
  inputs = {
    base-flake.url = "github:mjmaurer/infra?dir=flakes/base";
  };
  outputs = { self, base-flake }:
    {
      lib = base-flake.lib // {
        readme = ''
        '';

        mkInitReadme = pkgs: with pkgs; ''
          Add the following to your shell if you need to run java applications:
          ```bash
          export DISPLAY=$(ip route list default | awk '{print $3}'):0
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
