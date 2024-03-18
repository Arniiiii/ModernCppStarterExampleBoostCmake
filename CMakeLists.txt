cmake_minimum_required(VERSION 3.14...3.22)

# ---- Project ----

# Note: update this to your new project's name and version
project(
  Greeter
  VERSION 1.1
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
find_package(Patch REQUIRED)

set(PATCH_COMMAND_ARGS "-rnN")

file(GLOB_RECURSE patches_for_boost CONFIGURE_DEPENDS
     "${CMAKE_CURRENT_SOURCE_DIR}/patches/packageProject/*.patch"
)

set(PATCH_COMMAND_FOR_CPM_BASE "${Patch_EXECUTABLE}" ${PATCH_COMMAND_ARGS} -p1 <)

set(PATCH_COMMAND_FOR_CPM "")
foreach(patch_filename IN LISTS patches_for_boost)
  list(APPEND PATCH_COMMAND_FOR_CPM ${PATCH_COMMAND_FOR_CPM_BASE})
  list(APPEND PATCH_COMMAND_FOR_CPM ${patch_filename})
  list(APPEND PATCH_COMMAND_FOR_CPM &&)
endforeach()
list(POP_BACK PATCH_COMMAND_FOR_CPM)

message(DEBUG "Patch command: ${PATCH_COMMAND_FOR_CPM}")
CPMAddPackage(
  NAME PackageProject
  VERSION 1.11.2
  GIT_REPOSITORY "https://github.com/TheLartians/PackageProject.cmake.git" PATCH_COMMAND
                                                                           ${PATCH_COMMAND_FOR_CPM}
)

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

  set(PATCH_COMMAND_ARGS "-rnN")

  file(GLOB_RECURSE patches_for_boost CONFIGURE_DEPENDS
       "${CMAKE_CURRENT_SOURCE_DIR}/patches/boost/*.patch"
  )

  set(PATCH_COMMAND_FOR_CPM_BASE "${Patch_EXECUTABLE}" ${PATCH_COMMAND_ARGS} -p1 <)

  set(PATCH_COMMAND_FOR_CPM "")
  foreach(patch_filename IN LISTS patches_for_boost)
    list(APPEND PATCH_COMMAND_FOR_CPM ${PATCH_COMMAND_FOR_CPM_BASE})
    list(APPEND PATCH_COMMAND_FOR_CPM ${patch_filename})
    list(APPEND PATCH_COMMAND_FOR_CPM &&)
  endforeach()
  list(POP_BACK PATCH_COMMAND_FOR_CPM)

  message(DEBUG "Patch command: ${PATCH_COMMAND_FOR_CPM}")

  CPMAddPackage(
    NAME Boost
    URL "https://github.com/boostorg/boost/releases/download/boost-${TRY_BOOST_VERSION}/boost-${TRY_BOOST_VERSION}.tar.xz"
        PATCH_COMMAND ${PATCH_COMMAND_FOR_CPM}
    OPTIONS "BOOST_ENABLE_CMAKE ON"
  )

  set(IS_BOOST_LOCAL OFF)
endif()

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
  foreach(a_lib ${BOOST_HEADER_ONLY_COMPONENTS_THAT_YOU_NEED})
    target_link_libraries(${PROJECT_NAME} PUBLIC Boost::${a_lib})
  endforeach()
endif()

foreach(a_lib ${BOOST_NOT_HEADER_ONLY_COMPONENTS_THAT_YOU_NEED})
  target_link_libraries(${PROJECT_NAME} PUBLIC Boost::${a_lib})
endforeach()

target_include_directories(
  ${PROJECT_NAME} PUBLIC $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
                         $<INSTALL_INTERFACE:include/${PROJECT_NAME}-${PROJECT_VERSION}>
)

# ---- Create an installable target ----
# this allows users to install and find the library via `find_package()`.

# the location where the project's version header will be placed should match the project's regular
# header paths
string(TOLOWER ${PROJECT_NAME}/version.h VERSION_HEADER_LOCATION)

set_property(TARGET ${PROJECT_NAME} PROPERTY VERSION ${PROJECT_VERSION})
set_property(TARGET ${PROJECT_NAME} PROPERTY SOVERSION 1)

packageProject(
  NAME ${PROJECT_NAME}
  VERSION ${PROJECT_VERSION}
  NAMESPACE ${PROJECT_NAME}
  BINARY_DIR ${PROJECT_BINARY_DIR}
  INCLUDE_DIR ${PROJECT_SOURCE_DIR}/include
  INCLUDE_DESTINATION include/${PROJECT_NAME}
  VERSION_HEADER "${VERSION_HEADER_LOCATION}"
  COMPATIBILITY "AnyNewerVersion" DISABLE_VERSION_SUFFIX ON
  DEPENDENCIES "Boost 1.84.0"
)
