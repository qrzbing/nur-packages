{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  minimal ? false,
  gdb-static,
  fetchurl,
}:

let
  gdbStatic = gdb-static.override {
    inherit minimal;
    pythonSupport = true;
  };
  # gef older than 2016 will crash on gdb 17: <https://github.com/guyush1/gdb-static/releases/tag/v17.1-static>
  gdbStaticOld = gdbStatic.overrideAttrs (oldAttrs: rec {
    version = "16.3";
    src = fetchurl {
      url = "https://github.com/guyush1/gdb-static/releases/download/v${version}-static/gdb-static-full-x86_64.tar.gz";
      sha256 = "sha256-Jc2nLkDbyEQWK5gHk615twT+bJAzke8THvyH6KoOyrc=";
    };
  });
in
stdenv.mkDerivation rec {
  pname = "gef-static";
  version = "2025.01";

  src = fetchFromGitHub {
    owner = "hugsy";
    repo = "gef";
    rev = version;
    sha256 = "sha256-JM9zH1wWEdjpBafnxMIFtePjXWf3UOXhBSWZCXEOzKw=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  dontPatchELF = true;

  installPhase = ''
    mkdir -p $out/share/gef
    cp gef.py $out/share/gef
    makeWrapper ${gdbStaticOld}/bin/gdb $out/bin/gef \
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
