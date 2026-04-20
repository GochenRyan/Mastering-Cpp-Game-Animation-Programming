# # CMakeLists.txt to build a single example from the repository root.
# #
# # Uncomment exactly one SELECTED_SAMPLE line below to choose the sample to build.
# # If you want to build a sample directly, you can still use the CMakeLists.txt inside
# # that sample directory.

cmake_minimum_required(VERSION 3.19)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

project(Mastering-Cpp-Game-Animations)

include(ExternalProject)
include(CMakeParseArguments)

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

# Uncomment exactly one line to choose which sample the root build should compile.
# set(SELECTED_SAMPLE "chapter01/01_opengl_assimp")
set(SELECTED_SAMPLE "chapter01/02_vulkan_assimp")

# set(SELECTED_SAMPLE "chapter02/01_opengl_computeshader")
# set(SELECTED_SAMPLE "chapter02/02_vulkan_computeshader")
# set(SELECTED_SAMPLE "chapter03/01_opengl_selection")
# set(SELECTED_SAMPLE "chapter03/02_vulkan_selection")
# set(SELECTED_SAMPLE "chapter04/01_opengl_edit_view_mode")
# set(SELECTED_SAMPLE "chapter04/02_vulkan_edit_view_mode")
# set(SELECTED_SAMPLE "chapter05/01_opengl_load_save")
# set(SELECTED_SAMPLE "chapter05/02_vulkan_load_save")
# set(SELECTED_SAMPLE "chapter06/01_opengl_cameras")
# set(SELECTED_SAMPLE "chapter06/02_vulkan_cameras")
# set(SELECTED_SAMPLE "chapter07/01_opengl_animations")
# set(SELECTED_SAMPLE "chapter07/02_vulkan_animations")
# set(SELECTED_SAMPLE "chapter08/01_opengl_collisions")
# set(SELECTED_SAMPLE "chapter08/02_vulkan_collisions")
# set(SELECTED_SAMPLE "chapter09/01_opengl_behavior")
# set(SELECTED_SAMPLE "chapter09/02_vulkan_behavior")
# set(SELECTED_SAMPLE "chapter10/01_opengl_morphanim")
# set(SELECTED_SAMPLE "chapter10/02_vulkan_morphanim")
# set(SELECTED_SAMPLE "chapter11/01_opengl_level")
# set(SELECTED_SAMPLE "chapter11/02_vulkan_level")
# set(SELECTED_SAMPLE "chapter12/01_opengl_adv_collision")
# set(SELECTED_SAMPLE "chapter12/02_vulkan_adv_collision")
# set(SELECTED_SAMPLE "chapter13/01_opengl_navigation")
# set(SELECTED_SAMPLE "chapter13/02_vulkan_navigation")
# set(SELECTED_SAMPLE "chapter14/01_opengl_ideas")
# set(SELECTED_SAMPLE "chapter14/02_vulkan_ideas")
if(NOT DEFINED SELECTED_SAMPLE OR SELECTED_SAMPLE STREQUAL "")
  message(FATAL_ERROR "No sample selected. Uncomment one SELECTED_SAMPLE line in the root CMakeLists.txt.")
endif()

configure_sample_from_path("${SELECTED_SAMPLE}")
