{
  description = "Code Composer Studio integrated development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/c5dd43934613ae0f8ff37c59f61c507c2e8f980d";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachSystem ["x86_64-linux"] (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      majorVersion = "20";
      minorVersion = "3";
      patchVersion = "1";
      otherVersion = "00005";
      versionNumberDots = "${majorVersion}.${minorVersion}.${patchVersion}";
      versionNumberUnderscores = "${majorVersion}_${minorVersion}_${patchVersion}";

      # Default enabled components - all available options
      # Valid values according to CCS installer:
      # PF_SITARA_MCU PF_ARM_MPU PF_C28 PF_C6000SC PF_HERCULES PF_MMWAVE
      # PF_MSP430 PF_MSPM0 PF_MSPM33 PF_OMAPL PF_PGA PF_MSP432
      # PF_AUTO PF_TM4C PF_DIGITAL_POWER PF_WCONN
      defaultEnabledComponents = [
        "PF_SITARA_MCU"    # Sitara AM2x MCUs
        "PF_ARM_MPU"       # ARM-based MPUs (Sitara AM3x, AM4x, AM5x, AM6x, etc.)
        "PF_C28"           # C2000 real-time MCUs
        "PF_C6000SC"       # C6000 Power-Optimized DSP
        "PF_HERCULES"      # Hercules Safety MCUs
        "PF_MMWAVE"        # mmWave Sensors
        "PF_MSP430"        # MSP430 ultra-low power MCUs
        "PF_MSPM0"         # MSPM0 32-bit Arm Cortex-M0+ General Purpose MCUs
        "PF_MSPM33"        # MSPM33 MCUs
        "PF_OMAPL"         # OMAP-L1x DSP + ARM9 Processor
        "PF_PGA"           # PGA Sensor Signal Conditioners
        "PF_MSP432"        # SimpleLink MSP432 low power + performance MCUs
        "PF_AUTO"          # Automotive processors
        "PF_TM4C"          # TM4C12x ARM Cortex-M4F core-based MCUs
        "PF_DIGITAL_POWER" # UCD Digital Power Controllers
        "PF_WCONN"         # Wireless connectivity
      ];

      # Override enabledComponents to customize which TI components are installed
      # Example: ccstudio-unwrapped.override { enabledComponents = [ "PF_C28" "PF_MSP430" ]; }
      ccstudio-unwrapped = pkgs.callPackage ({
        stdenv,
        lib,
        enabledComponents ? defaultEnabledComponents,
      }: stdenv.mkDerivation rec {
        pname = "ccstudio";
        version = "${versionNumberDots}.${otherVersion}";

        meta = {
          description = "Code Composer Studio integrated development environment";
          longDescription = ''
            Code Composer Studio is an integrated development environment (IDE) for TI's microcontrollers and processors.
            It is comprised of a rich suite of tools used to build, debug, analyze and optimize embedded applications.
          '';
          homepage = "https://www.ti.com/tool/CCSTUDIO";
          downloadPage = "https://www.ti.com/tool/download/CCSTUDIO";
          changelog = "https://software-dl.ti.com/ccs/esd/CCSv${majorVersion}/CCS_${versionNumberUnderscores}/exports/CCS_${versionNumberDots}_ReleaseNote.htm";
          license = pkgs.lib.licenses.unfree;
          sourceProvenance = with pkgs.lib.sourceTypes; [binaryNativeCode];
          maintainers = with pkgs.lib.maintainers; [mymindstorm];
          mainProgram = "ccstudio";
          platforms = ["x86_64-linux"];
        };

        src = pkgs.fetchzip {
          url = "https://dr-download.ti.com/software-development/ide-configuration-compiler-or-debugger/MD-J1VdearkvK/20.3.1/CCS_20.3.1.00005_linux.zip";
          hash = "sha256-Cp7WtweQcyxfRUe+84h8X3nRHVZnyWLkajxHmMg5CJ8=";
        };

        desktopItem = pkgs.makeDesktopItem {
          name = "ccstudio";
          desktopName = "Code Composer Studio";
          exec = "ccstudio";
          icon = "ccs";
          comment = "IDE for TI's microcontrollers and processors";
          categories = ["Development"];
        };

        dontConfigure = true;
        dontBuild = true;

        # Disable hardening to prevent SIGTRAP crashes
        hardeningDisable = ["all"];

        nativeBuildInputs = with pkgs; [
          autoPatchelfHook
          fakeroot
          pkg-config
        ];

        buildInputs = with pkgs; [
          alsa-lib
          at-spi2-atk
          atkmm
          cairo
          cups
          dbus
          expat
          freetype
          gdk-pixbuf
          glib
          gtk3
          icu
          jdk
          libdrm
          libsecret
          libudev0-shim
          libusb-compat-0_1
          libusb1
          libxkbcommon
          mesa
          musl
          nspr
          nss
          openssl
          pango
          python39
          stdenv.cc.cc.lib
          stdenv.cc.libc
          systemd
          udev
          xorg.libX11
          xorg.libXScrnSaver
          xorg.libXcomposite
          xorg.libXcursor
          xorg.libXdamage
          xorg.libXext
          xorg.libXfixes
          xorg.libXi
          xorg.libXrandr
          xorg.libXrender
          xorg.libXtst
          xorg.libxcb
          xorg.libxkbfile
          zlib
        ];

        installPhase = let
          installerFHS = pkgs.buildFHSEnv {
            name = "ccstudio";
            targetPkgs = pkgs: [pkgs.fakeroot] ++ buildInputs;
            extraBwrapArgs = [
              "--bind $out/etc/udev/rules.d /etc/udev/rules.d"
            ];
          };
          installer = "./ccs_setup_${version}.run";
        in ''
          runHook preInstall
          # blackhawk strikes again. the build fails if it can't restart udev via `service`
          mkdir -p /build/fake-bin
          echo "#! /usr/bin/env bash" > /build/fake-bin/service
          echo "true" >> /build/fake-bin/service
          chmod 775 /build/fake-bin/service
          mkdir -p "$out/etc/udev/rules.d" # blackhawk compat
          patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
            ${installer}
          # fakeroot necessary because blackhawk refuses to install without it.
          ${installerFHS}/bin/ccstudio -c "export PATH=$PATH:/build/fake-bin && fakeroot ${installer} --mode unattended --prefix /build/ti --enable-components ${lib.concatStringsSep "," enabledComponents}"
          mkdir -p $out/share/applications
          cp ${desktopItem}/share/applications/* $out/share/applications
          mkdir -p "$out/opt"
          mv /build/ti/ccs $out/opt/
          rm -rf $out/opt/ccs/install_logs
          mkdir -p $out/share/icons/hicolor/256x256/apps
          ln -s $out/opt/ccs/doc/ccs.ico $out/share/icons/hicolor/256x256/apps/ccs.ico
          runHook postInstall
        '';
      }) {};
    in {
      packages.default = (pkgs.buildFHSEnv {
        name = "ccstudio";
        targetPkgs = pkgs:
          with pkgs; [
            ccstudio-unwrapped
            alsa-lib
            at-spi2-atk
            atkmm
            cairo
            cups
            dbus
            expat
            freetype
            gdk-pixbuf
            glib
            gtk3
            icu
            jdk
            libdrm
            libGL
            libGLU
            libsecret
            libudev0-shim
            libusb-compat-0_1
            libusb1
            libxkbcommon
            mesa
            musl
            nspr
            nss
            openssl
            pango
            python39
            stdenv.cc.cc.lib
            systemd
            udev
            xdg-desktop-portal
            xdg-desktop-portal-gtk
            xorg.libX11
            xorg.libXScrnSaver
            xorg.libXcomposite
            xorg.libXcursor
            xorg.libXdamage
            xorg.libXext
            xorg.libXfixes
            xorg.libXi
            xorg.libXrandr
            xorg.libXrender
            xorg.libXtst
            xorg.libxcb
            xorg.libxkbfile
            zlib
          ];

        runScript = pkgs.writeShellScript "ccstudio-wrapper" ''
          exec ${ccstudio-unwrapped}/opt/ccs/theia/ccstudio --disable-gpu "$@"
        '';

        meta = {
          description = "Code Composer Studio integrated development environment";
          homepage = "https://www.ti.com/tool/CCSTUDIO";
          license = pkgs.lib.licenses.unfree;
          mainProgram = "ccstudio";
          platforms = ["x86_64-linux"];
        };
      }).overrideAttrs (oldAttrs: {
        # Add desktop file and icon from unwrapped package
        postBuild = ''
          mkdir -p $out/share/applications
          mkdir -p $out/share/icons/hicolor/256x256/apps
          cp -r ${ccstudio-unwrapped}/share/applications/* $out/share/applications/
          cp -r ${ccstudio-unwrapped}/share/icons/hicolor/256x256/apps/* $out/share/icons/hicolor/256x256/apps/
        '';
      });

      packages.ccstudio = self.packages.${system}.default;
      packages.ccstudio-unwrapped = ccstudio-unwrapped;

      apps.default = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/ccstudio";
      };
    });
}
