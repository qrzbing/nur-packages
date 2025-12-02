{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  qt5, # wrapQtAppsHook
  copyDesktopItems, # Install desktopItems
  makeDesktopItem, # Genirate .desktop file
  glibc,
  zlib,
  dbus,
  cups,
  at-spi2-atk,
  at-spi2-core,
  libkrb5,
  libtiff,
  libdrm,
  alsa-lib,
  libpulseaudio,
  systemd,
  libglvnd,
  mesa,
  vulkan-loader,
  gtk2,
  gtk3,
  gdk-pixbuf,
  cairo,
  pango,
  nss,
  nspr,
  xorg,
  mtdev,
  libinput,
}:

let
  version = "9.1.1.110191_10191";
  src = fetchurl {
    url = "https://package.lanxin.cn/client/linux/lanxin-x64_Official_${version}.deb";
    sha256 = "sha256-ny2sfeo3/l4178vkfIYW75GOcaOhhhjnuRhCsiAURMA=";
  };

  # For old libs
  libtiff5-deb = stdenv.mkDerivation {
    pname = "libtiff5-prebuilt";
    version = "4.1.0";
    src = fetchurl {
      url = "http://archive.ubuntu.com/ubuntu/pool/main/t/tiff/libtiff5_4.1.0+git191117-2ubuntu0.20.04.14_amd64.deb";
      sha256 = "sha256-sgQnJ61FRpugE601N7gIw7C6G26QhO3FrHmMXxKNcsA=";
    };
    nativeBuildInputs = [ dpkg ];
    unpackPhase = "dpkg-deb -x $src .";
    installPhase = ''
      mkdir -p $out/lib
      cp usr/lib/x86_64-linux-gnu/libtiff.so.5* $out/lib/
    '';
  };
  libjasper-deb = stdenv.mkDerivation {
    pname = "libjasper1-prebuilt";
    version = "1.900.1";
    src = fetchurl {
      url = "http://archive.ubuntu.com/ubuntu/pool/main/j/jasper/libjasper1_1.900.1-debian1-2.4ubuntu1.3_amd64.deb";
      sha256 = "sha256-/0xX/chkEXm/Jc/ILCN71T9aMOpB7TekOVlNPqNVLXg=";
    };
    nativeBuildInputs = [ dpkg ];
    unpackPhase = "dpkg-deb -x $src .";
    installPhase = ''
      mkdir -p $out/lib
      cp usr/lib/x86_64-linux-gnu/libjasper.so.1* $out/lib/
    '';
  };
in
stdenv.mkDerivation {
  pname = "lanxin";
  inherit version src;

  buildInputs = [
    glibc
    zlib
    dbus
    cups
    at-spi2-atk
    at-spi2-core
    libkrb5
    libtiff
    libdrm
    alsa-lib
    libpulseaudio
    systemd
    libglvnd
    mesa
    vulkan-loader
    gtk2
    gtk3
    gdk-pixbuf
    cairo
    pango
    nss
    nspr
    xorg.libX11
    xorg.libXtst
    xorg.libxshmfence
    xorg.libXScrnSaver
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libxkbfile
    xorg.libxcb
    xorg.xcbutil
    xorg.xcbutilwm
    xorg.xcbutilimage
    xorg.xcbutilkeysyms
    xorg.xcbutilrenderutil
    qt5.qtbase
    qt5.qtdeclarative
    qt5.qtwayland
    qt5.qtwebsockets

    libtiff5-deb
    libjasper-deb

    mtdev
    libinput
  ];

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    qt5.wrapQtAppsHook
    copyDesktopItems # process desktopItems list
  ];

  unpackPhase = "dpkg-deb -x $src .";

  installPhase = ''
    mkdir -p $out/opt/lanxin
    cp -r opt/apps/cn.lanxin/files/* $out/opt/lanxin/

    mkdir -p $out/share/icons/hicolor
    cp -r opt/apps/cn.lanxin/entries/icons/hicolor/* $out/share/icons/hicolor/

    # Rename icon from cn.lanxin.png to lanxin.png to match Icon=lanxin
    for theme in $out/share/icons/hicolor/*; do
      if [ -f "$theme/apps/cn.lanxin.png" ]; then
        mv "$theme/apps/cn.lanxin.png" "$theme/apps/lanxin.png"
      fi
    done

    if [ -d "opt/apps/cn.lanxin/entries/icons/scalable" ]; then
       mkdir -p $out/share/icons/hicolor/scalable/apps
       cp opt/apps/cn.lanxin/entries/icons/scalable/apps/* $out/share/icons/hicolor/scalable/apps/ 2>/dev/null || true
       if [ -f "$out/share/icons/hicolor/scalable/apps/cn.lanxin.svg" ]; then
          mv "$out/share/icons/hicolor/scalable/apps/cn.lanxin.svg" "$out/share/icons/hicolor/scalable/apps/lanxin.svg"
       fi
       if [ -f "$out/share/icons/hicolor/scalable/apps/cn.lanxin1.svg" ]; then
          mv "$out/share/icons/hicolor/scalable/apps/cn.lanxin1.svg" "$out/share/icons/hicolor/scalable/apps/lanxin1.svg"
       fi
    fi

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "lanxin";
      desktopName = "Lanxin";
      exec = "lanxin %U";
      terminal = false;
      icon = "lanxin";
      startupWMClass = "lanxin";
      comment = "Lanxin Instant Messenger";
      categories = [
        "Network"
        "InstantMessaging"
        "Chat"
      ];
      extraConfig = {
        "Name[zh_CN]" = "蓝信";
        "Comment[zh_CN]" = "蓝信-安全数智化工作平台";
      };
    })
  ];

  postFixup = ''
    echo "Fixing libbase.so interpreter..."
    find $out -name "libbase.so" -exec patchelf --remove-interpreter {} \;

    wrapProgram $out/opt/lanxin/bin/lanxin \
      --prefix LD_LIBRARY_PATH : "${
        lib.makeLibraryPath [
          systemd
          libglvnd
          mesa
        ]
      }" \
      --set XDG_SESSION_TYPE x11 \
      --set QT_QPA_PLATFORM xcb \
      --add-flags "--no-sandbox"

    mkdir -p $out/bin
    ln -s $out/opt/lanxin/bin/lanxin $out/bin/lanxin
  '';

  meta = with lib; {
    description = "Lanxin Instant Messenger";
    homepage = "https://www.lanxin.cn/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "lanxin";
  };
}
