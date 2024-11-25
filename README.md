# Whisper.cpp prebuilt binaries
Whisper.cpp prebuilt binaries for static and dynamic linking

## Building on Windows

You will need MSVS 2022 installed.

Set up environment variables, e.g.:

```powershell
> $env:BUILD_WITH_ACCEL="cuda"
> $env:CUDA_TOOLKIT_ROOT_DIR="C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.5"
```

Acceleration options: `cpu`, `cuda`, `vulkan`, `mkl` and `hipblas`

For `hipblas` make sure `$env:HIP_PATH` points to the HIP installation folder, e.g. where `$env:HIP_PATH\bin\clang.exe` would be located.

The HIP installer can be downloaded from https://download.amd.com/developer/eula/rocm-hub/AMD-Software-PRO-Edition-24.Q3-Win10-Win11-For-HIP.exe.

The Vulkan installer can be found in https://sdk.lunarg.com/sdk/download/1.3.296.0/windows/VulkanSDK-1.3.296.0-Installer.exe.

The MKL installer can be found in https://www.intel.com/content/www/us/en/developer/tools/oneapi/onemkl-download.html.

Run the build script:

```powershell
> ./Build-Windows.ps1 -Version 0.0.6
```

## Building on Mac OS

Set the `MACOS_ARCH` env variable to `x86_64` or `arm64`:

```bash
$ export MACOS_ARCH=x86_64
```

Run the build script:

```bash
$ ./build-macos.sh 0.0.6
```
