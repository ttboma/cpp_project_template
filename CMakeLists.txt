cmake_minimum_required(VERSION 3.25)

# Generate compile_commands.json for clang-tidy
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Set the project name and version
project(
  MyProject
  VERSION     1.0.0
  DESCRIPTION "Modern C++ Project Template"
  LANGUAGES   CXX
)

# Including custom cmake utilities
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
include(RequireOutOfSourceBuilds)
include(FindDependency)

# Ensures that the project is built outside of the source directory
require_out_of_source_build()

# Specify the C++ standard
# Create an interface library target named "compiler_flags" to hold common
# compiler settings (no actual object code is produced)
add_library(compiler_flags INTERFACE)

# Require C++20 for all targets that link against compiler_flags
target_compile_features(compiler_flags INTERFACE cxx_std_20)

# Add compiler warning flags
# Define generator expressions to detect compiler families
set(gcc_like_cxx "$<COMPILE_LANG_AND_ID:CXX,ARMClang,AppleClang,Clang,GNU,LCC>")
set(msvc_cxx     "$<COMPILE_LANG_AND_ID:CXX,MSVC>")

# Apply warning options only when building this project (BUILD_INTERFACE)
target_compile_options(compiler_flags INTERFACE
  "$<${gcc_like_cxx}:$<BUILD_INTERFACE:-Wall;-Wextra;-Wshadow;-Wformat=2;-Wunused>>"
  "$<${msvc_cxx}:$<BUILD_INTERFACE:-W3>>"
)

include(GNUInstallDirs)

# Configure RPATH settings for proper runtime library linking
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
set(CMAKE_MACOSX_RPATH TRUE)

# Set RPATH for installed binaries to find libraries in the same installation
if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set(CMAKE_INSTALL_RPATH "@executable_path/../${CMAKE_INSTALL_LIBDIR}")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(CMAKE_INSTALL_RPATH "$ORIGIN/../${CMAKE_INSTALL_LIBDIR}")
endif()

# Add subdirectories
add_subdirectory(src)
add_subdirectory(bin)
add_subdirectory(tests)
add_subdirectory(docs)
