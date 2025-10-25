# Build library
add_library(mylib
    mylib.cpp
)

target_include_directories(mylib
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

target_link_libraries(mylib
    PUBLIC
        compiler_flags
)

# Windows-specific settings for DLL export
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    # Generate export header for DLL symbols
    include(GenerateExportHeader)
    generate_export_header(mylib
        EXPORT_FILE_NAME ${CMAKE_SOURCE_DIR}/include/mylib_export.h
    )

    # Set Windows-specific properties
    set_target_properties(mylib PROPERTIES
        WINDOWS_EXPORT_ALL_SYMBOLS ON
        VERSION ${PROJECT_VERSION}
        SOVERSION ${PROJECT_VERSION_MAJOR}
    )
endif()

# Install library
install(TARGETS mylib
    EXPORT MyProjectTargets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
