{ pkgs }:
let
  bun = pkgs.bun;

  # node_modules as a fixed-output derivation: the only kind of build allowed
  # network access inside the Nix sandbox (on by default on NixOS, off on darwin).
  # Update `outputHash` whenever bun.lock changes: set it to lib.fakeHash, build,
  # and copy the "got:" hash from the error.
  tsDeps = pkgs.stdenvNoCC.mkDerivation {
    pname = "ts-env-deps";
    version = "0.1.0";

    src = pkgs.lib.fileset.toSource {
      root = ./.;
      fileset = pkgs.lib.fileset.unions [
        ./package.json
        ./bun.lock
      ];
    };

    nativeBuildInputs = [ bun ];

    dontConfigure = true;
    dontFixup = true; # don't patch/strip anything; it would change the output hash

    buildPhase = ''
      runHook preBuild

      export HOME=$TMPDIR
      export BUN_INSTALL_CACHE_DIR=$TMPDIR/bun-cache
      bun install --frozen-lockfile --ignore-scripts --no-progress

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      cp -r node_modules $out

      runHook postInstall
    '';

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-8f9Iujj+NdOBk1EHtgIDWEE7fjYk3wErWinLGPMKm60=";
  };

  tsEnv = pkgs.runCommand "ts-env-0.1.0" { } ''
    mkdir -p $out
    ln -s ${tsDeps} $out/node_modules
    cp ${./tsconfig.json} $out/tsconfig.json
    cp ${./package.json} $out/package.json
  '';

  mkTsScript =
    {
      name,
      script,
      runtimeInputs ? [ ],
    }:
    let
      scriptName = builtins.baseNameOf (toString script);
      scriptDir = pkgs.runCommand "${name}-script-dir" { } ''
        mkdir -p $out
        ln -s ${tsEnv}/node_modules $out/node_modules
        ln -s ${tsEnv}/tsconfig.json $out/tsconfig.json
        ln -s ${tsEnv}/package.json $out/package.json
        cp ${script} $out/${scriptName}
      '';
      runtimePath = pkgs.lib.makeBinPath runtimeInputs;
    in
    pkgs.writeShellScriptBin name ''
      ${pkgs.lib.optionalString (runtimeInputs != [ ]) ''export PATH="${runtimePath}:$PATH"''}
      exec ${bun}/bin/bun run ${scriptDir}/${scriptName} "$@"
    '';
in
{
  inherit tsEnv;
  inherit mkTsScript;
}
