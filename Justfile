update:
    nix flake update

build package:
    nix build .#{{package}}
