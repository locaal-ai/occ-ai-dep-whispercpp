Param(
    [string]$Version
)

# check env var BUILD_WITH_ACCEL
if ($null -eq $env:BUILD_WITH_ACCEL) {
    Write-Host "Please set env var BUILD_WITH_ACCEL to 'cpu', 'cuda', 'vulkan', `mkl` or 'hipblas'."
    exit
}

$env:CMAKE_TOOLCHAIN_FILE=""
$env:VCPKG_ROOT=""

$cmakeArgs = @()
if ($env:BUILD_WITH_ACCEL -eq "cpu") {
    $cmakeArgs += (
        "-DWHISPERCPP_WITH_CUDA=OFF",
        "-DWHISPERCPP_WITH_HIPBLAS=OFF",
        "-DWHISPERCPP_WITH_VULKAN=OFF",
        "-DWHISPERCPP_WITH_MKL=OFF",
        "-DCMAKE_GENERATOR=Visual Studio 17 2022"
    )
    $zipFileName = "whispercpp-windows-cpu-$Version.zip"
} elseif ($env:BUILD_WITH_ACCEL -eq "hipblas") {
    $cmakeArgs += (
        "-DWHISPERCPP_WITH_CUDA=OFF",
        "-DWHISPERCPP_WITH_HIPBLAS=ON",
        "-DWHISPERCPP_WITH_VULKAN=OFF",
        "-DWHISPERCPP_WITH_MKL=OFF",
        "-DCMAKE_GENERATOR=Unix Makefiles", 
        "-DCMAKE_C_COMPILER='$env:HIP_PATH\bin\clang.exe'",
        "-DCMAKE_CXX_COMPILER='$env:HIP_PATH\bin\clang++.exe'")
    $zipFileName = "whispercpp-windows-hipblas-$Version.zip"
    $env:HIP_PLATFORM="amd"
} elseif ($env:BUILD_WITH_ACCEL -eq "vulkan") {
    $cmakeArgs += (
        "-DWHISPERCPP_WITH_CUDA=OFF",
        "-DWHISPERCPP_WITH_HIPBLAS=OFF",
        "-DWHISPERCPP_WITH_VULKAN=ON",
        "-DWHISPERCPP_WITH_MKL=OFF",
        "-DCMAKE_GENERATOR=Visual Studio 17 2022"
    )
    $zipFileName = "whispercpp-windows-vulkan-$Version.zip"
    # find the Vulkan SDK version path in C:\VulkanSDK\
    $vulkanSdkPath = Get-ChildItem -Path "C:\VulkanSDK" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $env:VULKAN_SDK_PATH="$vulkanSdkPath"
} elseif ($env:BUILD_WITH_ACCEL -eq "mkl") {
    $cmakeArgs += (
        "-DWHISPERCPP_WITH_CUDA=OFF",
        "-DWHISPERCPP_WITH_HIPBLAS=OFF",
        "-DWHISPERCPP_WITH_VULKAN=OFF",
        "-DWHISPERCPP_WITH_MKL=ON",
        "-DCMAKE_GENERATOR=Visual Studio 17 2022"
    )
    $zipFileName = "whispercpp-windows-mkl-$Version.zip"
    # find the MKL path in C:\Program Files (x86)\Intel\oneAPI
    $mklPath = Get-ChildItem -Path "C:\Program Files (x86)\Intel\oneAPI" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $env:MKL_PATH="$mklPath"
} elseif ($env:BUILD_WITH_ACCEL -eq "cuda") {
    $zipFileName = "whispercpp-windows-cuda-$Version.zip"
    # find the CUDA path in C:\Program Files\NVIDIA GPU Computing Toolkit
    $cudaPath = Get-ChildItem -Path "C:\Program Files\NVIDIA GPU Computing Toolkit" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $env:CUDA_TOOLKIT_ROOT_DIR="$cudaPath"
    $cmakeArgs += (
        "-DWHISPERCPP_WITH_CUDA=ON",
        "-DWHISPERCPP_WITH_HIPBLAS=OFF",
        "-DWHISPERCPP_WITH_VULKAN=OFF",
        "-DWHISPERCPP_WITH_MKL=OFF",
        "-DCMAKE_GENERATOR=Visual Studio 17 2022",
        "-DCUDA_TOOLKIT_ROOT_DIR=$env:CUDA_TOOLKIT_ROOT_DIR"
    )
} else {
    Write-Host "Invalid BUILD_WITH_ACCEL value. Please set it to 'cpu', 'cuda', 'vulkan', `mkl` or 'hipblas'."
    exit
}

# configure
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release @cmakeArgs

cmake --build build --config Release

# install
cmake --install build

# compress the release folder
Compress-Archive -Force -Path release -DestinationPath $zipFileName
