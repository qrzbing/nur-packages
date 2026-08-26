{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  qt5,
  copyDesktopItems,
  makeDesktopItem,
  zlib,
  dbus,
  cups,
  at-spi2-core,
  libkrb5,
  libdrm,
  alsa-lib,
  libpulseaudio,
  systemd,
  libglvnd,
  mesa,
  gtk2,
  gtk3,
  gdk-pixbuf,
  cairo,
  pango,
  nss,
  nspr,
  libX11,
  libXtst,
  libxshmfence,
  libXScrnSaver,
  libXcomposite,
  libXdamage,
  libXext,
  libXfixes,
  libXrandr,
  libxcb,
  mtdev,
  libinput,
  gst_all_1,
  dbus-glib,
  faad2,
  openal,
}:

let
  version = "9.9.0.112609";

  src = fetchurl {
    url = "https://cdn-lxs3.b.qianxin.com/lxpmcpublic/90aabdbb-94c5-4b8a-9368-30315ab86c05.deb";
    hash = "sha256-dRr9IByMCFtbGzKrNB8+7AkJBBByUHPxrnGmriwuTAc=";
  };
in
stdenv.mkDerivation {
  pname = "lanxin";
  inherit version src;

  dontWrapQtApps = true;

  buildInputs = [
    zlib
    dbus
    cups
    at-spi2-core
    libkrb5
    libdrm
    alsa-lib
    libpulseaudio
    systemd
    libglvnd
    mesa
    gtk2
    gtk3
    gdk-pixbuf
    cairo
    pango
    nss
    nspr
    libX11
    libXtst
    libxshmfence
    libXScrnSaver
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    libxcb
    qt5.qtmultimedia
    qt5.qtbase
    qt5.qtwayland
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-bad
    mtdev
    libinput

    dbus-glib
    faad2
    openal
  ];

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];

  unpackPhase = "dpkg-deb -x $src .";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/lanxin
    cp -r opt/apps/cn.lanxin/files/. $out/opt/lanxin/

    # These optional Qt image format plugins require the obsolete, unpatched
    # libtiff.so.5 and libjasper.so.1 shipped by old Ubuntu releases.  The
    # common PNG, JPEG, SVG and WebP plugins remain available.
    rm -f \
      $out/opt/lanxin/bin/plugins/imageformats/libqtiff.so \
      $out/opt/lanxin/bin/plugins/imageformats/libqjp2.so

    # EGLFS, LinuxFB, VNC and WebGL are embedded-device/server backends.  They
    # also mix Lanxin's bundled Qt/libstdc++/libudev with Nixpkgs Qt, which
    # causes symbol-version errors.  Keep the desktop XCB and Wayland backends.
    rm -f \
      $out/opt/lanxin/bin/{,Yealink/ylsdk/bin/}plugins/platforms/{libqeglfs.so,libqlinuxfb.so,libqminimalegl.so,libqvnc.so,libqwebgl.so}

    mkdir -p $out/share/icons/hicolor
    cp -r opt/apps/cn.lanxin/entries/icons/hicolor/. $out/share/icons/hicolor/

    if [ -d "opt/apps/cn.lanxin/entries/icons/scalable" ]; then
      cp -r opt/apps/cn.lanxin/entries/icons/scalable $out/share/icons/hicolor/
    fi

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "cn.lanxin";
      desktopName = "Lanxin";
      exec = "lanxin %U";
      terminal = false;
      icon = "cn.lanxin";
      startupWMClass = "cn.lanxin";
      comment = "Lanxin Instant Messenger";
      mimeTypes = [
        "x-scheme-handler/lanxinplus"
        "x-scheme-handler/cn.lanxin"
      ];
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
    wrapProgram $out/opt/lanxin/bin/lanxin \
      --prefix LD_LIBRARY_PATH : "${
        lib.makeLibraryPath [
          systemd
          libglvnd
          mesa
        ]
      }"

    mkdir -p $out/bin
    ln -s $out/opt/lanxin/bin/lanxin $out/bin/lanxin
  '';

  meta = with lib; {
    description = "Lanxin Instant Messenger";
    homepage = "https://www.lanxin.cn/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "lanxin";
    maintainers = with maintainers; [ qrzbing ];
  };
}
