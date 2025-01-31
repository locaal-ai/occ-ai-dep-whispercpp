# From: https://github.com/thewh1teagle/vibe/blob/main/scripts/setup_cuda.ps1
# Rendered here under the MIT License
# Copyright (c) 2024 thewh1teagle

$CUDA_VERSION_FULL = $env:INPUT_CUDA_VERSION # v12.5.0 or v11.8.0

# Make sure CUDA_VERSION_FULL is set and valid, otherwise error.
# Validate CUDA version, extracting components via regex
$cuda_ver_matched = $CUDA_VERSION_FULL -match "^(?<major>[1-9][0-9]*)\.(?<minor>[0-9]+)\.(?<patch>[0-9]+)$"
if (-not $cuda_ver_matched) {
    Write-Output "Invalid CUDA version specified, <major>.<minor>.<patch> required. '$CUDA_VERSION_FULL'."
    exit 1
}
$CUDA_MAJOR = $Matches.major
$CUDA_MINOR = $Matches.minor
$CUDA_PATCH = $Matches.patch

Write-Output "Selected CUDA version: $CUDA_VERSION_FULL"

$src = "cuda"
$dst = "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v$($CUDA_MAJOR).$($CUDA_MINOR)"
$installer = "cuda.exe"

$cudaVersions = @{
    '12.8.0'   = 'https://developer.download.nvidia.com/compute/cuda/12.8.0/local_installers/cuda_12.8.0_571.96_windows.exe'
    '12.6.3'   = 'https://developer.download.nvidia.com/compute/cuda/12.6.3/local_installers/cuda_12.6.3_561.17_windows.exe'
    '12.6.2'   = 'https://developer.download.nvidia.com/compute/cuda/12.6.2/local_installers/cuda_12.6.2_560.94_windows.exe'
    '12.6.1'   = 'https://developer.download.nvidia.com/compute/cuda/12.6.1/local_installers/cuda_12.6.1_560.94_windows.exe'
    '12.6.0'   = 'https://developer.download.nvidia.com/compute/cuda/12.6.0/local_installers/cuda_12.6.0_560.76_windows.exe'
    '12.5.1'   = 'https://developer.download.nvidia.com/compute/cuda/12.5.1/local_installers/cuda_12.5.1_555.85_windows.exe'
    '12.5.0'   = 'https://developer.download.nvidia.com/compute/cuda/12.5.0/local_installers/cuda_12.5.0_555.85_windows.exe'
    '12.4.1'   = 'https://developer.download.nvidia.com/compute/cuda/12.4.1/local_installers/cuda_12.4.1_551.78_windows.exe'
    '12.4.0'   = 'https://developer.download.nvidia.com/compute/cuda/12.4.0/local_installers/cuda_12.4.0_551.61_windows.exe'
    '12.3.2'   = 'https://developer.download.nvidia.com/compute/cuda/12.3.2/local_installers/cuda_12.3.2_546.12_windows.exe'
    '12.3.1'   = 'https://developer.download.nvidia.com/compute/cuda/12.3.1/local_installers/cuda_12.3.1_546.12_windows.exe'
    '12.3.0'   = 'https://developer.download.nvidia.com/compute/cuda/12.3.0/local_installers/cuda_12.3.0_545.84_windows.exe'
    '12.2.2'   = 'https://developer.download.nvidia.com/compute/cuda/12.2.2/local_installers/cuda_12.2.2_537.13_windows.exe'
    '12.2.1'   = 'https://developer.download.nvidia.com/compute/cuda/12.2.1/local_installers/cuda_12.2.1_536.67_windows.exe'
    '12.2.0'   = 'https://developer.download.nvidia.com/compute/cuda/12.2.0/local_installers/cuda_12.2.0_536.25_windows.exe'
    '12.1.1'   = 'https://developer.download.nvidia.com/compute/cuda/12.1.1/local_installers/cuda_12.1.1_531.14_windows.exe'
    '12.1.0'   = 'https://developer.download.nvidia.com/compute/cuda/12.1.0/local_installers/cuda_12.1.0_531.14_windows.exe'
    '12.0.1'   = 'https://developer.download.nvidia.com/compute/cuda/12.0.1/local_installers/cuda_12.0.1_528.33_windows.exe'
    '12.0.0'   = 'https://developer.download.nvidia.com/compute/cuda/12.0.0/local_installers/cuda_12.0.0_527.41_windows.exe'
    '11.8.0'   = 'https://developer.download.nvidia.com/compute/cuda/11.8.0/local_installers/cuda_11.8.0_522.06_windows.exe'
    '11.7.1'   = 'https://developer.download.nvidia.com/compute/cuda/11.7.1/local_installers/cuda_11.7.1_516.94_windows.exe'
    '11.7.0'   = 'https://developer.download.nvidia.com/compute/cuda/11.7.0/local_installers/cuda_11.7.0_516.01_windows.exe'
    '11.6.2'   = 'https://developer.download.nvidia.com/compute/cuda/11.6.2/local_installers/cuda_11.6.2_511.65_windows.exe'
    '11.6.1'   = 'https://developer.download.nvidia.com/compute/cuda/11.6.1/local_installers/cuda_11.6.1_511.65_windows.exe'
    '11.6.0'   = 'https://developer.download.nvidia.com/compute/cuda/11.6.0/local_installers/cuda_11.6.0_511.23_windows.exe'
    '11.5.2'   = 'https://developer.download.nvidia.com/compute/cuda/11.5.2/local_installers/cuda_11.5.2_496.13_windows.exe'
    '11.5.1'   = 'https://developer.download.nvidia.com/compute/cuda/11.5.1/local_installers/cuda_11.5.1_496.13_windows.exe'
    '11.5.0'   = 'https://developer.download.nvidia.com/compute/cuda/11.5.0/local_installers/cuda_11.5.0_496.13_win10.exe'
    '11.4.4'   = 'https://developer.download.nvidia.com/compute/cuda/11.4.4/local_installers/cuda_11.4.4_472.50_windows.exe'
    '11.4.3'   = 'https://developer.download.nvidia.com/compute/cuda/11.4.3/local_installers/cuda_11.4.3_472.50_win10.exe'
    '11.4.2'   = 'https://developer.download.nvidia.com/compute/cuda/11.4.2/local_installers/cuda_11.4.2_471.41_win10.exe'
    '11.4.1'   = 'https://developer.download.nvidia.com/compute/cuda/11.4.1/local_installers/cuda_11.4.1_471.41_win10.exe'
    '11.4.0'   = 'https://developer.download.nvidia.com/compute/cuda/11.4.0/local_installers/cuda_11.4.0_471.11_win10.exe'
    '11.3.1'   = 'https://developer.download.nvidia.com/compute/cuda/11.3.1/local_installers/cuda_11.3.1_465.89_win10.exe'
    '11.3.0'   = 'https://developer.download.nvidia.com/compute/cuda/11.3.0/local_installers/cuda_11.3.0_465.89_win10.exe'
    '11.2.2'   = 'https://developer.download.nvidia.com/compute/cuda/11.2.2/local_installers/cuda_11.2.2_461.33_win10.exe'
    '11.2.1'   = 'https://developer.download.nvidia.com/compute/cuda/11.2.1/local_installers/cuda_11.2.1_461.09_win10.exe'
    '11.2.0'   = 'https://developer.download.nvidia.com/compute/cuda/11.2.0/local_installers/cuda_11.2.0_460.89_win10.exe'
    '11.1.1'   = 'https://developer.download.nvidia.com/compute/cuda/11.1.1/local_installers/cuda_11.1.1_456.81_win10.exe'
    '11.0.3'   = 'https://developer.download.nvidia.com/compute/cuda/11.0.3/local_installers/cuda_11.0.3_451.82_win10.exe'
    '11.0.2'   = 'https://developer.download.nvidia.com/compute/cuda/11.0.2/local_installers/cuda_11.0.2_451.48_win10.exe'
    '11.0.1'   = 'https://developer.download.nvidia.com/compute/cuda/11.0.1/local_installers/cuda_11.0.1_451.22_win10.exe'
    '10.2.89'  = 'https://developer.download.nvidia.com/compute/cuda/10.2/Prod/local_installers/cuda_10.2.89_441.22_win10.exe'
    '10.1.243' = 'https://developer.download.nvidia.com/compute/cuda/10.1/Prod/local_installers/cuda_10.1.243_426.00_win10.exe'
    '10.0.130' = 'https://developer.nvidia.com/compute/cuda/10.0/Prod/local_installers/cuda_10.0.130_411.31_win10'
    '9.2.148'  = 'https://developer.nvidia.com/compute/cuda/9.2/Prod2/local_installers2/cuda_9.2.148_win10'
    '8.0.61'   = 'https://developer.nvidia.com/compute/cuda/8.0/Prod2/local_installers/cuda_8.0.61_win10-exe'
}

if ($cudaVersions.ContainsKey($CUDA_VERSION_FULL)) {
    $cudaInstallerUrl = $cudaVersions[$cudaVersion]
    Write-Output "CUDA version $cudaVersion found. Downloading from $cudaInstallerUrl"
    # Add your download and installation logic here
    $downloadUrl = $cudaInstallerUrl
}
else {
    Write-Output "CUDA version $cudaVersion not found."
    exit 1
}

# Download cuda
Write-Output "Downloading CUDA from: $downloadUrl"
if (-not (Test-Path -Path $installer)) {
    Write-Output "Downloading CUDA installer..."
    # If the file does not exist, download it
    & "C:\msys64\usr\bin\wget" $downloadUrl -O $installer -q
}

# Extract cuda
if (-not (Test-Path -Path $src -Type Container)) {
    # Extract CUDA using 7-Zip
    Write-Output "Extracting CUDA using 7-Zip..."
    mkdir "$src"
    & 'C:\Program Files\7-Zip\7z' x $installer -o"$src"
}

# Create destination directory if it doesn't exist
if (-Not (Test-Path -Path $dst)) {
    Write-Output "Creating destination directory: $dst"
    New-Item -Path $dst -ItemType Directory
}

# Get directories to process from the source path
$directories = Get-ChildItem -Directory -Path $src
$whitelist = @("CUDA_Toolkit_Release_Notes.txt", "DOCS", "EULA.txt", "LICENSE", "README", "version.json")

foreach ($dir in $directories) {
    # Get all subdirectories and files in the current directory
    $items = Get-ChildItem -Path (Join-Path $src $dir.Name)

    foreach ($item in $items) {
        if ($item.PSIsContainer) {
            # If the item is a directory, copy its contents
            Write-Output "Copying contents of directory $($item.FullName) to $dst"
            Copy-Item -Path "$($item.FullName)\*" -Destination $dst -Recurse -Force
        }
        else {
            if ($whitelist -contains $item.Name) {
                Write-Output "Copying file $($item.FullName) to $dst"
                Copy-Item -Path $item.FullName -Destination $dst -Force
            }
        }
    }
}

# Add msbuild cuda extensions
$msBuildExtensions = (Get-ChildItem  "$src\visual_studio_integration\CUDAVisualStudioIntegration\extras\visual_studio_integration\MSBuildExtensions").fullname
(Get-ChildItem 'C:\Program Files\Microsoft Visual Studio\2022\*\MSBuild\Microsoft\VC\*\BuildCustomizations').FullName | ForEach-Object { 
    $destination = $_
    $msBuildExtensions | ForEach-Object {
        $extension = $_
        Copy-Item $extension -Destination $destination -Force
        Write-Output "Copied $extension to $destination"
    }
}

# Add to Github env
Write-Output "Setting environment variables for GitHub Actions..."

Write-Output "CUDA_PATH=$dst"
Write-Output "CUDA_PATH_V$($CUDA_MAJOR)_$($CUDA_MINOR)=$dst"
Write-Output "CUDA_PATH_VX_Y=CUDA_PATH_V$($CUDA_MAJOR)_$($CUDA_MINOR)"
Write-Output "CUDA_VERSION=$CUDA_VERSION_FULL"

Write-Output "CUDA_PATH=$dst" >> $env:GITHUB_ENV
Write-Output "CUDA_PATH_V$($CUDA_MAJOR)_$($CUDA_MINOR)=$dst" >> $env:GITHUB_ENV
Write-Output "CUDA_PATH_VX_Y=CUDA_PATH_V$($CUDA_MAJOR)_$($CUDA_MINOR)" >> $env:GITHUB_ENV
Write-Output "CudaToolkitDir=$dst" >> $env:GITHUB_ENV
Write-Output "CMAKE_CUDA_COMPILER=$dst\bin\nvcc.exe" >> $env:GITHUB_ENV
Write-Output "NVCC_APPEND_FLAGS=-allow-unsupported-compiler" >> $env:GITHUB_ENV

Write-Output "CUDA_VERSION=$CUDA_VERSION_FULL" >> $env:GITHUB_ENV
Write-Output "Setup completed."
