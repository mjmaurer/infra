{
  writeShellApplication,
  colmapWithCuda,
}:
let
  shellApp =
    { name, text }:
    writeShellApplication {
      inherit name text;
      runtimeInputs = [ colmapWithCuda ];
    };
in
{
  pics-to-model = shellApp {
    name = "pics-to-model";
    text = builtins.readFile ./pics-to-model.sh;
  };
}
