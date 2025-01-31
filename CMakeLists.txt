cmake_minimum_required(VERSION 3.21)

project(Whispercpp_prebuilt)

include(ExternalProject)
include(FetchContent)

option(WHISPERCPP_WITH_CUDA "Build Whisper with CUDA support" OFF)
option(WHISPERCPP_WITH_HIPBLAS "Build Whisper with hipBLAS support" OFF)
option(WHISPERCPP_WITH_VULKAN "Build Whisper with Vulkan support" OFF)

set(CMAKE_OSX_ARCHITECTURES_ "$ENV{MACOS_ARCH}")

set(Whispercpp_Build_GIT_TAG "8a9ad7844d6e2a10cddf4b92de4089d7ac2b14a9")

if(${CMAKE_BUILD_TYPE} STREQUAL Release OR ${CMAKE_BUILD_TYPE} STREQUAL
  RelWithDebInfo)
  set(Whispercpp_BUILD_TYPE Release)
else()
  set(Whispercpp_BUILD_TYPE Debug)
endif()

if(UNIX AND NOT APPLE)
  # On linux add the `-fPIC` flag to the compiler
  set(WHISPER_EXTRA_CXX_FLAGS "-fPIC")

  if(WHISPERCPP_WITH_VULKAN)
    set(WHISPER_ADDITIONAL_CMAKE_ARGS -DGGML_CUDA=OFF -DGGML_VULKAN=ON)
  else()
    set(WHISPER_ADDITIONAL_CMAKE_ARGS -DGGML_CUDA=OFF)
  endif()
endif()

if(APPLE)
  # check the "MACOS_ARCH" env var to figure out if this is x86_64 or arm64
  if(NOT DEFINED ENV{MACOS_ARCH})
    message(
      FATAL_ERROR
      "The MACOS_ARCH environment variable is not set. Please set it to either `x86_64` or `arm64`"
    )
  endif(NOT DEFINED ENV{MACOS_ARCH})

  set(WHISPER_ADDITIONAL_CMAKE_ARGS -DGGML_METAL=ON -DWHISPER_COREML=ON
    -DWHISPER_COREML_ALLOW_FALLBACK=ON -DGGML_NATIVE=OFF)
  set(WHISPER_EXTRA_CXX_FLAGS
    "-Wno-shorten-64-to-32 -Wno-unused-parameter -Wno-unused-function -Wno-unguarded-availability-new"
  )
endif()

if(WIN32)
  if(WHISPERCPP_WITH_CUDA)
    # Build with CUDA
    set(WHISPER_ADDITIONAL_ENV "")
    set(WHISPER_ADDITIONAL_CMAKE_ARGS -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES=all)
    set(WHISPER_CMAKE_GENERATOR ${CMAKE_GENERATOR})
  elseif(WHISPERCPP_WITH_VULKAN)
    if(NOT DEFINED ENV{VULKAN_SDK_PATH})
      message(
        FATAL_ERROR
        "VULKAN_SDK_PATH is not set. Please set it to the root directory of your VulkanSDK installation, e.g. `C:/VulkanSDK/1.3.296.0`"
      )
    endif()

    # Build with VULKAN
    set(WHISPER_ADDITIONAL_ENV "VULKAN_SDK=$ENV{VULKAN_SDK_PATH}")
    set(WHISPER_ADDITIONAL_CMAKE_ARGS -DGGML_VULKAN=ON)
    set(WHISPER_CMAKE_GENERATOR ${CMAKE_GENERATOR})
  elseif(WHISPERCPP_WITH_HIPBLAS)
    # Build with hipBLAS
    if(NOT DEFINED ENV{HIP_PATH})
      message(
        FATAL_ERROR
        "HIP_PATH is not set. Please set it to the root directory of your HIP installation, e.g. `C:/Program Files/ROCm`"
      )
    endif(NOT DEFINED ENV{HIP_PATH})

    cmake_path(SET HIP_PATH_STR NORMALIZE "$ENV{HIP_PATH}")
    set(WHISPER_ADDITIONAL_ENV "CMAKE_PREFIX_PATH=${HIP_PATH_STR}")
    set(WHISPER_ADDITIONAL_CMAKE_ARGS
      -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
      -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER} -DGGML_HIPBLAS=ON
      -DGGML_CUDA=OFF)
    set(WHISPER_CMAKE_GENERATOR ${CMAKE_GENERATOR})
  else()
    # Build with OpenBLAS
    set(OpenBLAS_URL
      "https://github.com/OpenMathLib/OpenBLAS/releases/download/v0.3.26/OpenBLAS-0.3.26-x64.zip"
    )
    set(OpenBLAS_SHA256
      "859C510A962A30EF1B01AA93CDE26FDB5FB1050F94AD5AB2802EBA3731935E06")
    FetchContent_Declare(
      OpenBLAS
      URL ${OpenBLAS_URL}
      URL_HASH SHA256=${OpenBLAS_SHA256}
      DOWNLOAD_EXTRACT_TIMESTAMP true)
    FetchContent_MakeAvailable(OpenBLAS)
    set(OpenBLAS_DIR ${openblas_SOURCE_DIR})
    message(STATUS "OpenBLAS_DIR: ${OpenBLAS_DIR}")
    set(WHISPER_ADDITIONAL_ENV "OPENBLAS_PATH=${openblas_SOURCE_DIR}")
    set(WHISPER_ADDITIONAL_CMAKE_ARGS
      -DGGML_BLAS=ON -DGGML_BLAS_VENDOR=OpenBLAS -DGGML_CUDA=OFF
      -DBLAS_LIBRARIES=${OpenBLAS_DIR}/lib/libopenblas.lib
      -DBLAS_INCLUDE_DIRS=${OpenBLAS_DIR}/include)
    set(WHISPER_CMAKE_GENERATOR ${CMAKE_GENERATOR})
  endif()

  ExternalProject_Add(
    Whispercpp_Build
    DOWNLOAD_EXTRACT_TIMESTAMP true
    GIT_REPOSITORY https://github.com/ggerganov/whisper.cpp.git
    GIT_TAG ${Whispercpp_Build_GIT_TAG}
    BUILD_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> --config
    ${Whispercpp_BUILD_TYPE} --verbose
    BUILD_BYPRODUCTS
    <INSTALL_DIR>/lib/static/${CMAKE_STATIC_LIBRARY_PREFIX}whisper${CMAKE_STATIC_LIBRARY_SUFFIX}
    <INSTALL_DIR>/bin/${CMAKE_SHARED_LIBRARY_PREFIX}whisper${CMAKE_SHARED_LIBRARY_SUFFIX}
    <INSTALL_DIR>/lib/${CMAKE_IMPORT_LIBRARY_PREFIX}whisper${CMAKE_IMPORT_LIBRARY_SUFFIX}
    CMAKE_GENERATOR ${CMAKE_GENERATOR}
    INSTALL_COMMAND ${CMAKE_COMMAND} --install <BINARY_DIR> --config
    ${Whispercpp_BUILD_TYPE}
    CONFIGURE_COMMAND
    ${CMAKE_COMMAND} -E env ${WHISPER_ADDITIONAL_ENV} ${CMAKE_COMMAND}
    <SOURCE_DIR> -B <BINARY_DIR> -G ${WHISPER_CMAKE_GENERATOR}
    -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
    -DCMAKE_BUILD_TYPE=${Whispercpp_BUILD_TYPE}
    -DCMAKE_GENERATOR_PLATFORM=${CMAKE_GENERATOR_PLATFORM}
    -DCMAKE_CXX_FLAGS=${WHISPER_EXTRA_CXX_FLAGS}
    -DCMAKE_C_FLAGS=${WHISPER_EXTRA_CXX_FLAGS} -DBUILD_SHARED_LIBS=ON
    -DWHISPER_BUILD_TESTS=OFF -DWHISPER_BUILD_EXAMPLES=OFF
    -DWHISPER_BUILD_SERVER=OFF -DCMAKE_MODULE_PATH=${CMAKE_SOURCE_DIR}/cmake
    ${WHISPER_ADDITIONAL_CMAKE_ARGS})
else()
  # On Linux and MacOS build a static Whisper library
  ExternalProject_Add(
    Whispercpp_Build
    DOWNLOAD_EXTRACT_TIMESTAMP true
    GIT_REPOSITORY https://github.com/ggerganov/whisper.cpp.git
    GIT_TAG ${Whispercpp_Build_GIT_TAG}
    BUILD_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> --config
    ${Whispercpp_BUILD_TYPE}
    BUILD_BYPRODUCTS
    <INSTALL_DIR>/lib/static/${CMAKE_STATIC_LIBRARY_PREFIX}whisper${CMAKE_STATIC_LIBRARY_SUFFIX}
    CMAKE_GENERATOR ${CMAKE_GENERATOR}
    INSTALL_COMMAND
    ${CMAKE_COMMAND} --install <BINARY_DIR> --config ${Whispercpp_BUILD_TYPE}
    && ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/ggml/include/ggml.h
    <INSTALL_DIR>/include
    CONFIGURE_COMMAND
    ${CMAKE_COMMAND} -E env ${WHISPER_ADDITIONAL_ENV} ${CMAKE_COMMAND}
    <SOURCE_DIR> -B <BINARY_DIR> -G ${CMAKE_GENERATOR}
    -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
    -DCMAKE_BUILD_TYPE=${Whispercpp_BUILD_TYPE}
    -DCMAKE_GENERATOR_PLATFORM=${CMAKE_GENERATOR_PLATFORM}
    -DCMAKE_OSX_DEPLOYMENT_TARGET=15.2
    -DCMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES_}
    -DCMAKE_CXX_FLAGS=${WHISPER_EXTRA_CXX_FLAGS}
    -DCMAKE_C_FLAGS=${WHISPER_EXTRA_CXX_FLAGS} -DBUILD_SHARED_LIBS=OFF
    -DWHISPER_BUILD_TESTS=OFF -DWHISPER_BUILD_EXAMPLES=OFF
    -DWHISPER_BUILD_SERVER=OFF ${WHISPER_ADDITIONAL_CMAKE_ARGS})
endif(WIN32)

ExternalProject_Get_Property(Whispercpp_Build INSTALL_DIR)
ExternalProject_Get_Property(Whispercpp_Build BINARY_DIR)

# add the Whisper library to the link line
if(WIN32)
  # copy lib/ include/ and bin/ from ${INSTALL_DIR} to the release directory in
  # the root of the project
  install(DIRECTORY ${INSTALL_DIR}/lib DESTINATION ${CMAKE_SOURCE_DIR}/release)
  install(DIRECTORY ${INSTALL_DIR}/include
    DESTINATION ${CMAKE_SOURCE_DIR}/release)
  install(DIRECTORY ${INSTALL_DIR}/bin DESTINATION ${CMAKE_SOURCE_DIR}/release)

  if(WHISPERCPP_WITH_HIPBLAS)
    message(STATUS "Setup HIP DLLs installation")
    set(HIPBLAS_DLLS
      "${HIP_PATH_STR}/bin/hipblas.dll" "${HIP_PATH_STR}/bin/rocblas.dll"
      "${HIP_PATH_STR}/bin/amdhip64_6.dll"
      "${HIP_PATH_STR}/bin/amd_comgr_2.dll")
    install(FILES ${HIPBLAS_DLLS} DESTINATION ${CMAKE_SOURCE_DIR}/release/bin)
  elseif(WHISPERCPP_WITH_VULKAN)
    message(STATUS "Vulkan does not require DLLs copy")
  elseif(WHISPERCPP_WITH_CUDA)
    # Check that CUDA_TOOLKIT_ROOT_DIR is set
    if(NOT DEFINED CUDA_TOOLKIT_ROOT_DIR)
      message(
        FATAL_ERROR
        "CUDA_TOOLKIT_ROOT_DIR is not set. Please set it to the root directory of your CUDA "
        "installation, e.g. `C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v11.4`"
      )
    endif(NOT DEFINED CUDA_TOOLKIT_ROOT_DIR)

    # normalize CUDA path with file(TO_CMAKE_PATH)
    file(TO_CMAKE_PATH ${CUDA_TOOLKIT_ROOT_DIR} CUDA_TOOLKIT_ROOT_DIR)

    # find the CUDA DLLs for cuBLAS in the bin directory of the CUDA
    # installation e.g. cublas64_NN.dll
    file(GLOB CUBLAS_DLLS "${CUDA_TOOLKIT_ROOT_DIR}/bin/cublas64_*.dll")

    # find cublasLt DLL, e.g. cublasLt64_11.dll
    file(GLOB CUBLASLT_DLLS "${CUDA_TOOLKIT_ROOT_DIR}/bin/cublasLt64_*.dll")

    # find cudart DLL, e.g. cudart64_110.dll
    file(GLOB CUDART_DLLS "${CUDA_TOOLKIT_ROOT_DIR}/bin/cudart64_*.dll")

    # if any of the files cannot be found, abort
    if(NOT CUBLAS_DLLS
      OR NOT CUBLASLT_DLLS
      OR NOT CUDART_DLLS)
      message(
        FATAL_ERROR
        "Could not find cuBLAS, cuBLASLt or cuDART DLLs in ${CUDA_TOOLKIT_ROOT_DIR}/bin"
      )
    endif()

    # copy the DLLs to the OBS plugin directory
    install(FILES ${CUBLAS_DLLS} ${CUBLASLT_DLLS} ${CUDART_DLLS}
      DESTINATION ${CMAKE_SOURCE_DIR}/release/bin)
  else()
    message(STATUS "Install OpenBLAS DLLs")

    # add openblas to the link line
    install(DIRECTORY ${OpenBLAS_DIR}/lib
      DESTINATION ${CMAKE_SOURCE_DIR}/release)
    install(DIRECTORY ${OpenBLAS_DIR}/include
      DESTINATION ${CMAKE_SOURCE_DIR}/release)
    install(DIRECTORY ${OpenBLAS_DIR}/bin
      DESTINATION ${CMAKE_SOURCE_DIR}/release)
  endif()
else()
  # copy lib/ include/ and bin/ from ${INSTALL_DIR} to the release directory in
  # the root of the project
  install(DIRECTORY ${INSTALL_DIR}/lib DESTINATION ${CMAKE_SOURCE_DIR}/release)
  install(DIRECTORY ${INSTALL_DIR}/include
    DESTINATION ${CMAKE_SOURCE_DIR}/release)

  if(APPLE)
    # copy the Metal shader library to the release directory
    install(DIRECTORY ${INSTALL_DIR}/bin
      DESTINATION ${CMAKE_SOURCE_DIR}/release)
    install(
      FILES
      ${BINARY_DIR}/src/${CMAKE_STATIC_LIBRARY_PREFIX}whisper.coreml${CMAKE_STATIC_LIBRARY_SUFFIX}
      DESTINATION ${CMAKE_SOURCE_DIR}/release/lib)
  endif()
endif(WIN32)
