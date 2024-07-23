# PackageProject.cmake will be used to make our target installable
file(GLOB_RECURSE patches_for_boost CONFIGURE_DEPENDS
     "${CMAKE_CURRENT_SOURCE_DIR}/patches/packageProject.cmake/*.patch"
)

CPMAddPackage(
  NAME PackageProject.cmake
  VERSION 1.11.2
  GIT_REPOSITORY "https://github.com/TheLartians/PackageProject.cmake.git" PATCHES
                                                                           ${patches_for_boost}
)
