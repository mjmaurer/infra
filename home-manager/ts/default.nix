{ pkgs }:
let
  bun = pkgs.bun;

  tsEnv = pkgs.stdenv.mkDerivation {
    pname = "ts-env";
    version = "0.1.0";

    src = ./.;

    nativeBuildInputs = [ bun ];

    buildPhase = ''
      runHook preBuild

      export HOME=$TMPDIR
      bun install --frozen-lockfile

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -r node_modules $out/node_modules
      cp tsconfig.json $out/tsconfig.json
      cp package.json $out/package.json

      runHook postInstall
    '';
  };

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
