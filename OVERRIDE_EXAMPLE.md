# Component Configuration

By default, all TI components are enabled. You can customize which components to install using the `override` feature.

## Available Components

Valid component values (according to CCS installer):

- `PF_SITARA_MCU` - Sitara AM2x MCUs
- `PF_ARM_MPU` - ARM-based MPUs (Sitara AM3x, AM4x, AM5x, AM6x, etc.)
- `PF_C28` - C2000 real-time MCUs
- `PF_C6000SC` - C6000 Power-Optimized DSP
- `PF_HERCULES` - Hercules Safety MCUs
- `PF_MMWAVE` - mmWave Sensors
- `PF_MSP430` - MSP430 ultra-low power MCUs
- `PF_MSPM0` - MSPM0 32-bit Arm Cortex-M0+ General Purpose MCUs
- `PF_MSPM33` - MSPM33 MCUs
- `PF_OMAPL` - OMAP-L1x DSP + ARM9 Processor
- `PF_PGA` - PGA Sensor Signal Conditioners
- `PF_MSP432` - SimpleLink MSP432 low power + performance MCUs
- `PF_AUTO` - Automotive processors
- `PF_TM4C` - TM4C12x ARM Cortex-M4F core-based MCUs
- `PF_DIGITAL_POWER` - UCD Digital Power Controllers
- `PF_WCONN` - Wireless connectivity

## Usage Examples

### Method 1: Using in your own flake

```nix
{
  inputs = {
    ccs-nix.url = "github:yourusername/ccs-nix";
    nixpkgs.follows = "ccs-nix/nixpkgs";
  };

  outputs = { self, nixpkgs, ccs-nix }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      # Example 1: Only install C2000 support
      packages.${system}.ccs-c28-only = pkgs.buildFHSEnv {
        name = "ccstudio";
        targetPkgs = pkgs: [
          (ccs-nix.packages.${system}.ccstudio-unwrapped.override {
            enabledComponents = [ "PF_C28" ];
          })
          # ... other dependencies ...
        ];
        runScript = "${ccs-nix.packages.${system}.ccstudio-unwrapped.override {
          enabledComponents = [ "PF_C28" ];
        }}/opt/ccs/theia/ccstudio";
      };

      # Example 2: MSP430 and C2000 support only
      packages.${system}.ccs-embedded = pkgs.buildFHSEnv {
        name = "ccstudio";
        targetPkgs = pkgs: [
          (ccs-nix.packages.${system}.ccstudio-unwrapped.override {
            enabledComponents = [ "PF_MSP430" "PF_C28" ];
          })
          # ... other dependencies ...
        ];
        runScript = "${ccs-nix.packages.${system}.ccstudio-unwrapped.override {
          enabledComponents = [ "PF_MSP430" "PF_C28" ];
        }}/opt/ccs/theia/ccstudio";
      };
    };
}
```

### Method 2: Modifying flake.nix directly

Edit the `defaultEnabledComponents` list in `flake.nix` (lines 25-46) to change the default components for all builds.

### Method 3: Simple override in shell

```bash
# Override just the unwrapped package
nix build .#ccstudio-unwrapped --override-input enabledComponents '[ "PF_C28" ]'
```
