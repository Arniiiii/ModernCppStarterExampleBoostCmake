CPMFindPackage(
  NAME simdjson
  VERSION ${TRY_SIMDJSON_VERSION}
  URL https://github.com/simdjson/simdjson/archive/refs/tags/v${TRY_SIMDJSON_VERSION}.tar.gz
  OPTIONS "SIMDJSON_BUILD_STATIC_LIB ON" "SIMDJSON_ENABLE_THREADS ON"
          "SIMDJSON_IMPLEMENTATION westmere\\\;haswell\\\;icelake"
)

if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  target_compile_options(simdjson_static PRIVATE -fPIC)
endif()
