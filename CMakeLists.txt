cmake_minimum_required(VERSION 3.14...3.22)

# ---- Project ----

# Note: update this to your new project's name and version
project(
  Greeter
  VERSION 1.2
  LANGUAGES CXX
)

set(FETCHCONTENT_QUIET
    OFF
    CACHE BOOL "Make downloading of packages quiet"
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

include(cmake/getCPM.cmake)

# # PackageProject.cmake will be used to make our target installable find_package(Patch REQUIRED)
#
# set(PATCH_COMMAND_ARGS "-rnN")
#
file(GLOB_RECURSE patches_for_package_project CONFIGURE_DEPENDS
     "${CMAKE_CURRENT_SOURCE_DIR}/patches/packageProject/*.patch"
)
message(DEBUG "patches_for_package_project ${patches_for_package_project}")

# set(PATCH_COMMAND_FOR_CPM_BASE "${Patch_EXECUTABLE}" ${PATCH_COMMAND_ARGS} -p1 <)
#
# set(PATCH_COMMAND_FOR_CPM "") foreach(patch_filename IN LISTS patches_for_package_project)
# list(APPEND PATCH_COMMAND_FOR_CPM ${PATCH_COMMAND_FOR_CPM_BASE}) list(APPEND PATCH_COMMAND_FOR_CPM
# ${patch_filename}) list(APPEND PATCH_COMMAND_FOR_CPM &&) endforeach() list(POP_BACK
# PATCH_COMMAND_FOR_CPM)
#
# message(DEBUG "Patch command: ${PATCH_COMMAND_FOR_CPM}")
CPMAddPackage(
  NAME PackageProject
  VERSION 1.11.2
  GIT_REPOSITORY "https://github.com/TheLartians/PackageProject.cmake.git"
                 PATCHES ${patches_for_package_project}
)

set(TRY_BOOST_VERSION "1.85.0")
set(BOOST_NOT_HEADER_ONLY_COMPONENTS_THAT_YOU_NEED "thread")
set(BOOST_HEADER_ONLY_COMPONENTS_THAT_YOU_NEED "asio")

option(BUILD_SHARED_LIBS "yes/no" YES)

include(${CMAKE_CURRENT_LIST_DIR}/cmake/packages/addboost.cmake)

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

# Link dependencies
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
  DEPENDENCIES "Boost 1.85.0"
)
