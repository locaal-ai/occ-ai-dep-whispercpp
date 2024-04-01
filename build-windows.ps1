
# check env var CPU_OR_CUDA
if ($env:CPU_OR_CUDA -eq $null) {
    Write-Host "Please set env var CPU_OR_CUDA to 'cpu' or the CUDA version you want to use"
    exit
}

$cmakeArgs = @()
if ($env:CPU_OR_CUDA -eq "cpu") {
    $cmakeArgs += ("-DWHISPERCPP_WITH_CUDA=OFF")
} else {
    $cmakeArgs += (
        "-DWHISPERCPP_WITH_CUDA=ON",
        "-DCUDA_TOOLKIT_ROOT_DIR=$env:CUDA_TOOLKIT_ROOT_DIR"
    )
}

Remove-Item -Path build/CMakeCache.txt -Force

# configure
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release @cmakeArgs

cmake --build build --config Release

Remove-Item -Path release -Recurse -Force

# install
cmake --install build

# compress the release folder
Compress-Archive -Path release -DestinationPath whispercpp-windows-$env:CPU_OR_CUDA.zip
