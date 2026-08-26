{
  fetchurl,
  hyprcursor,
  lib,
  stdenvNoCC,
  unzip,
  win2xcur,
  writeText,
  xcur2png,
}:

let
  themeSpecs = [
    {
      name = "STMC-Standard";
      displayName = "Sam Toki Standard Cursors";
      description = "Sam Toki's standard cursor theme";
      infPattern = "*1-1 Standard.inf";
    }
    {
      name = "STMC-Standard-White";
      displayName = "Sam Toki Standard White Cursors";
      description = "Sam Toki's white standard cursor theme";
      infPattern = "*1-2 Standard (White).inf";
    }
    {
      name = "STMC-Standard-Classic";
      displayName = "Sam Toki Standard Classic Cursors";
      description = "Sam Toki's classic standard cursor theme";
      infPattern = "*1-3 Standard (Classic).inf";
    }
    {
      name = "STMC-Standard-Left-Handed";
      displayName = "Sam Toki Standard Left-Handed Cursors";
      description = "Sam Toki's left-handed standard cursor theme";
      infPattern = "*1-7 Standard (Left Handed).inf";
    }
    {
      name = "STMC-45-Degree";
      displayName = "Sam Toki 45-Degree Cursors";
      description = "Sam Toki's 45-degree cursor theme";
      infPattern = "*2-1 45-Degree.inf";
    }
    {
      name = "STMC-45-Degree-White";
      displayName = "Sam Toki 45-Degree White Cursors";
      description = "Sam Toki's white 45-degree cursor theme";
      infPattern = "*2-2 45-Degree (White).inf";
    }
    {
      name = "STMC-45-Degree-Left-Handed";
      displayName = "Sam Toki 45-Degree Left-Handed Cursors";
      description = "Sam Toki's left-handed 45-degree cursor theme";
      infPattern = "*2-7 45-Degree (Left Handed).inf";
    }
    {
      name = "STMC-Genshin";
      displayName = "Sam Toki Genshin Cursors";
      description = "Sam Toki's Genshin cursor theme";
      infPattern = "*3-1 Genshin.inf";
    }
    {
      name = "STMC-Genshin-Elements";
      displayName = "Sam Toki Genshin Elements Cursors";
      description = "Sam Toki's Genshin Elements cursor theme";
      infPattern = "*3-2 Genshin (Elements).inf";
    }
    {
      name = "STMC-Genshin-Left-Handed";
      displayName = "Sam Toki Genshin Left-Handed Cursors";
      description = "Sam Toki's left-handed Genshin cursor theme";
      infPattern = "*3-7 Genshin (Left Handed).inf";
    }
    {
      name = "STMC-Genshin-Nahida";
      displayName = "Sam Toki Genshin Nahida Cursors";
      description = "Sam Toki's Genshin Nahida cursor theme";
      infPattern = "*4-1 Genshin Nahida.inf";
    }
    {
      name = "STMC-Genshin-Nahida-Left-Handed";
      displayName = "Sam Toki Genshin Nahida Left-Handed Cursors";
      description = "Sam Toki's left-handed Genshin Nahida cursor theme";
      infPattern = "*4-7 Genshin Nahida (Left Handed).inf";
    }
    {
      name = "STMC-BTR-Ahoge";
      displayName = "Sam Toki BTR Ahoge Cursors";
      description = "Sam Toki's Bocchi the Rock Ahoge cursor theme";
      infPattern = "*5-1 BTR Ahoge.inf";
    }
    {
      name = "STMC-BTR-Ahoge-Nijika";
      displayName = "Sam Toki BTR Ahoge Nijika Cursors";
      description = "Sam Toki's Bocchi the Rock Nijika Ahoge cursor theme";
      infPattern = "*5-2 BTR Ahoge (Nijika).inf";
    }
    {
      name = "STMC-BTR-Ahoge-Mix";
      displayName = "Sam Toki BTR Ahoge Mix Cursors";
      description = "Sam Toki's Bocchi the Rock mixed Ahoge cursor theme";
      infPattern = "*5-3 BTR Ahoge (Mix).inf";
    }
    {
      name = "STMC-BTR-Ahoge-Left-Handed";
      displayName = "Sam Toki BTR Ahoge Left-Handed Cursors";
      description = "Sam Toki's left-handed Bocchi the Rock Ahoge cursor theme";
      infPattern = "*5-7 BTR Ahoge (Left Handed).inf";
    }
    {
      name = "STMC-Genshin-Furina";
      displayName = "Sam Toki Genshin Furina Cursors";
      description = "Sam Toki's Genshin Furina cursor theme";
      infPattern = "*6-1 Genshin Furina.inf";
    }
    {
      name = "STMC-Genshin-Furina-Left-Handed";
      displayName = "Sam Toki Genshin Furina Left-Handed Cursors";
      description = "Sam Toki's left-handed Genshin Furina cursor theme";
      infPattern = "*6-7 Genshin Furina (Left Handed).inf";
    }
    {
      name = "STMC-Silent-Witch";
      displayName = "Sam Toki Silent Witch Cursors";
      description = "Sam Toki's Silent Witch cursor theme";
      infPattern = "*7-1 Silent Witch.inf";
    }
    {
      name = "STMC-Silent-Witch-Alt";
      displayName = "Sam Toki Silent Witch Alt Cursors";
      description = "Sam Toki's alternate Silent Witch cursor theme";
      infPattern = "*7-2 Silent Witch (Alt).inf";
    }
    {
      name = "STMC-Silent-Witch-Left-Handed";
      displayName = "Sam Toki Silent Witch Left-Handed Cursors";
      description = "Sam Toki's left-handed Silent Witch cursor theme";
      infPattern = "*7-7 Silent Witch (Left Handed).inf";
    }
  ];

  themeNames = map (theme: theme.name) themeSpecs;

  buildTheme =
    theme:
    let
      indexTheme = writeText "${theme.name}-index.theme" ''
        [Icon Theme]
        Name=${theme.displayName}
        Comment=${theme.description} converted to XCursor
        Inherits=Adwaita
      '';
    in
    ''
      themeDir="$out/share/icons/${theme.name}"
      cursorDir="$themeDir/cursors"
      mkdir -p "$cursorDir"

      infFile="$(find "$unpackDir/STMC" -type f -name ${lib.escapeShellArg theme.infPattern} -print -quit)"
      if [[ -z "$infFile" ]]; then
        echo ${lib.escapeShellArg "${theme.displayName} INF was not found in the release archive"} >&2
        exit 1
      fi

      # The default I-beam is nearly invisible over dark Wayland clients.
      # Upstream includes a matching high-contrast white variant, so use it
      # for the text/xterm shapes in both generated cursor formats.
      if grep -qF 'STMC Common 06 Beam.cur' "$infFile"; then
        substituteInPlace "$infFile" \
          --replace-fail 'STMC Common 06 Beam.cur' 'STMC Common 06 Beam (White).cur'
      fi

      win2xcurtheme "$infFile" -o "$cursorDir"
      install -Dm444 ${indexTheme} "$themeDir/index.theme"

      # Keep XCursor data for GTK, Qt and XWayland, and compile the same
      # artwork into native Hyprcursor data for the compositor.
      hyprWorkDir="$TMPDIR/hyprcursor-work-${theme.name}"
      hyprOutputDir="$TMPDIR/hyprcursor-output-${theme.name}"
      mkdir -p "$hyprWorkDir" "$hyprOutputDir"

      hyprcursor-util \
        --extract "$themeDir" \
        --output "$hyprWorkDir" \
        --resize bilinear

      extractedDir="$hyprWorkDir/extracted_${theme.name}"
      substituteInPlace "$extractedDir/manifest.hl" \
        --replace-fail 'name = Extracted Theme' 'name = ${theme.name}' \
        --replace-fail 'description = Automatically extracted with hyprcursor-util' \
          ${lib.escapeShellArg "description = ${theme.description}"}

      hyprcursor-util \
        --create "$extractedDir" \
        --output "$hyprOutputDir"

      compiledDir="$hyprOutputDir/theme_${theme.name}"
      test -f "$cursorDir/default"
      test -f "$cursorDir/text"
      test -f "$compiledDir/manifest.hl"
      test -f "$compiledDir/hyprcursors/default.hlc"
      test -f "$compiledDir/hyprcursors/text.hlc"
      cp -r "$compiledDir/." "$themeDir/"
    '';
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "sam-toki-mouse-cursors";
  version = "10.00";

  src = fetchurl {
    url = "https://github.com/SamToki/Sam-Toki-Mouse-Cursors/releases/download/v${finalAttrs.version}/STMC.zip";
    hash = "sha256-9pKe2/LpBTO2HrWXm/QfdKfeCnwMyplfutRMB/0TRnw=";
  };

  dontUnpack = true;
  strictDeps = true;
  nativeBuildInputs = [
    hyprcursor
    unzip
    win2xcur
    xcur2png
  ];

  installPhase = ''
    runHook preInstall

    unpackDir="$TMPDIR/sam-toki-mouse-cursors"
    mkdir -p "$unpackDir"
    unzip -q "$src" -d "$unpackDir"

    ${lib.concatMapStringsSep "\n" buildTheme themeSpecs}

    runHook postInstall
  '';

  passthru = {
    inherit themeNames;
  };

  meta = {
    description = "Sam Toki's mouse cursor themes for XCursor and Hyprcursor";
    homepage = "https://github.com/SamToki/Sam-Toki-Mouse-Cursors";
    changelog = "https://github.com/SamToki/Sam-Toki-Mouse-Cursors/releases/tag/v${finalAttrs.version}";
    license = lib.licenses."cc-by-nc-sa-30";
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ qrzbing ];
  };
})
