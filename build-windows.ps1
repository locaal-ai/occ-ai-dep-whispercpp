Param(
    [string]$Version
)

# check env var BUILD_WITH_ACCEL
if ($env:BUILD_WITH_ACCEL -eq $null) {
    Write-Host "Please set env var BUILD_WITH_ACCEL to 'cpu', 'cuda' or 'hipblas'."
    exit
}

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
} else {
    $cmakeArgs += (
        "-DWHISPERCPP_WITH_CUDA=ON",
        "-DCUDA_TOOLKIT_ROOT_DIR=$env:CUDA_TOOLKIT_ROOT_DIR"
    )
    $zipFileName = "whispercpp-windows-cuda-$Version.zip"
}

# configure
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release @cmakeArgs

cmake --build build --config RelWithDebInfo

# install
cmake --install build

Get-ChildItem

# compress the release folder
Compress-Archive -Force -Path release -DestinationPath $zipFileName
