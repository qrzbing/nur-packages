{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
  zlib,
  fontconfig,
  glib,
  nss,
  nspr,
  at-spi2-core,
  expat,
  libkrb5,
  libdrm,
  libxkbcommon,
  udev,
  dbus,
  cups,
  alsa-lib,
  mesa,
  libX11,
  libXcomposite,
  libXdamage,
  libXext,
  libXfixes,
  libXrandr,
  libxcb,
  icu,
}:

let
  version = "2.9.1.2";

  src = fetchurl {
    url = "https://sp.thsi.cn/staticS3/mobileweb-upload-static-server.file/app_6/downloadcenter/cn.com.10jqka_kylin_${version}_amd64.deb";
    hash = "sha256-1ktOT0xdv8UQGEt6Ei1W6titpE8iMd1QZnoVZH6ljmQ=";
  };

  opensslCompatSrc = fetchurl {
    url = "https://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.24_amd64.deb";
    hash = "sha256-fPOdcKY5AX0d18jTbaoiWAY2CGiORJ/d9A/91G+ZKng=";
  };
in
stdenv.mkDerivation {
  pname = "tonghuashun";
  inherit version src;

  buildInputs = [
    zlib
    fontconfig
    glib
    nss
    nspr
    at-spi2-core
    expat
    libkrb5
    libdrm
    libxkbcommon
    udev
    dbus
    cups
    alsa-lib
    mesa
    libX11
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    libxcb
  ];

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];

  autoPatchelfIgnoreMissingDeps = [ "liblttng-ust.so.0" ];

  unpackPhase = "dpkg-deb -x $src .";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/tonghuashun
    cp -r opt/apps/cn.com.10jqka/files/. $out/opt/tonghuashun/

    dpkg-deb -x ${opensslCompatSrc} openssl-compat
    mkdir -p $out/opt/tonghuashun/lib
    cp openssl-compat/usr/lib/x86_64-linux-gnu/lib{crypto,ssl}.so.1.1 \
      $out/opt/tonghuashun/lib/

    sed -i '/\.a"/,+2 d' $out/opt/tonghuashun/HevoNext.B2CApp.deps.json

    install -Dm644 \
      opt/apps/cn.com.10jqka/entries/icons/hicolor/scalable/apps/HevoIcon.svg \
      $out/share/icons/hicolor/scalable/apps/cn.com.10jqka.svg

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "cn.com.10jqka";
      desktopName = "同花顺炒股软件";
      exec = "tonghuashun %U";
      terminal = false;
      icon = "cn.com.10jqka";
      startupWMClass = "HevoNext.B2CApp";
      comment = "提供全面的行情信息";
      categories = [ "Office" ];
    })
  ];

  postFixup = ''
    wrapProgram $out/opt/tonghuashun/HevoNext.B2CApp \
      --prefix LD_LIBRARY_PATH : "$out/opt/tonghuashun/lib:${
        lib.makeLibraryPath [
          zlib
          fontconfig
          glib
          nss
          nspr
          at-spi2-core
          expat
          libkrb5
          libdrm
          libxkbcommon
          udev
          dbus
          cups
          alsa-lib
          icu
          mesa
          libX11
          libXcomposite
          libXdamage
          libXext
          libXfixes
          libXrandr
          libxcb
        ]
      }"

    mkdir -p $out/bin
    ln -s $out/opt/tonghuashun/HevoNext.B2CApp $out/bin/tonghuashun
  '';

  meta = with lib; {
    description = "Tonghuashun stock market client";
    homepage = "https://www.10jqka.com.cn/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "tonghuashun";
    maintainers = with maintainers; [ qrzbing ];
  };
}
