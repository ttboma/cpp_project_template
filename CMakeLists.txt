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
include(require_out_of_source_builds)
include(find_dependency)

# Ensures that the project is built outside of the source directory
requireOutOfSourceBuild()

# Specify the C++ standard
# Create an interface library target named "compiler_flags" to hold common
# compiler settings (no actual object code is produced)
add_library(compiler_flags INTERFACE)

# Require C++20 for all targets that link against compiler_flags
target_compile_features(compiler_flags INTERFACE cxx_std_20)

# Add compiler warning flags
# Define generator expressions to detect compiler families
set(gccLikeCxx "$<COMPILE_LANG_AND_ID:CXX,ARMClang,AppleClang,Clang,GNU,LCC>")
set(msvcCxx     "$<COMPILE_LANG_AND_ID:CXX,MSVC>")

# Apply warning options only when building this project (BUILD_INTERFACE)
target_compile_options(compiler_flags INTERFACE
  "$<${gccLikeCxx}:$<BUILD_INTERFACE:-Wall;-Wextra;-Wshadow;-Wformat=2;-Wunused>>"
  "$<${msvcCxx}:$<BUILD_INTERFACE:-W3>>"
)

include(GNUInstallDirs)

# Enable testing for CTest
enable_testing()

# Configure RPATH settings for proper runtime library linking
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

# Platform-specific configurations
if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set(CMAKE_MACOSX_RPATH TRUE)
    set(CMAKE_INSTALL_RPATH "@executable_path/../${CMAKE_INSTALL_LIBDIR}")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(CMAKE_INSTALL_RPATH "$ORIGIN/../${CMAKE_INSTALL_LIBDIR}")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    # On Windows, DLLs are searched in the same directory as the executable
    # or in directories specified by PATH
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

    # For multi-config generators (Visual Studio)
    foreach(CONFIG ${CMAKE_CONFIGURATION_TYPES})
        string(TOUPPER ${CONFIG} CONFIG_UPPER)
        set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_${CONFIG_UPPER} ${CMAKE_BINARY_DIR}/bin/${CONFIG})
        set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_${CONFIG_UPPER} ${CMAKE_BINARY_DIR}/lib/${CONFIG})
        set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${CONFIG_UPPER} ${CMAKE_BINARY_DIR}/lib/${CONFIG})
    endforeach()
endif()

# Add subdirectories
add_subdirectory(src)
add_subdirectory(bin)
add_subdirectory(tests)
add_subdirectory(docs)
