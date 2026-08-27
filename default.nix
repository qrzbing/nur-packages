# This file describes your repository contents.
# It should return a set of nix derivations
# and optionally the special attributes `lib`, `nixosModules` and `overlays`.
# It should NOT import <nixpkgs>. Instead, you should take pkgs as an argument.
# Having pkgs default to <nixpkgs> is fine though, and it lets you use short
# commands such as:
#     nix-build -A mypackage

{
  pkgs ? import <nixpkgs> { },
}:

{
  # The `lib`, `nixosModules`, and `overlays` names are special
  lib = import ./lib { inherit pkgs; }; # functions
  nixosModules = import ./nixos-modules; # NixOS modules
  overlays = import ./overlays; # nixpkgs overlays

  lanxin = pkgs.callPackage ./pkgs/lanxin { };
  musescore = pkgs.callPackage ./pkgs/musescore { };
  sam-toki-mouse-cursors = pkgs.callPackage ./pkgs/sam-toki-mouse-cursors { };
  # ...
}
