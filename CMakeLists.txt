# # CMakeLists.txt to build examples from the repository root.
# #
# # Add one or more entries to SELECTED_SAMPLES below to choose the samples to build.
# # If you want to build a sample directly, you can still use the CMakeLists.txt inside
# # that sample directory.

cmake_minimum_required(VERSION 3.19)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

project(Mastering-Cpp-Game-Animations)

include(ExternalProject)
include(CMakeParseArguments)

function(add_sample_sources_to_ide sample_target sample_source_dir)
  file(GLOB_RECURSE sample_ide_sources CONFIGURE_DEPENDS
    "${sample_source_dir}/CMakeLists.txt"
    "${sample_source_dir}/*.c"
    "${sample_source_dir}/*.cc"
    "${sample_source_dir}/*.cpp"
    "${sample_source_dir}/*.cxx"
    "${sample_source_dir}/*.h"
    "${sample_source_dir}/*.hh"
    "${sample_source_dir}/*.hpp"
    "${sample_source_dir}/*.hxx"
    "${sample_source_dir}/*.cmake"
    "${sample_source_dir}/*.frag"
    "${sample_source_dir}/*.vert"
    "${sample_source_dir}/*.glsl"
  )

  if(sample_ide_sources)
    source_group(TREE "${sample_source_dir}" FILES ${sample_ide_sources})
    set_property(TARGET ${sample_target} APPEND PROPERTY SOURCES ${sample_ide_sources})
  endif()
endfunction()

function(build_selected_sample sample_rel_dir)
  set(options WITH_CONFIG WITH_CONTROLS WITH_SDL2 REQUIRES_VULKAN)
  cmake_parse_arguments(SAMPLE "${options}" "" "" ${ARGN})

  set(sample_source_dir "${PROJECT_SOURCE_DIR}/${sample_rel_dir}")
  set(sample_binary_dir "${CMAKE_BINARY_DIR}/${sample_rel_dir}-build")
  set(sample_output_dir "${PROJECT_SOURCE_DIR}/bin/${sample_rel_dir}")
  string(REPLACE "/" "_" sample_target "${sample_rel_dir}")

  if(NOT EXISTS "${sample_source_dir}/CMakeLists.txt")
    message(FATAL_ERROR "Selected sample does not exist: ${sample_rel_dir}")
  endif()

  if(SAMPLE_REQUIRES_VULKAN)
    find_program(VULKANINFO_EXECUTABLE NAMES vulkaninfo${CMAKE_EXECUTABLE_SUFFIX})

    if(NOT VULKANINFO_EXECUTABLE)
      message(FATAL_ERROR "Selected sample requires the Vulkan SDK, but vulkaninfo was not found: ${sample_rel_dir}")
    endif()
  endif()

  set(sample_install_commands
    COMMAND ${CMAKE_COMMAND} -E copy "${sample_binary_dir}/$<CONFIG>/Main${CMAKE_EXECUTABLE_SUFFIX}" "${sample_output_dir}/"
    COMMAND ${CMAKE_COMMAND} -E copy "${sample_binary_dir}/$<CONFIG>/imgui.ini" "${sample_output_dir}/"
    COMMAND ${CMAKE_COMMAND} -E copy_directory "${sample_binary_dir}/$<CONFIG>/assets/" "${sample_output_dir}/assets/"
    COMMAND ${CMAKE_COMMAND} -E copy_directory "${sample_binary_dir}/$<CONFIG>/shader/" "${sample_output_dir}/shader/"
    COMMAND ${CMAKE_COMMAND} -E copy_directory "${sample_binary_dir}/$<CONFIG>/textures/" "${sample_output_dir}/textures/"
  )

  if(SAMPLE_WITH_CONFIG)
    list(APPEND sample_install_commands
      COMMAND ${CMAKE_COMMAND} -E copy_directory "${sample_binary_dir}/$<CONFIG>/config/" "${sample_output_dir}/config/"
    )
  endif()

  if(SAMPLE_WITH_CONTROLS)
    list(APPEND sample_install_commands
      COMMAND ${CMAKE_COMMAND} -E copy "${sample_binary_dir}/$<CONFIG>/controls.txt" "${sample_output_dir}/"
    )
  endif()

  if(SAMPLE_WITH_SDL2)
    list(APPEND sample_install_commands
      COMMAND ${CMAKE_COMMAND} -E copy "${sample_binary_dir}/$<CONFIG>/SDL2.dll" "${sample_output_dir}/"
      COMMAND ${CMAKE_COMMAND} -E copy "${sample_binary_dir}/$<CONFIG>/SDL2_mixer.dll" "${sample_output_dir}/"
    )
  endif()

  message(STATUS "Selected sample: ${sample_rel_dir}")

  ExternalProject_Add(
    ${sample_target}
    PREFIX "${CMAKE_BINARY_DIR}/build-files/${sample_target}"
    SOURCE_DIR "${sample_source_dir}"
    BINARY_DIR "${sample_binary_dir}"
    INSTALL_COMMAND ${CMAKE_COMMAND} -E make_directory "${sample_output_dir}"
    ${sample_install_commands}
    USES_TERMINAL_BUILD true
  )

  add_sample_sources_to_ide(${sample_target} "${sample_source_dir}")

  if(CMAKE_GENERATOR MATCHES "Visual Studio")
    set_target_properties(${sample_target} PROPERTIES
      VS_DEBUGGER_COMMAND "${sample_binary_dir}/$<CONFIG>/Main${CMAKE_EXECUTABLE_SUFFIX}"
      VS_DEBUGGER_WORKING_DIRECTORY "${sample_binary_dir}/$<CONFIG>"
    )
    set_property(DIRECTORY PROPERTY VS_STARTUP_PROJECT ${sample_target})
  endif()
endfunction()

function(configure_sample_from_path sample_rel_dir)
  get_filename_component(sample_chapter_dir "${sample_rel_dir}" DIRECTORY)
  get_filename_component(sample_leaf_dir "${sample_rel_dir}" NAME)

  string(REGEX MATCH "^chapter([0-9][0-9])$" _chapter_match "${sample_chapter_dir}")

  if(NOT _chapter_match)
    message(FATAL_ERROR "Unsupported sample path: ${sample_rel_dir}")
  endif()

  set(sample_chapter_num "${CMAKE_MATCH_1}")

  string(REGEX MATCH "^[0-9][0-9]_(opengl|vulkan)_(.+)$" _sample_match "${sample_leaf_dir}")

  if(NOT _sample_match)
    message(FATAL_ERROR "Unsupported sample directory name: ${sample_rel_dir}")
  endif()

  set(sample_api "${CMAKE_MATCH_1}")

  set(sample_options)

  if(sample_chapter_num GREATER_EQUAL 5)
    list(APPEND sample_options WITH_CONFIG)
  endif()

  if(sample_chapter_num EQUAL 14)
    list(APPEND sample_options WITH_CONTROLS)

    if(WIN32 AND NOT MINGW)
      list(APPEND sample_options WITH_SDL2)
    endif()
  endif()

  if(sample_api STREQUAL "vulkan")
    list(APPEND sample_options REQUIRES_VULKAN)
  endif()

  build_selected_sample("${sample_rel_dir}" ${sample_options})
endfunction()

# Add one or more entries to choose which samples the root build should compile.
# This can also be set from the command line, for example:
# cmake -S . -B build -DSELECTED_SAMPLES="chapter01/01_opengl_assimp;chapter01/02_vulkan_assimp"
if(NOT DEFINED SELECTED_SAMPLES)
  set(SELECTED_SAMPLES
    # "chapter01/01_opengl_assimp"
    "chapter01/02_vulkan_assimp"

    # "chapter02/01_opengl_computeshader"
    # "chapter02/02_vulkan_computeshader"
    # "chapter03/01_opengl_selection"
    # "chapter03/02_vulkan_selection"
    # "chapter04/01_opengl_edit_view_mode"
    # "chapter04/02_vulkan_edit_view_mode"
    # "chapter05/01_opengl_load_save"
    # "chapter05/02_vulkan_load_save"
    # "chapter06/01_opengl_cameras"
    # "chapter06/02_vulkan_cameras"
    # "chapter07/01_opengl_animations"
    # "chapter07/02_vulkan_animations"
    # "chapter08/01_opengl_collisions"
    # "chapter08/02_vulkan_collisions"
    # "chapter09/01_opengl_behavior"
    # "chapter09/02_vulkan_behavior"
    # "chapter10/01_opengl_morphanim"
    # "chapter10/02_vulkan_morphanim"
    # "chapter11/01_opengl_level"
    # "chapter11/02_vulkan_level"
    # "chapter12/01_opengl_adv_collision"
    # "chapter12/02_vulkan_adv_collision"
    # "chapter13/01_opengl_navigation"
    # "chapter13/02_vulkan_navigation"
    # "chapter14/01_opengl_ideas"
    # "chapter14/02_vulkan_ideas"
  )
endif()

# Backward compatibility for older command lines or local edits that still set SELECTED_SAMPLE.
if(DEFINED SELECTED_SAMPLE AND NOT SELECTED_SAMPLE STREQUAL "")
  list(APPEND SELECTED_SAMPLES ${SELECTED_SAMPLE})
endif()

if(NOT SELECTED_SAMPLES)
  message(FATAL_ERROR "No sample selected. Add at least one entry to SELECTED_SAMPLES in the root CMakeLists.txt.")
endif()

list(REMOVE_DUPLICATES SELECTED_SAMPLES)

foreach(selected_sample IN LISTS SELECTED_SAMPLES)
  configure_sample_from_path("${selected_sample}")
endforeach()
