# Build library
add_library(my_lib
    my_lib.cpp
)

target_include_directories(my_lib
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

target_link_libraries(my_lib
    PUBLIC
        compiler_flags
)

# Windows-specific settings for DLL export
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    # Generate export header for DLL symbols
    include(GenerateExportHeader)
    generate_export_header(my_lib
        EXPORT_FILE_NAME ${CMAKE_SOURCE_DIR}/include/my_lib_export.h
    )

    # Set Windows-specific properties
    set_target_properties(my_lib PROPERTIES
        WINDOWS_EXPORT_ALL_SYMBOLS ON
        VERSION ${PROJECT_VERSION}
        SOVERSION ${PROJECT_VERSION_MAJOR}
    )
endif()

# Install library
install(TARGETS my_lib
    EXPORT MyProjectTargets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
