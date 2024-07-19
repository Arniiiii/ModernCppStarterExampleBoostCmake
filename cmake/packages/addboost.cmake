function(SUBDIRLIST result_var curdir)
  file(
    GLOB children
    RELATIVE ${curdir}
    ${curdir}/*
  )
  set(result "")
  foreach(child ${children})
    if(IS_DIRECTORY ${curdir}/${child})
      list(APPEND result ${child})
    endif()
  endforeach()
  set(${result_var}
      ${result}
      PARENT_SCOPE
  )
endfunction()

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

  set(BOOST_URL
      "https://github.com/boostorg/boost/releases/download/boost-${TRY_BOOST_VERSION}/boost-${TRY_BOOST_VERSION}-cmake.tar.xz"
  )
  if(${TRY_BOOST_VERSION} STRLESS "1.85.0")
    set(BOOST_URL
        "https://github.com/boostorg/boost/releases/download/boost-${TRY_BOOST_VERSION}/boost-${TRY_BOOST_VERSION}.tar.xz"
    )
  endif()

  set(patches_for_boost "")

  file(GLOB global_patches_for_boost CONFIGURE_DEPENDS
       "${CMAKE_CURRENT_SOURCE_DIR}/patches/boost/*.patch"
  )
  list(APPEND patches_for_boost ${global_patches_for_boost})

  subdirlist(subdirs_boost_patches "${CMAKE_CURRENT_SOURCE_DIR}/patches/boost")
  if(subdirs_boost_patches)
    foreach(subdir ${subdirs_boost_patches})
      if(${subdir} STREQUAL ${TRY_BOOST_VERSION})
        file(GLOB_RECURSE patches_with_max_applicable_version_up_to CONFIGURE_DEPENDS
             "${CMAKE_CURRENT_SOURCE_DIR}/patches/boost/${subdir}/*.patch"
        )
        list(APPEND patches_for_boost ${patches_with_max_applicable_version_up_to})
      endif()
    endforeach()
  endif()

  if(patches_for_boost)
    find_package(Patch REQUIRED)
    set(PATCH_COMMAND_ARGS "-rnN")
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
      URL ${BOOST_URL} PATCH_COMMAND ${PATCH_COMMAND_FOR_CPM}
      OPTIONS "BOOST_ENABLE_CMAKE ON" "BOOST_SKIP_INSTALL_RULES OFF"
    )
  else()
    CPMAddPackage(
      NAME Boost
      URL ${BOOST_URL}
      OPTIONS "BOOST_SKIP_INSTALL_RULES OFF"
    )
  endif()

  set(IS_BOOST_LOCAL OFF)
endif()
