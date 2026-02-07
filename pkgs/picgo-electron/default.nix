{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs_22,
  pnpm,
  fetchPnpmDeps,
  pnpmConfigHook,
  electron_38,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
}:

stdenv.mkDerivation rec {
  pname = "picgo-electron";
  version = "2.5.0";

  src = fetchFromGitHub {
    owner = "Molunerfinn";
    repo = "PicGo";
    rev = "v${version}";
    hash = "sha256-M3cA17DoPXfldvq1vjF3P9HEXGkd+TXFuTr95iqIWsQ=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    hash = "sha256-BfKTZy9NBfBj0MwREoxYmyvhfXP4FlADam2SwNTOJ2U=";
    fetcherVersion = 3; # lockfileVersion 9.0 corresponds to fetcherVersion 3
  };

  nativeBuildInputs = [
    nodejs_22
    pnpm
    pnpmConfigHook
    makeWrapper
    copyDesktopItems
  ];

  # Environment variables
  ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
  SYSTEM_ELECTRON_VERSION = electron_38.version;

  # Configuration phase
  preConfigure = ''
    export HOME=$(mktemp -d)
    export PNPM_HOME="$HOME/.pnpm"
  '';

  # Build phase
  buildPhase = ''
    runHook preBuild

    export NODE_ENV=development
    echo "Building PicGo with electron-vite..."
    pnpm run build

    runHook postBuild
  '';

  # Installation phase
  installPhase = ''
        runHook preInstall

        # Create application directory
        mkdir -p $out/lib/${pname}

        # Copy build outputs
        cp -r dist_electron $out/lib/${pname}/
        cp -r public $out/lib/${pname}/
        cp package.json $out/lib/${pname}/
        cp -r node_modules $out/lib/${pname}/

        # Create launcher script to set application name
        cat > $out/lib/${pname}/.launcher.js <<'EOF'
    const { app } = require('electron');
    const path = require('path');

    // Set application name (determines config directory as ~/.config/picgo)
    app.setName('picgo');

    // Load main process
    require(path.join(__dirname, 'dist_electron/main/index.js'));
    EOF

        # Create startup script
        mkdir -p $out/bin
        makeWrapper ${electron_38}/bin/electron $out/bin/picgo \
          --add-flags "$out/lib/${pname}/.launcher.js" \
          --set NODE_ENV production \
          --chdir "$out/lib/${pname}"

        # Install icons
        for size in 256x256 512x512; do
          if [ -f "build/icons/$size.png" ]; then
            mkdir -p $out/share/icons/hicolor/$size/apps
            cp "build/icons/$size.png" $out/share/icons/hicolor/$size/apps/${pname}.png
          fi
        done

        runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = pname;
      desktopName = "PicGo";
      comment = "A simple & beautiful tool for pictures uploading";
      exec = "picgo %U";
      icon = pname;
      categories = [
        "Utility"
        "Graphics"
      ];
      mimeTypes = [ "x-scheme-handler/picgo" ];
      startupWMClass = "PicGo";
    })
  ];

  meta = with lib; {
    description = "A simple & beautiful tool for pictures uploading built by electron-vue";
    longDescription = ''
      PicGo is a simple & beautiful tool for pictures uploading built by electron-vue.
      It supports uploading images to various cloud storage services and clipboard management.
      The application features a plugin system for extending functionality.
    '';
    homepage = "https://github.com/Molunerfinn/PicGo";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "picgo";
    maintainers = with maintainers; [ qrzbing ];
  };
}
