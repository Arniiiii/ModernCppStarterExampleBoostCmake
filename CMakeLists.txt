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
  find_package(Boost ${TRY_BOOST_VERSION} REQUIRED COMPONENTS
    ${BOOST_NOT_HEADER_ONLY_COMPONENTS_THAT_YOU_NEED})
  set(IS_BOOST_LOCAL ON)
elseif(${CPM_USE_LOCAL_PACKAGES} OR NOT ${CPM_DOWNLOAD_ALL})
  message(STATUS "Trying to use local Boost...")
  find_package(Boost ${TRY_BOOST_VERSION} COMPONENTS ${BOOST_NOT_HEADER_ONLY_COMPONENTS_THAT_YOU_NEED})
  if(${BOOST_FOUND})
    set(IS_BOOST_LOCAL ON)
    message(DEBUG "boost include dir: ${Boost_INCLUDE_DIRS}")
  endif()
endif()

if(NOT (${BOOST_FOUND}) OR (NOT DEFINED BOOST_FOUND))
  message(STATUS "Trying to download Boost...")
  set(BOOST_INCLUDE_LIBRARIES
    "${BOOST_NOT_HEADER_ONLY_COMPONENTS_THAT_YOU_NEED};${BOOST_HEADER_ONLY_COMPONENTS_THAT_YOU_NEED}")
  CPMAddPackage(
    NAME Boost
    URL
    "https://github.com/boostorg/boost/releases/download/boost-${TRY_BOOST_VERSION}/boost-${TRY_BOOST_VERSION}.tar.xz"
    DOWNLOAD_ONLY YES
  )
  message(DEBUG "It's gonna execute next: patch -rnN -p1 -d ${Boost_SOURCE_DIR} -i ${CMAKE_CURRENT_SOURCE_DIR}/patches/boost/boost_cmake_enable_install_rules_for_add_subdirectory_case.patch  ")
  execute_process(COMMAND patch -rnN -p1 -d ${Boost_SOURCE_DIR} -i ${CMAKE_CURRENT_SOURCE_DIR}/patches/boost/boost_cmake_enable_install_rules_for_add_subdirectory_case.patch  ) # -N is essential. it won't allow patch twice.
  add_subdirectory(${Boost_SOURCE_DIR} ${Boost_BINARY_DIR} SYSTEM EXCLUDE_FROM_ALL)
  set(IS_BOOST_LOCAL OFF)
endif()



# CPMAddPackage(
#   NAME fmt
#   GIT_TAG 9.1.0
#   GITHUB_REPOSITORY fmtlib/fmt
#   OPTIONS "FMT_INSTALL YES" # create an installable target
# )

# ---- Add source files ----

# Note: globbing sources is considered bad practice as CMake's generators may not detect new files
# automatically. Keep that in mind when changing files, or explicitly mention them here.
file(GLOB_RECURSE headers CONFIGURE_DEPENDS
  "${CMAKE_CURRENT_SOURCE_DIR}/include/*.hpp")
file(GLOB_RECURSE sources CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/source/*.cpp")

# ---- Create library ----

# Note: for header-only libraries change all PUBLIC flags to INTERFACE and create an interface
# target: add_library(${PROJECT_NAME} INTERFACE)
add_library(${PROJECT_NAME} ${headers} ${sources})
set_target_properties(${PROJECT_NAME} PROPERTIES CXX_STANDARD 17)

# being a cross-platform target, we enforce standards conformance on MSVC
target_compile_options(${PROJECT_NAME} PUBLIC "$<$<COMPILE_LANG_AND_ID:CXX,MSVC>:/permissive->")

# Link dependencies
# target_link_libraries(${PROJECT_NAME} PRIVATE fmt::fmt)
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
  DEPENDENCIES "Boost 1.84.0"
)
