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
