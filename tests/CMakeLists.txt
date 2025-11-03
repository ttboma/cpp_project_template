# Find Google Test - will use system version or fetch if not found
find_package(GTest)

if(NOT GTest_FOUND)
    message(STATUS "Fetching Google Test...")
    include(FetchContent)
    FetchContent_Declare(
        googletest
        URL https://github.com/google/googletest/archive/refs/tags/v1.14.0.tar.gz
    )
    set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
    FetchContent_MakeAvailable(googletest)
endif()

include(GoogleTest)

# Build test executable
add_executable(my_lib_tests
    test_mylib.cpp
)

target_link_libraries(my_lib_tests
    PRIVATE
        my_lib
        GTest::gtest_main
        compiler_flags
)

# Discover and register tests
gtest_discover_tests(my_lib_tests)
