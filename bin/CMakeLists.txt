# Build executable
add_executable(myapp
    main.cpp
)

target_link_libraries(myapp
    PRIVATE
        mylib
        compiler_flags
)

# Set RPATH for the executable
set_target_properties(myapp PROPERTIES
    BUILD_RPATH_USE_ORIGIN TRUE
    INSTALL_RPATH_USE_LINK_PATH TRUE
)

# Install executable
install(TARGETS myapp
    DESTINATION ${CMAKE_INSTALL_BINDIR}
)
