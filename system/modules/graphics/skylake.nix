{ pkgs, ... }:
{
  nixpkgs.config.packageOverrides = pkgs: {
    # Hybrid driver might provide VP9 for skylake, but this was also archived a long time ago.
    # Probably don't need VP9 (it's video codec), and could comment out if trouble
    intel-vaapi-driver = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
  };
}
