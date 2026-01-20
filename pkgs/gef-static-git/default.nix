{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  minimal ? false,
  gdb-static,
}:

let
  gdbStatic = gdb-static.override {
    inherit minimal;
    pythonSupport = true;
  };
in
stdenv.mkDerivation {
  pname = "gef-static-git";
  version = "unstable-2026.01.10";

  src = fetchFromGitHub {
    owner = "hugsy";
    repo = "gef";
    rev = "60a99cb7fdfcc40310187eca243a8a2052127406";
    sha256 = "sha256-8sRiQ23BsloLqdZwBcI3BCqeEJ9WyUVSqD2d67pr2gE=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  dontPatchELF = true;

  installPhase = ''
    mkdir -p $out/share/gef
    cp gef.py $out/share/gef
    makeWrapper ${gdbStatic}/bin/gdb $out/bin/gef \
      --add-flags "-q -x $out/share/gef/gef.py"
  '';

  meta = {
    description = "Modern experience for (static) GDB with advanced debugging features for exploit developers & reverse engineers";
    mainProgram = "gef";
    homepage = "https://github.com/hugsy/gef";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [ qrzbing ];
  };
}
