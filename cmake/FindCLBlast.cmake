# Assume the library is called libCLBlast.a and the headers are in 'include'
find_path(CLBlast_INCLUDE_DIR NAMES clblast.h
          PATHS ${clblast_SOURCE_DIR}/include)

find_library(CLBlast_LIBRARY NAMES clblast
             PATHS ${clblast_SOURCE_DIR}/lib)

# find opencl sdk includes
find_path(OPENCL_INCLUDE_DIR NAMES CL/opencl.h
          PATHS ${opencl_sdk_SOURCE_DIR}/include)

# find opencl sdk libraries
find_library(OPENCL_LIBRARY NAMES OpenCL
             PATHS ${opencl_sdk_SOURCE_DIR}/lib)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(CLBlast DEFAULT_MSG
                                  CLBlast_LIBRARY CLBlast_INCLUDE_DIR)

if(CLBlast_FOUND AND NOT TARGET clbast)
  add_library(clbast::clblast STATIC IMPORTED)
  set_target_properties(clbast::clblast PROPERTIES
                        IMPORTED_LOCATION "${CLBlast_LIBRARY}"
                        INTERFACE_INCLUDE_DIRECTORIES "${CLBlast_INCLUDE_DIR}")
  # add opencl library
  add_library(opencl STATIC IMPORTED)
  set_target_properties(opencl PROPERTIES
                        IMPORTED_LOCATION "${OPENCL_LIBRARY}"
                        INTERFACE_INCLUDE_DIRECTORIES "${OPENCL_INCLUDE_DIR}")

  # add clblast as an interface for clbast::clblast and opencl both
  add_library(clblast INTERFACE)
  target_link_libraries(clblast INTERFACE clbast::clblast opencl)

  # find the library dir and store in CLBlast_LIBRARY_DIR
  get_filename_component(CLBlast_LIBRARY_DIR ${CLBlast_LIBRARY} DIRECTORY)
  get_filename_component(OpenCL_LIBRARY_DIR ${OPENCL_LIBRARY} DIRECTORY)

  # Add to include directories
  include_directories(${CLBlast_INCLUDE_DIR} ${OPENCL_INCLUDE_DIR})
  # add the link directories
  link_directories(${CLBlast_LIBRARY_DIR} ${OpenCL_LIBRARY_DIR})
endif()
