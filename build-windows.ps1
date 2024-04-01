Param(
    [string]$Version
)

# check env var CPU_OR_CUDA
if ($env:CPU_OR_CUDA -eq $null) {
    Write-Host "Please set env var CPU_OR_CUDA to 'cpu' or the CUDA version you want to use"
    exit
}

$cmakeArgs = @()
if ($env:CPU_OR_CUDA -eq "cpu") {
    $cmakeArgs += ("-DWHISPERCPP_WITH_CUDA=OFF")
    $zipFileName = "whispercpp-windows-cpu-$Version.zip"
} else {
    $cmakeArgs += (
        "-DWHISPERCPP_WITH_CUDA=ON",
        "-DCUDA_TOOLKIT_ROOT_DIR=$env:CUDA_TOOLKIT_ROOT_DIR"
    )
    $zipFileName = "whispercpp-windows-cuda$env:CPU_OR_CUDA-$Version.zip"
}

# configure
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release @cmakeArgs

cmake --build build --config Release

# install
cmake --install build

# compress the release folder
Compress-Archive -Path release -DestinationPath $zipFileName
