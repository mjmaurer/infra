{
  inputs = {
    base-flake.url = "github:mjmaurer/infra?dir=flakes/base";
  };
  outputs = { self, base-flake }:
    {
      lib = base-flake.lib // {
        readme = ''
        '';

        overlays = [
          (final: prev: {
            yarn = prev.yarn.override {
              nodejs = self.lib.mkNode final;
            };
          })
        ];

        mkNode = pkgs: pkgs.nodejs_22;
        mkLang = self.lib.mkNode;
        mkPackages = pkgs: with pkgs; [
          (self.lib.mkNode pkgs)
          yarn
        ];
      };
    };
}
