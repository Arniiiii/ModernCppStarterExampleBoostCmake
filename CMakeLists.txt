cmake_minimum_required(VERSION 3.14...3.22)

# ---- Project ----

# Note: update this to your new project's name and version
project(
  Greeter
  VERSION 1.0
  LANGUAGES CXX
)

# ---- Include guards ----

if(PROJECT_SOURCE_DIR STREQUAL PROJECT_BINARY_DIR)
  message(
    FATAL_ERROR
      "In-source builds not allowed. Please make a new directory (called a build directory) and run CMake from there."
  )
endif()

# ---- Add dependencies via CPM ----
# see https://github.com/TheLartians/CPM.cmake for more info

include(cmake/CPM.cmake)

# PackageProject.cmake will be used to make our target installable
CPMAddPackage("gh:TheLartians/PackageProject.cmake@1.8.0")

set(TRY_BOOST_VERSION "1.84.0")
set(BOOST_NOT_HEADER_ONLY_COMPONENTS_THAT_YOU_NEED "thread")
set(BOOST_HEADER_ONLY_COMPONENTS_THAT_YOU_NEED "asio")

option(BUILD_SHARED_LIBS "yes/no" YES)

set(IS_BOOST_LOCAL OFF)
if(${CPM_LOCAL_PACKAGES_ONLY})
  message(STATUS "Trying to find Boost...")
  find_package(
    Boost ${TRY_BOOST_VERSION} REQUIRED
    COMPONENTS ${BOOST_NOT_HEADER_ONLY_COMPONENTS_THAT_YOU_NEED}
  )
  set(IS_BOOST_LOCAL ON)
elseif(${CPM_USE_LOCAL_PACKAGES} OR NOT ${CPM_DOWNLOAD_ALL})
  message(STATUS "Trying to use local Boost...")
  find_package(
    Boost ${TRY_BOOST_VERSION} COMPONENTS ${BOOST_NOT_HEADER_ONLY_COMPONENTS_THAT_YOU_NEED}
  )
  if(${BOOST_FOUND})
    set(IS_BOOST_LOCAL ON)
    message(DEBUG "boost include dir: ${Boost_INCLUDE_DIRS}")
  endif()
endif()

if(NOT (${BOOST_FOUND}) OR (NOT DEFINED BOOST_FOUND))
  message(STATUS "Trying to download Boost...")
  set(BOOST_INCLUDE_LIBRARIES
      "${BOOST_NOT_HEADER_ONLY_COMPONENTS_THAT_YOU_NEED};${BOOST_HEADER_ONLY_COMPONENTS_THAT_YOU_NEED}"
  )
  set(__boost_include_libraries "")

  find_package(Patch REQUIRED)

  # set(PATCH_COMMAND_ARGS " -rnN ")
  set(PATCH_COMMAND_ARGS "")
  # set(PATCH_COMMAND_SOURCE " -d " )
  # set(PATCH_COMMAND_INPUT_PATCHES " -i ")
  # file(GLOB_RECURSE patches_for_boost CONFIGURE_DEPENDS
  #      "${CMAKE_CURRENT_SOURCE_DIR}/patches/boost/*.patch"
  # )
  # set(PATCH_COMMAND_FOR_CPM_BASE "${Patch_EXECUTABLE} ${PATCH_COMMAND_ARGS} < ")
  # set(PATCH_COMMAND_FOR_CPM "")
  # foreach(patch_filename IN LISTS patches_for_boost)
  #     string(APPEND PATCH_COMMAND_FOR_CPM "${PATCH_COMMAND_FOR_CPM_BASE}
  #     ${patch_filename} \n")
  # endforeach()
  # message(DEBUG "Patch command: ${PATCH_COMMAND_FOR_CPM}")
  CPMAddPackage(
    NAME Boost
    URL "https://github.com/boostorg/boost/releases/download/boost-${TRY_BOOST_VERSION}/boost-${TRY_BOOST_VERSION}.tar.xz"
    OPTIONS "BOOST_ENABLE_CMAKE ON" 
    PATCH_COMMAND "${Patch_EXECUTABLE}" ${PATCH_COMMAND_ARGS} -p1 < "${CMAKE_CURRENT_SOURCE_DIR}/patches/boost/boost_cmake_enable_install_rules_for_add_subdirectory_case.patch"
"${Patch_EXECUTABLE}" ${PATCH_COMMAND_ARGS} -p1 < "${CMAKE_CURRENT_SOURCE_DIR}/patches/boost/boost_cmake_give_all_boost_deps_please.patch"
  )
  set(IS_BOOST_LOCAL OFF)
endif()

# CPMAddPackage( NAME fmt GIT_TAG 9.1.0 GITHUB_REPOSITORY fmtlib/fmt OPTIONS "FMT_INSTALL YES" #
# create an installable target )

# ---- Add source files ----

# Note: globbing sources is considered bad practice as CMake's generators may not detect new files
# automatically. Keep that in mind when changing files, or explicitly mention them here.
file(GLOB_RECURSE headers CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/include/*.hpp")
file(GLOB_RECURSE sources CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/source/*.cpp")

# ---- Create library ----

# Note: for header-only libraries change all PUBLIC flags to INTERFACE and create an interface
# target: add_library(${PROJECT_NAME} INTERFACE)
add_library(${PROJECT_NAME} ${headers} ${sources})
set_target_properties(${PROJECT_NAME} PROPERTIES CXX_STANDARD 17)

# being a cross-platform target, we enforce standards conformance on MSVC
target_compile_options(${PROJECT_NAME} PUBLIC "$<$<COMPILE_LANG_AND_ID:CXX,MSVC>:/permissive->")

# Link dependencies target_link_libraries(${PROJECT_NAME} PRIVATE fmt::fmt)
if(${IS_BOOST_LOCAL})
  target_link_libraries(${PROJECT_NAME} PUBLIC Boost::boost)
else()
  target_link_libraries(${PROJECT_NAME} PUBLIC Boost::asio)
endif()
target_link_libraries(${PROJECT_NAME} PUBLIC Boost::thread)

target_include_directories(
  ${PROJECT_NAME} PUBLIC $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
                         $<INSTALL_INTERFACE:include/${PROJECT_NAME}-${PROJECT_VERSION}>
)

# ---- Create an installable target ----
# this allows users to install and find the library via `find_package()`.

# the location where the project's version header will be placed should match the project's regular
# header paths
string(TOLOWER ${PROJECT_NAME}/version.h VERSION_HEADER_LOCATION)

packageProject(
  NAME ${PROJECT_NAME}
  VERSION ${PROJECT_VERSION}
  NAMESPACE ${PROJECT_NAME}
  BINARY_DIR ${PROJECT_BINARY_DIR}
  INCLUDE_DIR ${PROJECT_SOURCE_DIR}/include
  INCLUDE_DESTINATION include/${PROJECT_NAME}-${PROJECT_VERSION}
  VERSION_HEADER "${VERSION_HEADER_LOCATION}"
  COMPATIBILITY SameMajorVersion
  DEPENDENCIES "Boost 1.84.0" # "boost_asio" "boost_thread"
)
#
# message("Boost include libraries: ${__boost_include_libraries}")
# set(__${PROJECT_NAME}__boost_dependencies "") foreach(a_lib_with_maybe_slash
# ${__boost_include_libraries}) set(a_lib ${a_lib_with_maybe_slash}) string(REPLACE "/" "_" a_lib
# ${a_lib}) message("boost lib: boost_"${a_lib}) list(APPEND __${PROJECT_NAME}__boost_dependencies
# "boost_${a_lib}") endforeach()
#
# message("Boost libs with boost__ : ${__${PROJECT_NAME}__boost_dependencies}")
#
# install( TARGETS ${target_name} ${__${PROJECT_NAME}__boost_dependencies} RUNTIME DESTINATION bin #
# Destination for executables LIBRARY DESTINATION lib64 # Destination for shared libraries ARCHIVE
# DESTINATION lib64 # Destination for static libraries (if any) PRIVATE_HEADER DESTINATION include
# PUBLIC_HEADER DESTINATION include )
