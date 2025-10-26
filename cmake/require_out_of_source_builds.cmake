#------------------------------------------------------------------------------
# requireOutOfSourceBuild()
#
# Ensures that CMake is not being run in a source directory or any directory
# containing a CMakeLists.txt file. If a CMakeLists.txt file is detected in the
# build directory, the function stops configuration with a fatal error and
# instructs the user to use a separate build subdirectory.
#
# Usage:
#   requireOutOfSourceBuild()
#
# Example:
#   # Call this function at the top of your main CMakeLists.txt
#   requireOutOfSourceBuild()
#
#------------------------------------------------------------------------------
function(requireOutOfSourceBuild)
    # Converts a file path to CMake's preferred path format - it normalizes the path separators (e.g., converts backslashes \ to forward slashes / on Windows) - and store the normalized path in the variable `locPath`.
    file(TO_CMAKE_PATH
        "${PROJECT_BINARY_DIR}/CMakeLists.txt" locPath
    )

    if(EXISTS "${locPath}")
        message(FATAL_ERROR "You cannot build in a source directory (or any directory with a CMakeLists.txt file). Please make a build subdirectory. For example, run `cmake . -B build`. Feel free to remove CMakeCache.txt and CMakeFiles.")
    endif()
endfunction()
