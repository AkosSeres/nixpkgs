{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  fetchPnpmDeps,
  cargo-tauri,
  desktop-file-utils,
  makeBinaryWrapper,
  nodejs,
  pnpm,
  pnpmConfigHook,
  pkg-config,
  wrapGAppsHook4,
  webkitgtk_4_1,
  openssl,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "terax-ai";
  version = "0.6.1";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "crynta";
    repo = "terax-ai";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Sjwh5XoTK19EcYjkVmOc4rMJdWNJKdQFXGZjLH3MW5A=";
  };

  cargoRoot = "src-tauri";
  buildAndTestSubdir = finalAttrs.cargoRoot;

  cargoHash = "sha256-4yY9JvH7+E9ilMSK88MvfB1mVH90C0WddSIpKfwq5A0=";

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 3;
    hash = "sha256-QHGRc4z2gaB8IEwSvUMuDcrDzKFokB67z0wGf6hTIco=";
  };

  postPatch = ''
    substituteInPlace src-tauri/tauri.conf.json \
      --replace-fail '"createUpdaterArtifacts": true' '"createUpdaterArtifacts": false'
  '';

  nativeBuildInputs = [
    cargo-tauri.hook
    nodejs
    pnpm
    pnpmConfigHook
    pkg-config
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [ makeBinaryWrapper ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    desktop-file-utils
    wrapGAppsHook4
  ];

  buildInputs = [
    openssl
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    webkitgtk_4_1
  ];

  env.OPENSSL_NO_VENDOR = 1;

  preFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
    gappsWrapperArgs+=(--set-default WEBKIT_DISABLE_DMABUF_RENDERER 1)
  '';

  postInstall =
    lib.optionalString stdenv.hostPlatform.isDarwin ''
      makeBinaryWrapper $out/Applications/Terax.app/Contents/MacOS/terax $out/bin/terax
    ''
    + lib.optionalString stdenv.hostPlatform.isLinux ''
      desktop-file-edit \
        --set-key="StartupWMClass" --set-value="Terax" \
        $out/share/applications/Terax.desktop
    '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Open-source AI-native terminal emulator";
    homepage = "https://github.com/crynta/terax-ai";
    changelog = "https://github.com/crynta/terax-ai/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    inherit (cargo-tauri.hook.meta) platforms;
    maintainers = with lib.maintainers; [ akosseres ];
    mainProgram = "terax";
  };
})
