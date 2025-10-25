@echo off
setlocal enabledelayedexpansion

REM Windows Build Script for C++ Project Template
REM This script provides a Windows equivalent to the Unix build.sh script

REM Default values
set "BUILD_TYPE=Release"
set "BUILD_DIR="
set "INSTALL_PREFIX="
set "CLEAN_BUILD=false"
set "RUN_TESTS=false"
set "VERBOSE=false"
set "BUILD_TESTS=true"
set "TESTS_ONLY=false"
set "BUILD_DOCS=false"
set "OPEN_DOCS=false"
set "JOBS=4"

REM Get number of processors if available
if defined NUMBER_OF_PROCESSORS (
    set "JOBS=%NUMBER_OF_PROCESSORS%"
)

REM Script directory
set "SCRIPT_DIR=%~dp0"
set "SOURCE_DIR=%SCRIPT_DIR%"

REM Colors for output (Windows doesn't support ANSI colors in standard cmd by default)
REM But we'll define them for consistency and future PowerShell support

:parse_args
if "%~1"=="" goto end_parse_args
if "%~1"=="-h" goto show_help
if "%~1"=="--help" goto show_help
if "%~1"=="-d" (
    set "BUILD_TYPE=Debug"
    shift
    goto parse_args
)
if "%~1"=="--debug" (
    set "BUILD_TYPE=Debug"
    shift
    goto parse_args
)
if "%~1"=="-r" (
    set "BUILD_TYPE=Release"
    shift
    goto parse_args
)
if "%~1"=="--release" (
    set "BUILD_TYPE=Release"
    shift
    goto parse_args
)
if "%~1"=="--clean" (
    set "CLEAN_BUILD=true"
    shift
    goto parse_args
)
if "%~1"=="-t" (
    set "RUN_TESTS=true"
    shift
    goto parse_args
)
if "%~1"=="--test" (
    set "RUN_TESTS=true"
    shift
    goto parse_args
)
if "%~1"=="--tests-only" (
    set "TESTS_ONLY=true"
    set "BUILD_TESTS=true"
    set "RUN_TESTS=true"
    shift
    goto parse_args
)
if "%~1"=="--no-tests" (
    set "BUILD_TESTS=false"
    shift
    goto parse_args
)
if "%~1"=="-v" (
    set "VERBOSE=true"
    shift
    goto parse_args
)
if "%~1"=="--verbose" (
    set "VERBOSE=true"
    shift
    goto parse_args
)
if "%~1"=="--docs" (
    set "BUILD_DOCS=true"
    shift
    goto parse_args
)
if "%~1"=="--open-docs" (
    set "BUILD_DOCS=true"
    set "OPEN_DOCS=true"
    shift
    goto parse_args
)
if "%~1"=="-j" (
    set "JOBS=%~2"
    shift
    shift
    goto parse_args
)
echo Unknown option: %~1
goto show_help

:end_parse_args

REM Determine preset name based on OS and build type
set "PRESET_NAME=x64-Windows-%BUILD_TYPE%"

REM Set default build and install directories if not specified
if "%BUILD_DIR%"=="" (
    set "BUILD_DIR=%SOURCE_DIR%\out\build\%PRESET_NAME%"
)

if "%INSTALL_PREFIX%"=="" (
    set "INSTALL_PREFIX=%SOURCE_DIR%\out\install\%PRESET_NAME%"
)

echo ========================================
echo   Windows C++ Build Script
echo ========================================
echo Build Type:       %BUILD_TYPE%
echo Build Directory:  %BUILD_DIR%
echo Install Prefix:   %INSTALL_PREFIX%
echo Parallel Jobs:    %JOBS%
echo Clean Build:      %CLEAN_BUILD%
echo Run Tests:        %RUN_TESTS%
echo Build Tests:      %BUILD_TESTS%
echo Tests Only:       %TESTS_ONLY%
echo Build Docs:       %BUILD_DOCS%
echo Open Docs:        %OPEN_DOCS%
echo ========================================
echo.

REM Check dependencies
echo [INFO] Checking dependencies...

REM Check CMake
cmake --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] CMake not found. Please install CMake and add it to PATH.
    echo         Download from: https://cmake.org/download/
    exit /b 1
)
echo [SUCCESS] CMake found

REM Check C++ compiler (try MSVC first, then others)
where cl >nul 2>&1
if not errorlevel 1 (
    echo [SUCCESS] MSVC compiler found
    goto compiler_found
)

where g++ >nul 2>&1
if not errorlevel 1 (
    echo [SUCCESS] GCC compiler found
    goto compiler_found
)

where clang++ >nul 2>&1
if not errorlevel 1 (
    echo [SUCCESS] Clang compiler found
    goto compiler_found
)

echo [ERROR] No C++ compiler found. Please install:
echo         - Visual Studio 2022 with C++ tools, or
echo         - MinGW-w64, or
echo         - Clang
exit /b 1

:compiler_found

REM Check for Doxygen (optional)
doxygen --version >nul 2>&1
if not errorlevel 1 (
    echo [SUCCESS] Doxygen found
) else (
    echo [WARNING] Doxygen not found. Documentation generation will be skipped.
    echo           Install from: https://www.doxygen.nl/download.html
    set "BUILD_DOCS=false"
)

REM Clean build directory if requested
if "%CLEAN_BUILD%"=="true" (
    echo [INFO] Cleaning build directory: %BUILD_DIR%
    if exist "%BUILD_DIR%" (
        rmdir /s /q "%BUILD_DIR%"
    )
    echo [SUCCESS] Build directory cleaned
)

REM Configure CMake
echo [INFO] Configuring CMake...
cmake --preset "%PRESET_NAME%"
if errorlevel 1 (
    echo [ERROR] CMake configuration failed
    exit /b 1
)
echo [SUCCESS] CMake configuration complete

REM Build project
if "%TESTS_ONLY%"=="false" (
    echo [INFO] Building project...
    if "%VERBOSE%"=="true" (
        cmake --build "%BUILD_DIR%" --config %BUILD_TYPE% --parallel %JOBS% --verbose
    ) else (
        cmake --build "%BUILD_DIR%" --config %BUILD_TYPE% --parallel %JOBS%
    )
    if errorlevel 1 (
        echo [ERROR] Build failed
        exit /b 1
    )
    echo [SUCCESS] Build complete
)

REM Build tests if requested
if "%BUILD_TESTS%"=="true" (
    echo [INFO] Building test targets...
    if "%VERBOSE%"=="true" (
        cmake --build "%BUILD_DIR%" --target mylib_tests --config %BUILD_TYPE% --parallel %JOBS% --verbose
    ) else (
        cmake --build "%BUILD_DIR%" --target mylib_tests --config %BUILD_TYPE% --parallel %JOBS%
    )
    if errorlevel 1 (
        echo [ERROR] Test build failed
        exit /b 1
    )
    echo [SUCCESS] Tests built
)

REM Run tests if requested
if "%RUN_TESTS%"=="true" (
    echo [INFO] Running tests...
    ctest --test-dir "%BUILD_DIR%" --output-on-failure --config %BUILD_TYPE%
    if errorlevel 1 (
        echo [ERROR] Tests failed
        exit /b 1
    )
    echo [SUCCESS] All tests passed
)

REM Install if not tests only
if "%TESTS_ONLY%"=="false" (
    echo [INFO] Installing to %INSTALL_PREFIX%...
    cmake --install "%BUILD_DIR%" --config %BUILD_TYPE%
    if errorlevel 1 (
        echo [ERROR] Installation failed
        exit /b 1
    )
    echo [SUCCESS] Installation complete
)

REM Build documentation if requested
if "%BUILD_DOCS%"=="true" (
    echo [INFO] Building documentation...
    cmake --build "%BUILD_DIR%" --target docs --config %BUILD_TYPE%
    if errorlevel 1 (
        echo [WARNING] Documentation build failed
    ) else (
        echo [SUCCESS] Documentation built

        if "%OPEN_DOCS%"=="true" (
            set "DOCS_INDEX=%BUILD_DIR%\docs\html\index.html"
            if exist "!DOCS_INDEX!" (
                echo [INFO] Opening documentation...
                start "!DOCS_INDEX!"
            ) else (
                echo [WARNING] Documentation index not found at: !DOCS_INDEX!
            )
        )
    )
)

echo.
echo [SUCCESS] ========================================
echo [SUCCESS]   Build completed successfully!
echo [SUCCESS] ========================================
echo [INFO] Build directory: %BUILD_DIR%
echo [INFO] Install prefix:  %INSTALL_PREFIX%

goto end

:show_help
echo Usage: build.bat [OPTIONS]
echo.
echo Build script for C++ Project Template (Windows).
echo.
echo Options:
echo   -h, --help          Show this help message
echo   -d, --debug         Build in Debug mode
echo   -r, --release       Build in Release mode (default)
echo       --clean         Clean build directory before building
echo   -t, --test          Run tests after building
echo       --tests-only    Only build and run tests
echo       --no-tests      Don't build tests
echo   -v, --verbose       Enable verbose output
echo       --docs          Build documentation with Doxygen
echo       --open-docs     Build and open documentation
echo   -j ^<jobs^>           Number of parallel jobs (default: %JOBS%)
echo.
echo Examples:
echo   build.bat                    # Release build
echo   build.bat --debug           # Debug build
echo   build.bat --clean --test    # Clean build and run tests
echo   build.bat --docs            # Build with documentation
echo.

:end
