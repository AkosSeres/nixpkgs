{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  pkg-config,
  cli11,
  hidapi,
  libusb1,
  loguru,
  nlohmann_json,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "alienfx-linux";
  version = "1.2.0";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "tr1xem";
    repo = "alienfx-linux";
    tag = "v${finalAttrs.version}";
    hash = "sha256-L29EGPY8ecgFxjyTi9VAidGfu2jG8V0mkIHRYZ5foAE=";
  };

  patches = [ ./use-system-dependencies.patch ];

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
  ];

  buildInputs = [
    cli11
    hidapi
    libusb1
    loguru
    nlohmann_json
  ];

  cmakeFlags = [
    "-DALIENFX_BUILD_CLI=ON"
    "-DALIENFX_BUILD_EXAMPLE=OFF"
  ];

  # Upstream does not provide an install target.
  installPhase = ''
    runHook preInstall

    install -Dm755 alienfx_cli "$out/bin/alienfx-cli"
    ln -s alienfx-cli "$out/bin/alienfx_cli"

    # On NixOS, enable with services.udev.packages = [ pkgs.alienfx-linux ].
    install -Dm444 ${./70-alienfx-linux.rules} \
      "$out/lib/udev/rules.d/70-alienfx-linux.rules"

    runHook postInstall
  '';

  doInstallCheck = true;

  installCheckPhase = ''
    runHook preInstallCheck

    "$out/bin/alienfx-cli" --help > /dev/null

    runHook postInstallCheck
  '';

  meta = {
    description = "Linux SDK and CLI for controlling Alienware lighting";
    homepage = "https://github.com/tr1xem/alienfx-linux";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ akosseres ];
    mainProgram = "alienfx-cli";
    platforms = lib.platforms.linux;
  };
})
