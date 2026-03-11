{
  lib,
  stdenv,
  fetchurl,
}:

stdenv.mkDerivation rec {
  pname = "neo4j-mcp";
  version = "1.4.5";

  src = fetchurl {
    url = "https://github.com/neo4j/mcp/releases/download/v${version}/neo4j-mcp_Linux_x86_64.tar.gz";
    sha256 = "sha256-l8XZ6S7M9xkGqxnhDsgQksavZExtnZjR8O+qe6LKlMg=";
  };

  # Upstream tarball does not contain a single top-level directory.
  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/libexec/${pname} $out/bin
    cp -r ./* $out/libexec/${pname}/

    binCandidate="$(find "$out/libexec/${pname}" -maxdepth 3 -type f -name "${pname}" | head -n1)"
    if [ -z "$binCandidate" ]; then
      echo "error: ${pname} executable not found in release archive"
      exit 1
    fi

    install -Dm755 "$binCandidate" "$out/bin/${pname}"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Model Context Protocol server for Neo4j";
    homepage = "https://github.com/neo4j/mcp";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    mainProgram = "neo4j-mcp";
    maintainers = with maintainers; [ qrzbing ];
  };
}
