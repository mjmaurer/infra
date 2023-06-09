with import <nixpkgs> { };

stdenv.mkDerivation {
  name = "node";
  buildInputs = [ ansible ];
}