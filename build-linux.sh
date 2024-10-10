# Description: Build script for linux
#!/bin/bash

# get version from first argument
version=$1

# check env var BUILD_WITH_ACCEL
if [ "$BUILD_WITH_ACCEL" = "vulkan" ]; then
    echo "Building with acceleration"
    export CMAKE_ARGS="$CMAKE_ARGS -DWHISPERCPP_WITH_VULKAN=ON"
else
    echo "Building without acceleration"
fi

# configure
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release $CMAKE_ARGS

cmake --build build --config Release

# install
cmake --install build

# compress the release folder
tar -czvf whispercpp-linux-$LINUX_ARCH-$BUILD_WITH_ACCEL-$version.tar.gz release
