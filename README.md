# Code Composer Studio (CCS) for Nix

A Nix flake for [Code Composer Studio](https://www.ti.com/tool/CCSTUDIO), Texas Instruments' integrated development environment (IDE) for embedded processors and microcontrollers.

## Overview

Code Composer Studio (CCS) is an IDE that comprises a suite of tools used to develop and debug embedded applications. It supports various TI processor families including C2000, MSP430, MSP432, Sitara, and more.

## Prerequisites

- Nix with flakes enabled
- Unfree packages must be allowed (CCS has an unfree license)

## Quick Start

### Run directly

```bash
NIXPKGS_ALLOW_UNFREE=1 nix run github:abeljim/ccs-nix --impure
```

### Build and install

```bash
NIXPKGS_ALLOW_UNFREE=1 nix build --impure
./result/bin/ccstudio
```

### Add to your flake

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ccs-nix.url = "github:abeljim/ccs-nix";
  };

  outputs = { self, nixpkgs, ccs-nix }: {
    # Use the default package with all components
    packages.x86_64-linux.default = ccs-nix.packages.x86_64-linux.default;
  };
}
```

### Use with Home Manager

Add to your Home Manager configuration:

```nix
{ inputs, pkgs, ... }:

{
  # Add ccs-nix as a flake input in your flake.nix first
  # inputs.ccs-nix.url = "github:abeljim/ccs-nix";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Add to home packages
  home.packages = [
    # Option 1: Use default with all components
    inputs.ccs-nix.packages.${pkgs.system}.default

    # Option 2: Use with custom components
    # (inputs.ccs-nix.packages.${pkgs.system}.ccstudio-unwrapped.override {
    #   enabledComponents = [ "PF_C28" "PF_MSP430" ];
    # })
  ];
}
```

Or if you're using standalone Home Manager (not as a NixOS module):

```nix
{ config, pkgs, ... }:

let
  ccs-nix = builtins.fetchGit {
    url = "https://github.com/abeljim/ccs-nix";
    ref = "main";
  };
  ccsPackages = (import ccs-nix).packages.${pkgs.system};
in
{
  nixpkgs.config.allowUnfree = true;

  home.packages = [
    ccsPackages.default
  ];
}
```

## Configuration

### Customizing Installed Components

By default, **all TI components are enabled**. You can customize which components to install by modifying the `defaultEnabledComponents` list in `flake.nix` (lines 29-46) or by using the override mechanism.

#### Available Components

The following components are available (all enabled by default):

| Component | Description |
|-----------|-------------|
| `PF_SITARA_MCU` | Sitara AM2x MCUs |
| `PF_ARM_MPU` | ARM-based MPUs (Sitara AM3x, AM4x, AM5x, AM6x, etc.) |
| `PF_C28` | C2000 real-time MCUs |
| `PF_C6000SC` | C6000 Power-Optimized DSP |
| `PF_HERCULES` | Hercules Safety MCUs |
| `PF_MMWAVE` | mmWave Sensors |
| `PF_MSP430` | MSP430 ultra-low power MCUs |
| `PF_MSPM0` | MSPM0 32-bit Arm Cortex-M0+ MCUs |
| `PF_MSPM33` | MSPM33 MCUs |
| `PF_OMAPL` | OMAP-L1x DSP + ARM9 Processor |
| `PF_PGA` | PGA Sensor Signal Conditioners |
| `PF_MSP432` | SimpleLink MSP432 low power + performance MCUs |
| `PF_AUTO` | Automotive processors |
| `PF_TM4C` | TM4C12x ARM Cortex-M4F core-based MCUs |
| `PF_DIGITAL_POWER` | UCD Digital Power Controllers |
| `PF_WCONN` | Wireless connectivity |

#### Method 1: Direct Modification

Edit the `defaultEnabledComponents` list in `flake.nix`:

```nix
defaultEnabledComponents = [
  "PF_C28"    # Only install C2000 support
  "PF_MSP430" # And MSP430 support
];
```

#### Method 2: Override in Your Flake

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ccs-nix.url = "github:abeljim/ccs-nix";
  };

  outputs = { self, nixpkgs, ccs-nix }:
    let
      system = "x86_64-linux";

      # Create a custom CCS with only specific components
      customCCS = ccs-nix.packages.${system}.ccstudio-unwrapped.override {
        enabledComponents = [ "PF_C28" "PF_MSP430" ];
      };
    in {
      packages.${system}.default = customCCS;
    };
}
```

## Version Information

- **Current Version**: 20.3.1.00005
- **Supported Platforms**: x86_64-linux

## License

Code Composer Studio is proprietary software with an unfree license. This Nix flake is provided as a convenience for packaging CCS, but users must comply with TI's license terms.

## Troubleshooting

### Unfree Package Error

If you encounter an error about unfree packages, you need to allow them:

```bash
# Temporary (for single command)
NIXPKGS_ALLOW_UNFREE=1 nix build --impure

# Or in your NixOS configuration
nixpkgs.config.allowUnfree = true;

# Or in ~/.config/nixpkgs/config.nix
{ allowUnfree = true; }
```

### GPU Issues

The wrapper script includes `--disable-gpu` by default to prevent graphics-related crashes. If you need GPU acceleration, modify the `runScript` in `flake.nix`.

## Development

### Building from Source

```bash
git clone <repository-url>
cd ccs-nix
NIXPKGS_ALLOW_UNFREE=1 nix build --impure
```

### Available Packages

- `packages.x86_64-linux.default` - Full CCS with FHS environment (recommended)
- `packages.x86_64-linux.ccstudio` - Alias for default
- `packages.x86_64-linux.ccstudio-unwrapped` - CCS without FHS wrapper (for advanced use)

## Credits

- Original package maintained by [mymindstorm](https://github.com/mymindstorm)
- Based on the TI Code Composer Studio installer

## See Also

- [Code Composer Studio Documentation](https://www.ti.com/tool/CCSTUDIO)
- [CCS Release Notes](https://software-dl.ti.com/ccs/esd/CCSv20/CCS_20_3_1/exports/CCS_20.3.1_ReleaseNote.htm)
