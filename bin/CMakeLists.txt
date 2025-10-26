# Build executable
add_executable(my_app
    main.cpp
)

target_link_libraries(my_app
    PRIVATE
        my_lib
        compiler_flags
)

# Set RPATH for the executable
set_target_properties(my_app PROPERTIES
    BUILD_RPATH_USE_ORIGIN TRUE
    INSTALL_RPATH_USE_LINK_PATH TRUE
)

# Install executable
install(TARGETS my_app
    DESTINATION ${CMAKE_INSTALL_BINDIR}
)
