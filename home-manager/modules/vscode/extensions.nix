{ pkgs, lib }:

let
  inherit (pkgs.stdenv) isDarwin isLinux isi686 isx86_64 isAarch32 isAarch64;
  vscode-utils = pkgs.vscode-utils;
  merge = lib.attrsets.recursiveUpdate;
in merge (merge (merge (merge {
  "github"."vscode-pull-request-github" =
    vscode-utils.extensionFromVscodeMarketplace {
      name = "vscode-pull-request-github";
      publisher = "github";
      version = "0.103.2024121117";
      sha256 = "0k90870ra85np0dg19mx2blr1yg9i2sk25mx08bblqh0hh0s5941";
    };
  "github"."copilot-chat" = vscode-utils.extensionFromVscodeMarketplace {
    name = "copilot-chat";
    publisher = "github";
    version = "0.24.2024121201";
    sha256 = "14cs1ncbv0fib65m1iv6njl892p09fmamjkfyxrsjqgks2hisz5z";
  };
} (lib.attrsets.optionalAttrs (isLinux && (isi686 || isx86_64)) { }))
  (lib.attrsets.optionalAttrs (isLinux && (isAarch32 || isAarch64)) { }))
  (lib.attrsets.optionalAttrs (isDarwin && (isi686 || isx86_64)) { }))
(lib.attrsets.optionalAttrs (isDarwin && (isAarch32 || isAarch64)) { })