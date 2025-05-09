cmake_minimum_required(VERSION 3.21)

project(raylib-examples VERSION 0.1 LANGUAGES C CXX)

set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_COLOR_MAKEFILE ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Tell raylib's config script to look for shared libraries
set(raylib_USE_STATIC_LIBS OFF CACHE BOOL "Use static raylib libraries")

# Find raylib (assumes it's installed via Homebrew or system package)
find_package(raylib REQUIRED)

# Common compile flags
add_library(common_compile_options INTERFACE)
target_compile_options(common_compile_options INTERFACE
  $<$<CONFIG:Debug>:-Wall;-Wextra;-Wunused-parameter;-g;-fno-omit-frame-pointer;-funwind-tables>
  $<$<CONFIG:Release>:-O2;-DNDEBUG>
)

# Default to examples/main.c unless overridden via -DEXEC_SOURCE
if(NOT DEFINED EXEC_SOURCE)
  set(EXEC_SOURCE "examples/main.c")
endif()

get_filename_component(EXEC_NAME "${EXEC_SOURCE}" NAME_WE)

add_executable(${EXEC_NAME} ${EXEC_SOURCE})
target_link_libraries(${EXEC_NAME} PRIVATE raylib common_compile_options)

# macOS framework linking (required for raylib)
if (APPLE)
  target_link_libraries(${EXEC_NAME} PRIVATE
    "-framework IOKit"
    "-framework Cocoa"
    "-framework OpenGL"
  )
endif()

# Ensure output is placed directly in build-$CONFIG/
set_target_properties(${EXEC_NAME} PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
)
