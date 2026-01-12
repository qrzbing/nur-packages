{
  lib,
  stdenv,
  fetchurl,
  pythonSupport ? true,
  minimal ? false,
}:

let
  version = "17.1";

  archSuffix =
    {
      "x86_64-linux" = "x86_64";
    }
    .${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  variant = if pythonSupport then "full" else "slim";

  sources = {
    full = {
      "x86_64" = {
        hash = "sha256-5cBovIpJewUsrT5up7IwpMcuiX3ub5lqq6ZUUJQInxQ=";
      }; # x86_64 Full
    };
    slim = {
      "x86_64" = {
        hash = "sha256-Jy3MepVbm3veOog7kj/fRNnsqzHG4Om/XBQfMlZozzU=";
      }; # x86_64 Slim
    };
  };

  currentSource = sources.${variant}.${archSuffix};

in
stdenv.mkDerivation rec {
  pname = "gdb-static";
  inherit version;

  src = fetchurl {
    url = "https://github.com/guyush1/gdb-static/releases/download/v${version}-static/gdb-static-${variant}-${archSuffix}.tar.gz";
    sha256 = currentSource.hash;
  };

  sourceRoot = ".";
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  dontPatchELF = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    ${
      if minimal then
        ''
          cp gdb $out/bin/
        ''
      else
        ''
          cp -r * $out/bin/
          chmod +x $out/bin/*
        ''
    }

    runHook postInstall
  '';

  meta = with lib; {
    description = "GNU Project debugger (Static Binary)";
    longDescription = ''
      GDB, the GNU Project debugger, allows you to see what is going
      on `inside' another program while it executes -- or what another
      program was doing at the moment it crashed.

      This package contains statically linked binaries, reducing closure size significantly.
    '';
    homepage = "https://github.com/guyush1/gdb-static";
    license = licenses.gpl3Plus;
    platforms = [
      "x86_64-linux"
    ];
    mainProgram = "gdb";
    maintainers = with maintainers; [ qrzbing ];
  };
}
