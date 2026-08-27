{
  lib,
  stdenv,
  fetchFromGitHub,

  # nativeBuildInputs
  copyDesktopItems,
  gradle_9,
  jdk25,

  # installCheckInputs
  gtk3,

  # helpers
  makeDesktopItem,
  testers,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "audiveris";
  version = "5.11.0";

  src = fetchFromGitHub {
    owner = "Audiveris";
    repo = "audiveris";
    tag = finalAttrs.version;
    hash = "sha256-mqHzhEeAb6f/NDGLtXGtJP3d6ddY+THvCIQAvA5eUOQ=";
  };

  nativeBuildInputs = [
    copyDesktopItems
    gradle_9
    jdk25
  ];

  strictDeps = true;
  dontStrip = true;

  postPatch = ''
    # Only configure the application project. The documentation, installers,
    # schemas and Flatpak generator are unrelated to the Nix package and pull
    # in a large second set of build-only dependencies.
    substituteInPlace settings.gradle \
      --replace-fail "include 'flatpak'" "// Flatpak project disabled for the Nix build" \
      --replace-fail "if (startParameter.projectProperties['isFlatpak'] == 'true') {" "if (true) {"

    # GitHub source archives do not contain .git. Preserve the exact release
    # commit in ProgramId instead of allowing the build to invoke git.
    substituteInPlace app/build.gradle \
      --replace-fail \
        "commandLine = \"git log -n1 --pretty=%H -- :^../flatpak/flathub\".split(' ')" \
        "commandLine = [\"echo\", \"9e1e55cd2746037d059345881c53e6a6754bffbd\"]"
  '';

  mitmCache = gradle_9.fetchDeps {
    pkg = finalAttrs.finalPackage;
    data = ./deps.json;
  };

  __darwinAllowLocalNetworking = true;
  enableParallelBuilding = false;
  enableParallelChecking = false;
  enableParallelUpdating = false;

  gradleFlags = [
    "--max-workers=1"
    "-Dfile.encoding=utf-8"
    "-Dorg.gradle.java.home=${jdk25}"
  ];
  gradleBuildTask = ":app:distTar";

  # Some classifier tests fan out across every CPU for several minutes. They
  # are unsuitable for a routine package build; the install check and the
  # end-to-end OMR test exercise the packaged application instead.
  doCheck = false;

  desktopItems = [
    (makeDesktopItem {
      name = "org.audiveris.audiveris";
      desktopName = "Audiveris";
      genericName = "Optical Music Recognition (OMR)";
      comment = "Convert sheet music to MusicXML";
      exec = "audiveris %F";
      icon = "org.audiveris.audiveris";
      terminal = false;
      categories = [
        "AudioVideo"
        "Graphics"
        "Music"
        "Scanning"
      ];
      keywords = [
        "OMR"
        "MusicXML"
        "sheet music"
      ];
      extraConfig = {
        "Name[zh_CN]" = "Audiveris 乐谱识别";
        "GenericName[zh_CN]" = "光学乐谱识别（OMR）";
        "Comment[zh_CN]" = "将扫描乐谱转换为 MusicXML";
      };
    })
  ];

  installPhase = ''
    runHook preInstall

    install -d "$out/share/audiveris"
    tar -xf "app/build/distributions/app-${finalAttrs.version}.tar" \
      --strip-components=1 \
      -C "$out/share/audiveris"
    rm -f "$out/share/audiveris/lib/"*-linux-arm64.jar
    patchShebangs --host "$out/share/audiveris/bin/Audiveris"

    install -d "$out/bin"
    ln -s ../share/audiveris/bin/Audiveris "$out/bin/audiveris"
    ln -s audiveris "$out/bin/Audiveris"

    install -Dm644 app/res/icon-256.png \
      "$out/share/icons/hicolor/256x256/apps/org.audiveris.audiveris.png"
    install -Dm644 app/res/icon-64.png \
      "$out/share/icons/hicolor/64x64/apps/org.audiveris.audiveris.png"
    for size in 16 24 32 48; do
      install -Dm644 \
        "app/src/main/java/org/audiveris/omr/ui/resources/icon-$size.png" \
        "$out/share/icons/hicolor/''${size}x''${size}/apps/org.audiveris.audiveris.png"
    done

    install -Dm644 flatpak/res/org.audiveris.audiveris.metainfo.xml \
      "$out/share/metainfo/org.audiveris.audiveris.metainfo.xml"

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    export XDG_CONFIG_HOME="$TMPDIR/config"
    export XDG_DATA_HOME="$TMPDIR/data"
    export XDG_CACHE_HOME="$TMPDIR/cache"
    LD_LIBRARY_PATH=${
      lib.makeLibraryPath [
        gtk3
        stdenv.cc.cc.lib
      ]
    } \
      JAVA_HOME=${jdk25} \
      "$out/bin/audiveris" -version | tee version.txt
    grep -F '${finalAttrs.version}' version.txt

    runHook postInstallCheck
  '';

  passthru.tests.version = testers.testVersion {
    package = finalAttrs.finalPackage;
    command = "LD_LIBRARY_PATH=${
      lib.makeLibraryPath [
        gtk3
        stdenv.cc.cc.lib
      ]
    } JAVA_HOME=${jdk25} XDG_CONFIG_HOME=$TMPDIR/config audiveris -version";
    version = finalAttrs.version;
  };

  meta = {
    description = "Open-source optical music recognition application";
    homepage = "https://audiveris.github.io/audiveris/";
    changelog = "https://github.com/Audiveris/audiveris/releases/tag/${finalAttrs.version}";
    license = with lib.licenses; [
      agpl3Plus
      # javax.media:jai-core is distributed under Sun's Binary Code License.
      unfreeRedistributable
    ];
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryBytecode # Maven dependencies
      binaryNativeCode # JavaCPP Tesseract and Leptonica classifiers
    ];
    maintainers = with lib.maintainers; [ qrzbing ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "audiveris";
  };
})
