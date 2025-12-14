{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libxkbcommon,
  mesa,
  nspr,
  nss,
  pango,
  systemd,
  xorg,
  libglvnd,
}:

stdenv.mkDerivation rec {
  pname = "feishin";
  version = "0.22.0";

  src = fetchurl {
    url = "https://github.com/jeffvli/feishin/releases/download/v${version}/Feishin-linux-x64.tar.xz";
    hash = "sha256-exKZjBHNSjPWyhfHj8aCrPTmnqHIXolPoW5WeskedsI=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libxkbcommon
    mesa
    nspr
    nss
    pango
    systemd
    xorg.libX11
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXrandr
    xorg.libxcb
    xorg.libxshmfence
    libglvnd
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/feishin $out/bin

    cp -r * $out/share/feishin/

    install -Dm644 resources/assets/icons/icon.png $out/share/pixmaps/feishin.png

    makeWrapper $out/share/feishin/feishin $out/bin/feishin \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ libglvnd ]}" \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
      --unset GTK_MODULES

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "feishin";
      desktopName = "Feishin";
      comment = "A player for your self-hosted music server";
      icon = "feishin";
      exec = "feishin %u";
      categories = [
        "Audio"
        "AudioVideo"
        "Player"
        "Music"
      ];
      startupWMClass = "feishin";
    })
  ];

  meta = with lib; {
    description = "Full-featured Subsonic/Jellyfin compatible desktop music player";
    homepage = "https://github.com/jeffvli/feishin";
    platforms = [ "x86_64-linux" ];
    license = licenses.gpl3Plus;
    mainProgram = "feishin";
    maintainers = with maintainers; [ ];
  };
}
