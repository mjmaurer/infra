# Generates an iTerm2 .itermcolors plist from a base16 color palette.
# Color mapping matches alacritty.nix (base05→black, base00→white, etc.)
{ lib, palette }:
let
  hexDigitToInt =
    c:
    {
      "0" = 0;
      "1" = 1;
      "2" = 2;
      "3" = 3;
      "4" = 4;
      "5" = 5;
      "6" = 6;
      "7" = 7;
      "8" = 8;
      "9" = 9;
      "a" = 10;
      "b" = 11;
      "c" = 12;
      "d" = 13;
      "e" = 14;
      "f" = 15;
      "A" = 10;
      "B" = 11;
      "C" = 12;
      "D" = 13;
      "E" = 14;
      "F" = 15;
    }
    .${c};

  hexPairToInt = a: b: hexDigitToInt a * 16 + hexDigitToInt b;

  hexToRgbFloats =
    hex:
    let
      chars = lib.stringToCharacters hex;
    in
    {
      red = (hexPairToInt (builtins.elemAt chars 0) (builtins.elemAt chars 1)) * 1.0 / 255;
      green = (hexPairToInt (builtins.elemAt chars 2) (builtins.elemAt chars 3)) * 1.0 / 255;
      blue = (hexPairToInt (builtins.elemAt chars 4) (builtins.elemAt chars 5)) * 1.0 / 255;
    };

  colorEntry =
    name: hex:
    let
      c = hexToRgbFloats hex;
    in
    ''
      <key>${name}</key>
      <dict>
        <key>Color Space</key>
        <string>sRGB</string>
        <key>Red Component</key>
        <real>${toString c.red}</real>
        <key>Green Component</key>
        <real>${toString c.green}</real>
        <key>Blue Component</key>
        <real>${toString c.blue}</real>
      </dict>'';

  # Same base16 → ANSI mapping as alacritty.nix
  black = palette.base05;
  red = palette.base08;
  green = palette.base0B;
  yellow = palette.base0A;
  blue = palette.base0D;
  magenta = palette.base0E;
  cyan = palette.base0C;
  white = palette.base00;

  background = palette.base00;
  foreground = palette.base05;
  selection = palette.base02;
in
''
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
  ${colorEntry "Ansi 0 Color" black}
  ${colorEntry "Ansi 1 Color" red}
  ${colorEntry "Ansi 2 Color" green}
  ${colorEntry "Ansi 3 Color" yellow}
  ${colorEntry "Ansi 4 Color" blue}
  ${colorEntry "Ansi 5 Color" magenta}
  ${colorEntry "Ansi 6 Color" cyan}
  ${colorEntry "Ansi 7 Color" white}
  ${colorEntry "Ansi 8 Color" black}
  ${colorEntry "Ansi 9 Color" red}
  ${colorEntry "Ansi 10 Color" green}
  ${colorEntry "Ansi 11 Color" yellow}
  ${colorEntry "Ansi 12 Color" blue}
  ${colorEntry "Ansi 13 Color" magenta}
  ${colorEntry "Ansi 14 Color" cyan}
  ${colorEntry "Ansi 15 Color" white}
  ${colorEntry "Background Color" background}
  ${colorEntry "Foreground Color" foreground}
  ${colorEntry "Bold Color" foreground}
  ${colorEntry "Cursor Color" foreground}
  ${colorEntry "Cursor Text Color" white}
  ${colorEntry "Selection Color" selection}
  ${colorEntry "Selected Text Color" foreground}
  </dict>
  </plist>
''
