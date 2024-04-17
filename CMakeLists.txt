cmake_minimum_required(VERSION 3.21)

project(Whispercpp_prebuilt)

include(ExternalProject)
include(FetchContent)

option(WHISPERCPP_WITH_CUDA "Build Whisper with CUDA support" OFF)
option(WHISPERCPP_WITH_CLBLAST "Build Whisper with CLBlast support" OFF)

set(CMAKE_OSX_ARCHITECTURES_ "$ENV{MACOS_ARCH}")

set(Whispercpp_Build_GIT_TAG "v1.5.5")

if(${CMAKE_BUILD_TYPE} STREQUAL Release OR ${CMAKE_BUILD_TYPE} STREQUAL RelWithDebInfo)
  set(Whispercpp_BUILD_TYPE Release)
else()
  set(Whispercpp_BUILD_TYPE Debug)
endif()

if(UNIX AND NOT APPLE)
  # On linux add the `-fPIC` flag to the compiler
  set(WHISPER_EXTRA_CXX_FLAGS "-fPIC")
  set(WHISPER_ADDITIONAL_CMAKE_ARGS -DWHISPER_BLAS=OFF -DWHISPER_CUBLAS=OFF -DWHISPER_OPENBLAS=OFF -DWHISPER_NO_AVX=ON
                                    -DWHISPER_NO_AVX2=ON)
endif()
if(APPLE)
  # check the "MACOS_ARCH" env var to figure out if this is x86 or arm64
  if(NOT DEFINED ENV{MACOS_ARCH})
    message(FATAL_ERROR "The MACOS_ARCH environment variable is not set. Please set it to either `x86` or `arm64`")
  endif(NOT DEFINED ENV{MACOS_ARCH})
  if($ENV{MACOS_ARCH} STREQUAL "x86_64")
    set(WHISPER_ADDITIONAL_CMAKE_ARGS -DWHISPER_METAL=OFF -DWHISPER_COREML=OFF -DWHISPER_NO_AVX=OFF
                                      -DWHISPER_NO_AVX2=OFF -DWHISPER_NO_F16C=OFF)
  else()
    set(WHISPER_ADDITIONAL_CMAKE_ARGS -DWHISPER_METAL=OFF -DWHISPER_COREML=OFF -DWHISPER_NO_AVX=ON -DWHISPER_NO_AVX2=ON
                                      -DWHISPER_NO_F16C=ON -DWHISPER_NO_FMA=ON)
  endif()
  set(WHISPER_EXTRA_CXX_FLAGS
      "-Wno-shorten-64-to-32 -Wno-unused-parameter -Wno-unused-function -Wno-unguarded-availability-new")
endif()

if(WIN32)
  if(WHISPERCPP_WITH_CUDA)
    # Build with CUDA Check that CUDA_TOOLKIT_ROOT_DIR is set
    if(NOT DEFINED CUDA_TOOLKIT_ROOT_DIR)
      message(FATAL_ERROR "CUDA_TOOLKIT_ROOT_DIR is not set. Please set it to the root directory of your CUDA "
                          "installation, e.g. `C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v11.4`")
    endif(NOT DEFINED CUDA_TOOLKIT_ROOT_DIR)

    set(WHISPER_ADDITIONAL_ENV "CUDAToolkit_ROOT=${CUDA_TOOLKIT_ROOT_DIR}")
    set(WHISPER_ADDITIONAL_CMAKE_ARGS -DWHISPER_BLAS=OFF -DWHISPER_CUBLAS=ON -DWHISPER_OPENBLAS=OFF
                                      -DCMAKE_GENERATOR_TOOLSET=cuda=${CUDA_TOOLKIT_ROOT_DIR})
  elseif(WHISPERCPP_WITH_CLBLAST)
    # Build with CLBlast
    set(CLBLAST_URL "https://github.com/CNugteren/CLBlast/releases/download/1.6.2/CLBlast-1.6.2-windows-x64.zip")
    set(CLBLAST_SHA256 "09776AFACF89A960C59A0F072FE8595D8F49593B343E25C901F357DAC680018F")
    FetchContent_Declare(
      CLBlast
      DOWNLOAD_EXTRACT_TIMESTAMP true
      URL ${CLBLAST_URL}
      URL_HASH SHA256=${CLBLAST_SHA256})
    FetchContent_MakeAvailable(CLBlast)
    find_program(SEVEN_ZIP_EXECUTABLE 7z)
    if(NOT SEVEN_ZIP_EXECUTABLE)
      message(FATAL_ERROR "7z executable not found!")
    endif()
    execute_process(
      COMMAND ${SEVEN_ZIP_EXECUTABLE} x -y ${clblast_SOURCE_DIR}/CLBlast-1.6.2-windows-x64.7z
      WORKING_DIRECTORY ${clblast_SOURCE_DIR}
      RESULT_VARIABLE SEVEN_ZIP_RESULT
      OUTPUT_QUIET
    )
    if(NOT SEVEN_ZIP_RESULT EQUAL 0)
      message(FATAL_ERROR "Failed to extract CLBlast: ${SEVEN_ZIP_ERROR}")
    endif()
    set(clblast_SOURCE_DIR ${clblast_SOURCE_DIR}/CLBlast-1.6.2-windows-x64)

    set(OPENCL_SDK_URL "https://github.com/KhronosGroup/OpenCL-SDK/releases/download/v2023.12.14/OpenCL-SDK-v2023.12.14-Win-x64.zip")
    set(OPENCL_SDK_SHA256 "4C49F37A97B1B6D191B076C1E5D095B180E44BDC72DB32EC8B9748FF6ECFAEB6")
    FetchContent_Declare(
      OpenCL_SDK
      DOWNLOAD_EXTRACT_TIMESTAMP true
      URL ${OPENCL_SDK_URL}
      URL_HASH SHA256=${OPENCL_SDK_SHA256})
    FetchContent_MakeAvailable(OpenCL_SDK)

    message(STATUS "clblast_SOURCE_DIR: ${clblast_SOURCE_DIR}")
    set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
    find_package(CLBlast REQUIRED)

    set(WHISPER_ADDITIONAL_CMAKE_ARGS -DWHISPER_BLAS=OFF -DWHISPER_CUBLAS=OFF -DWHISPER_OPENBLAS=OFF
      -DWHISPER_CLBLAST=ON -Dclblast_SOURCE_DIR=${clblast_SOURCE_DIR} -Dopencl_sdk_SOURCE_DIR=${opencl_sdk_SOURCE_DIR})
  else()
    # Build with OpenBLAS
    set(OpenBLAS_URL "https://github.com/OpenMathLib/OpenBLAS/releases/download/v0.3.26/OpenBLAS-0.3.26-x64.zip")
    set(OpenBLAS_SHA256 "859C510A962A30EF1B01AA93CDE26FDB5FB1050F94AD5AB2802EBA3731935E06")
    FetchContent_Declare(
      OpenBLAS
      URL ${OpenBLAS_URL}
      URL_HASH SHA256=${OpenBLAS_SHA256}
      DOWNLOAD_EXTRACT_TIMESTAMP true
    )
    FetchContent_MakeAvailable(OpenBLAS)
    set(OpenBLAS_DIR ${openblas_SOURCE_DIR})
    message(STATUS "OpenBLAS_DIR: ${OpenBLAS_DIR}")
    set(WHISPER_ADDITIONAL_ENV "OPENBLAS_PATH=${openblas_SOURCE_DIR}")
    set(WHISPER_ADDITIONAL_CMAKE_ARGS -DWHISPER_BLAS=ON -DWHISPER_OPENBLAS=ON -DWHISPER_CUBLAS=OFF)
  endif()

  ExternalProject_Add(
    Whispercpp_Build
    DOWNLOAD_EXTRACT_TIMESTAMP true
    GIT_REPOSITORY https://github.com/ggerganov/whisper.cpp.git
    GIT_TAG ${Whispercpp_Build_GIT_TAG}
    BUILD_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> --config ${Whispercpp_BUILD_TYPE} --verbose
    BUILD_BYPRODUCTS
      <INSTALL_DIR>/lib/static/${CMAKE_STATIC_LIBRARY_PREFIX}whisper${CMAKE_STATIC_LIBRARY_SUFFIX}
      <INSTALL_DIR>/bin/${CMAKE_SHARED_LIBRARY_PREFIX}whisper${CMAKE_SHARED_LIBRARY_SUFFIX}
      <INSTALL_DIR>/lib/${CMAKE_IMPORT_LIBRARY_PREFIX}whisper${CMAKE_IMPORT_LIBRARY_SUFFIX}
    CMAKE_GENERATOR ${CMAKE_GENERATOR}
    INSTALL_COMMAND
      ${CMAKE_COMMAND} --install <BINARY_DIR> --config ${Whispercpp_BUILD_TYPE} && ${CMAKE_COMMAND} -E copy
      <BINARY_DIR>/${Whispercpp_BUILD_TYPE}/whisper.lib <INSTALL_DIR>/lib && ${CMAKE_COMMAND} -E copy
      <SOURCE_DIR>/ggml.h <INSTALL_DIR>/include
    CONFIGURE_COMMAND
      ${CMAKE_COMMAND} -E env ${WHISPER_ADDITIONAL_ENV} ${CMAKE_COMMAND} <SOURCE_DIR> -B <BINARY_DIR> -G
      ${CMAKE_GENERATOR} -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR> -DCMAKE_BUILD_TYPE=${Whispercpp_BUILD_TYPE}
      -DCMAKE_GENERATOR_PLATFORM=${CMAKE_GENERATOR_PLATFORM} -DCMAKE_OSX_DEPLOYMENT_TARGET=10.13
      -DCMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES_} -DCMAKE_CXX_FLAGS=${WHISPER_EXTRA_CXX_FLAGS}
      -DCMAKE_C_FLAGS=${WHISPER_EXTRA_CXX_FLAGS} -DBUILD_SHARED_LIBS=ON -DWHISPER_BUILD_TESTS=OFF
      -DWHISPER_BUILD_EXAMPLES=OFF -DCMAKE_MODULE_PATH=${CMAKE_SOURCE_DIR}/cmake ${WHISPER_ADDITIONAL_CMAKE_ARGS})

  if(NOT WHISPERCPP_WITH_CUDA AND NOT WHISPERCPP_WITH_CLBLAST)
    add_dependencies(Whispercpp_Build OpenBLAS)
  endif()
else()
  # On Linux and MacOS build a static Whisper library
  ExternalProject_Add(
    Whispercpp_Build
    DOWNLOAD_EXTRACT_TIMESTAMP true
    GIT_REPOSITORY https://github.com/ggerganov/whisper.cpp.git
    GIT_TAG ${Whispercpp_Build_GIT_TAG}
    BUILD_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> --config ${Whispercpp_BUILD_TYPE}
    BUILD_BYPRODUCTS <INSTALL_DIR>/lib/static/${CMAKE_STATIC_LIBRARY_PREFIX}whisper${CMAKE_STATIC_LIBRARY_SUFFIX}
    CMAKE_GENERATOR ${CMAKE_GENERATOR}
    INSTALL_COMMAND ${CMAKE_COMMAND} --install <BINARY_DIR> --config ${Whispercpp_BUILD_TYPE} && ${CMAKE_COMMAND} -E
                    copy <SOURCE_DIR>/ggml.h <INSTALL_DIR>/include
    CONFIGURE_COMMAND
      ${CMAKE_COMMAND} -E env ${WHISPER_ADDITIONAL_ENV} ${CMAKE_COMMAND} <SOURCE_DIR> -B <BINARY_DIR> -G
      ${CMAKE_GENERATOR} -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR> -DCMAKE_BUILD_TYPE=${Whispercpp_BUILD_TYPE}
      -DCMAKE_GENERATOR_PLATFORM=${CMAKE_GENERATOR_PLATFORM} -DCMAKE_OSX_DEPLOYMENT_TARGET=10.13
      -DCMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES_} -DCMAKE_CXX_FLAGS=${WHISPER_EXTRA_CXX_FLAGS}
      -DCMAKE_C_FLAGS=${WHISPER_EXTRA_CXX_FLAGS} -DBUILD_SHARED_LIBS=OFF -DWHISPER_BUILD_TESTS=OFF
      -DWHISPER_BUILD_EXAMPLES=OFF ${WHISPER_ADDITIONAL_CMAKE_ARGS})
endif(WIN32)

ExternalProject_Get_Property(Whispercpp_Build INSTALL_DIR)

# add the Whisper library to the link line
if(WIN32)
  # copy lib/ include/ and bin/ from ${INSTALL_DIR} to the release directory in the root of the project
  install(DIRECTORY ${INSTALL_DIR}/lib DESTINATION ${CMAKE_SOURCE_DIR}/release)
  install(DIRECTORY ${INSTALL_DIR}/include DESTINATION ${CMAKE_SOURCE_DIR}/release)
  install(DIRECTORY ${INSTALL_DIR}/bin DESTINATION ${CMAKE_SOURCE_DIR}/release)

  if(NOT WHISPERCPP_WITH_CUDA AND NOT WHISPERCPP_WITH_CLBLAST)
    # add openblas to the link line
    install(DIRECTORY ${OpenBLAS_DIR}/lib DESTINATION ${CMAKE_SOURCE_DIR}/release)
    install(DIRECTORY ${OpenBLAS_DIR}/include DESTINATION ${CMAKE_SOURCE_DIR}/release)
    install(DIRECTORY ${OpenBLAS_DIR}/bin DESTINATION ${CMAKE_SOURCE_DIR}/release)
  elseif(WHISPERCPP_WITH_CLBLAST)
    file(TO_CMAKE_PATH ${clblast_SOURCE_DIR} clblast_SOURCE_DIR)
    # find the clblast DLLs in the bin directory of the CLBlast installation
    file(GLOB CLBLAST_DLLS "${clblast_SOURCE_DIR}/bin/clblast.dll")
    # if the files cannot be found, abort
    if(NOT CLBLAST_DLLS)
      message(FATAL_ERROR "Could not find CLBlast DLLs in ${clblast_SOURCE_DIR}/bin")
    endif()
    # copy the DLLs to the OBS plugin directory
    install(FILES ${CLBLAST_DLLS} DESTINATION ${CMAKE_SOURCE_DIR}/release/bin)
    install(DIRECTORY ${clblast_SOURCE_DIR}/include ${opencl_sdk_SOURCE_DIR}/include DESTINATION ${CMAKE_SOURCE_DIR}/release)

    file(TO_CMAKE_PATH ${opencl_sdk_SOURCE_DIR} opencl_sdk_SOURCE_DIR)
    # find the opencl SDK DLLs in the bin directory of the OpenCL SDK installation
    file(GLOB OPENCL_SDK_DLLS "${opencl_sdk_SOURCE_DIR}/bin/OpenCL.dll")
    # if the files cannot be found, abort
    if(NOT OPENCL_SDK_DLLS)
      message(FATAL_ERROR "Could not find OpenCL SDK DLLs in ${opencl_sdk_SOURCE_DIR}/bin")
    endif()
    # copy the DLLs to the OBS plugin directory
    install(FILES ${OPENCL_SDK_DLLS} DESTINATION ${CMAKE_SOURCE_DIR}/release/bin)
  else()
    # normalize CUDA path with file(TO_CMAKE_PATH)
    file(TO_CMAKE_PATH ${CUDA_TOOLKIT_ROOT_DIR} CUDA_TOOLKIT_ROOT_DIR)
    # find the CUDA DLLs for cuBLAS in the bin directory of the CUDA installation e.g. cublas64_NN.dll
    file(GLOB CUBLAS_DLLS "${CUDA_TOOLKIT_ROOT_DIR}/bin/cublas64_*.dll")
    # find cublasLt DLL, e.g. cublasLt64_11.dll
    file(GLOB CUBLASLT_DLLS "${CUDA_TOOLKIT_ROOT_DIR}/bin/cublasLt64_*.dll")
    # find cudart DLL, e.g. cudart64_110.dll
    file(GLOB CUDART_DLLS "${CUDA_TOOLKIT_ROOT_DIR}/bin/cudart64_*.dll")
    # if any of the files cannot be found, abort
    if(NOT CUBLAS_DLLS
       OR NOT CUBLASLT_DLLS
       OR NOT CUDART_DLLS)
      message(FATAL_ERROR "Could not find cuBLAS, cuBLASLt or cuDART DLLs in ${CUDA_TOOLKIT_ROOT_DIR}/bin")
    endif()
    # copy the DLLs to the OBS plugin directory
    install(FILES ${CUBLAS_DLLS} ${CUBLASLT_DLLS} ${CUDART_DLLS} DESTINATION ${CMAKE_SOURCE_DIR}/release/bin)
  endif()
else()
  # copy lib/ include/ and bin/ from ${INSTALL_DIR} to the release directory in the root of the project
  install(DIRECTORY ${INSTALL_DIR}/lib DESTINATION ${CMAKE_SOURCE_DIR}/release)
  install(DIRECTORY ${INSTALL_DIR}/include DESTINATION ${CMAKE_SOURCE_DIR}/release)
endif(WIN32)
