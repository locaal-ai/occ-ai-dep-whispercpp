Param(
    [string]$Version
)

# check env var BUILD_WITH_ACCEL
if ($env:BUILD_WITH_ACCEL -eq $null) {
    Write-Host "Please set env var BUILD_WITH_ACCEL to 'cpu', 'cuda', 'vulkan' or 'hipblas'."
    exit
}

$env:CMAKE_TOOLCHAIN_FILE=""
$env:VCPKG_ROOT=""

$cmakeArgs = @()
if ($env:BUILD_WITH_ACCEL -eq "cpu") {
    $cmakeArgs += ("-DWHISPERCPP_WITH_CUDA=OFF")
    $zipFileName = "whispercpp-windows-cpu-$Version.zip"
} elseif ($env:BUILD_WITH_ACCEL -eq "hipblas") {
    $cmakeArgs += ("-DWHISPERCPP_WITH_CUDA=OFF", 
        "-DWHISPERCPP_WITH_HIPBLAS=ON", 
        "-DCMAKE_GENERATOR=Unix Makefiles", 
        "-DCMAKE_C_COMPILER='$env:HIP_PATH\bin\clang.exe'",
        "-DCMAKE_CXX_COMPILER='$env:HIP_PATH\bin\clang++.exe'")
    $zipFileName = "whispercpp-windows-hipblas-$Version.zip"
    $env:HIP_PLATFORM="amd"
} elseif ($env:BUILD_WITH_ACCEL -eq "vulkan") {
    $cmakeArgs += (
        "-DWHISPERCPP_WITH_VULKAN=ON",
        "-DCMAKE_GENERATOR=Visual Studio 17 2022"
    )
    $zipFileName = "whispercpp-windows-vulkan-$Version.zip"
    # find the Vulkan SDK version path in C:\VulkanSDK\
    $vulkanSdkPath = Get-ChildItem -Path "C:\VulkanSDK" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $env:VULKAN_SDK_PATH="$vulkanSdkPath"
} else {
    $cmakeArgs += (
        "-DWHISPERCPP_WITH_CUDA=ON",
        "-DCMAKE_GENERATOR=Visual Studio 17 2022",
        "-DCUDA_TOOLKIT_ROOT_DIR=$env:CUDA_TOOLKIT_ROOT_DIR"
    )
    $zipFileName = "whispercpp-windows-cuda-$Version.zip"
}

# configure
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release @cmakeArgs

cmake --build build --config Release

# install
cmake --install build

# compress the release folder
Compress-Archive -Force -Path release -DestinationPath $zipFileName
