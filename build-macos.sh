# Description: Build script for macOS
#!/bin/bash

# get version from first argument
version=$1

# configure
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release

cmake --build build --config Release

# install
cmake --install build

# compress the release folder
tar -czvf whispercpp-macos-$version.tar.gz release
