# Locate the Open Asset Importer Library - assimp
#
# This module defines the following variables:
#
# ASSIMP_LIBRARY the assimp library target or file path
# ASSIMP_ZLIB_LIBRARY optional zlib dependency used by some static assimp builds
# ASSIMP_INCLUDE_DIR where to find Assimp include files.
# ASSIMP_FOUND true if assimp has been found.
#
# To help locate the library and include file, you can define a
# variable called ASSIMP_ROOT (or environment variable ASSIMP_ROOT)
# which points to the root of the Assimp installation.
#
# Cmake file from: https://github.com/daw42/glslcookbook

set(_assimp_HEADER_SEARCH_DIRS
  "/usr/include"
  "/usr/local/include"
  "${CMAKE_SOURCE_DIR}/includes"
  "C:/Program Files/assimp/include"
)

set(_assimp_LIB_SEARCH_DIRS
  "/usr/lib"
  "/usr/local/lib"
  "${CMAKE_SOURCE_DIR}/lib"
  "C:/Program Files/assimp/lib"
)

# Check environment for root search directory
set(_assimp_ENV_ROOT $ENV{ASSIMP_ROOT})
if(NOT ASSIMP_ROOT AND _assimp_ENV_ROOT)
  set(ASSIMP_ROOT ${_assimp_ENV_ROOT})
endif()

# Put user specified location at beginning of search
if(ASSIMP_ROOT)
  list(INSERT _assimp_HEADER_SEARCH_DIRS 0 "${ASSIMP_ROOT}/include")
  list(INSERT _assimp_LIB_SEARCH_DIRS 0 "${ASSIMP_ROOT}/lib")
endif()

# Search local/system installs first
find_path(ASSIMP_INCLUDE_DIR assimp/Importer.hpp
  PATHS ${_assimp_HEADER_SEARCH_DIRS}
)

find_library(ASSIMP_LIBRARY NAMES assimp
  PATHS ${_assimp_LIB_SEARCH_DIRS}
)

find_library(ASSIMP_ZLIB_LIBRARY NAMES zlibstatic libz z
  PATHS ${_assimp_LIB_SEARCH_DIRS}
)

# Fallback: fetch assimp once in a shared repo folder and reuse across chapters.
if(NOT ASSIMP_LIBRARY OR NOT ASSIMP_INCLUDE_DIR)
  include(FetchContent)

  # Shared source cache for all chapter projects in this repository.
  set(_assimp_repo_root "${CMAKE_SOURCE_DIR}/../..")
  set(_assimp_shared_src "${_assimp_repo_root}/.deps/assimp-src")

  # Configure assimp build options before adding source tree.
  set(ASSIMP_BUILD_TESTS OFF CACHE BOOL "" FORCE)
  set(ASSIMP_NO_EXPORT ON CACHE BOOL "" FORCE)
  set(ASSIMP_INSTALL OFF CACHE BOOL "" FORCE)
  set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)

  # Only fetch from network the first time the shared source is missing.
  if(NOT EXISTS "${_assimp_shared_src}/CMakeLists.txt")
    FetchContent_Declare(
      assimp_fetch
      GIT_REPOSITORY https://github.com/assimp/assimp
      GIT_TAG        v6.0.2
      GIT_SHALLOW    1
      SOURCE_DIR     "${_assimp_shared_src}"
    )
    FetchContent_Populate(assimp_fetch)
  endif()

  # Build from shared source with a chapter-local binary dir.
  if(NOT TARGET assimp AND NOT TARGET assimp::assimp)
    add_subdirectory("${_assimp_shared_src}" "${CMAKE_BINARY_DIR}/_deps/fetchcontent/assimp-build" EXCLUDE_FROM_ALL)
  endif()

  if(TARGET assimp::assimp)
    set(ASSIMP_LIBRARY assimp::assimp)
    get_target_property(ASSIMP_INCLUDE_DIR assimp::assimp INTERFACE_INCLUDE_DIRECTORIES)
    # Target-based linking carries transitive dependencies.
    set(ASSIMP_ZLIB_LIBRARY "")
  elseif(TARGET assimp)
    set(ASSIMP_LIBRARY assimp)
    get_target_property(ASSIMP_INCLUDE_DIR assimp INTERFACE_INCLUDE_DIRECTORIES)
    set(ASSIMP_ZLIB_LIBRARY "")
  endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(assimp DEFAULT_MSG ASSIMP_LIBRARY ASSIMP_INCLUDE_DIR)
