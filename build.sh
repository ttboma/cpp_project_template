#!/usr/bin/env bash

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${SCRIPT_DIR}"

# Default values
BUILD_TYPE="Release"
BUILD_DIR=""
INSTALL_PREFIX=""
CLEAN_BUILD=false
RUN_TESTS=false
VERBOSE=false
BUILD_TESTS=true
TESTS_ONLY=false
BUILD_DOCS=false
OPEN_DOCS=false
JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

# Helper functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Build script for leetcode_cpp project.

OPTIONS:
    -h, --help              Show this help message
    -c, --clean             Clean build (remove build directory first)
    -t, --type TYPE         Build type: Debug, Release, RelWithDebInfo, MinSizeRel (default: Release)
    -d, --build-dir DIR     Build directory (default: "\${sourceDir}/out/build/\${presetName}")
    -j, --jobs N            Number of parallel jobs (default: $(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4))
    -r, --run-tests         Run tests after building
    -i, --install PREFIX    Install to PREFIX directory (default: \${sourceDir}/out/install/\${presetName})
    -v, --verbose           Verbose build output
    --no-tests              Don't build tests
    --tests-only            Build and run tests only (implies --run-tests)
    --docs                  Build documentation (requires Doxygen)
    --open-docs             Build and open documentation in browser (implies --docs)

EXAMPLES:
    $(basename "$0")                          # Build Release version
    $(basename "$0") -c -t Debug              # Clean build in Debug mode
    $(basename "$0") -t Debug -r              # Build Debug and run tests
    $(basename "$0") --tests-only             # Build and run tests only
    $(basename "$0") -i /usr/local            # Build and install to /usr/local
    $(basename "$0") --docs                   # Build documentation
    $(basename "$0") --open-docs              # Build and open documentation in browser

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -c|--clean)
            CLEAN_BUILD=true
            shift
            ;;
        -t|--type)
            BUILD_TYPE="$2"
            shift 2
            ;;
        -d|--build-dir)
            BUILD_DIR="$2"
            shift 2
            ;;
        -j|--jobs)
            JOBS="$2"
            shift 2
            ;;
        -r|--run-tests)
            RUN_TESTS=true
            shift
            ;;
        -i|--install)
            INSTALL_PREFIX="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --no-tests)
            BUILD_TESTS=false
            shift
            ;;
        --tests-only)
            TESTS_ONLY=true
            RUN_TESTS=true
            shift
            ;;
        --docs)
            BUILD_DOCS=true
            shift
            ;;
        --open-docs)
            BUILD_DOCS=true
            OPEN_DOCS=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate build type
case $BUILD_TYPE in
    Debug|Release|RelWithDebInfo|MinSizeRel)
        ;;
    *)
        print_error "Invalid build type: $BUILD_TYPE"
        print_error "Valid types: Debug, Release, RelWithDebInfo, MinSizeRel"
        exit 1
        ;;
esac

# Determine preset name based on OS and build type
OS_NAME=$(uname -s)
PRESET_NAME="x64-${OS_NAME}-${BUILD_TYPE}"

# Set default build and install directories if not specified
if [[ -z "$BUILD_DIR" ]]; then
    BUILD_DIR="${SOURCE_DIR}/out/build/${PRESET_NAME}"
fi

if [[ -z "$INSTALL_PREFIX" ]]; then
    INSTALL_PREFIX="${SOURCE_DIR}/out/install/${PRESET_NAME}"
fi

print_info "========================================"
print_info "  LeetCode C++ Build Script"
print_info "========================================"
print_info "Build Type:       ${BUILD_TYPE}"
print_info "Build Directory:  ${BUILD_DIR}"
print_info "Install Prefix:   ${INSTALL_PREFIX}"
print_info "Parallel Jobs:    ${JOBS}"
print_info "Clean Build:      ${CLEAN_BUILD}"
print_info "Run Tests:        ${RUN_TESTS}"
print_info "Build Tests:      ${BUILD_TESTS}"
print_info "Tests Only:       ${TESTS_ONLY}"
print_info "Build Docs:       ${BUILD_DOCS}"
print_info "Open Docs:        ${OPEN_DOCS}"
print_info "========================================"
echo ""

# 1. Check dependencies
print_info "Checking dependencies..."

# Check for CMake
if ! command -v cmake &> /dev/null; then
    print_error "CMake is not installed. Please install CMake first."
    exit 1
fi
print_success "CMake found: $(cmake --version | head -n1)"

# Check for C++ compiler
if ! command -v g++ &> /dev/null && ! command -v clang++ &> /dev/null; then
    print_error "No C++ compiler found. Please install g++ or clang++."
    exit 1
fi
if command -v clang++ &> /dev/null; then
    print_success "C++ compiler found: $(clang++ --version | head -n1)"
elif command -v g++ &> /dev/null; then
    print_success "C++ compiler found: $(g++ --version | head -n1)"
fi

# Check for Doxygen (warning only)
if ! command -v doxygen &> /dev/null; then
    print_warning "Doxygen not found. Documentation generation will be skipped."
    print_warning "Install with: brew install doxygen (macOS) or apt-get install doxygen (Linux)"
    if [[ "$BUILD_DOCS" == true ]]; then
        print_error "Cannot build documentation without Doxygen. Please install it first."
        exit 1
    fi
else
    print_success "Doxygen found: $(doxygen --version)"
fi

echo ""

# 2. Setup virtual environment and install Python tools
print_info "Setting up Python virtual environment..."

VENV_DIR="${SOURCE_DIR}/.venv"

# Create virtual environment if it doesn't exist
if [[ ! -d "$VENV_DIR" ]]; then
    print_info "Creating virtual environment at ${VENV_DIR}..."
    python3 -m venv "$VENV_DIR"
    print_success "Virtual environment created"
else
    print_info "Virtual environment already exists"
fi

# Activate virtual environment
source "${VENV_DIR}/bin/activate"

# Install/upgrade pip
print_info "Upgrading pip..."
pip install --upgrade pip -q

# Install pre-commit if not present
PRECOMMIT_IN_VENV="${VENV_DIR}/bin/pre-commit"
if [[ ! -f "$PRECOMMIT_IN_VENV" ]]; then
    print_info "Installing pre-commit in virtual environment..."
    pip install pre-commit -q
    print_success "pre-commit installed"
else
    print_success "pre-commit already installed: $($PRECOMMIT_IN_VENV --version)"
fi

# Install clang-format and clang-tidy in virtual environment
# These are available as Python packages
CLANG_FORMAT_IN_VENV="${VENV_DIR}/bin/clang-format"
if [[ ! -f "$CLANG_FORMAT_IN_VENV" ]]; then
    print_info "Installing clang-format in virtual environment..."
    pip install clang-format -q
    print_success "clang-format installed: $($CLANG_FORMAT_IN_VENV --version | head -n1)"
else
    print_success "clang-format found in venv: $($CLANG_FORMAT_IN_VENV --version | head -n1)"
fi

CLANG_TIDY_IN_VENV="${VENV_DIR}/bin/clang-tidy"
if [[ ! -f "$CLANG_TIDY_IN_VENV" ]]; then
    print_info "Installing clang-tidy in virtual environment..."
    pip install clang-tidy -q
    print_success "clang-tidy installed: $($CLANG_TIDY_IN_VENV --version | head -n1)"
else
    print_success "clang-tidy found in venv: $($CLANG_TIDY_IN_VENV --version | head -n1)"
fi

# Install pre-commit hooks if .pre-commit-config.yaml exists
if [[ -f "${SOURCE_DIR}/.pre-commit-config.yaml" ]]; then
    print_info "Installing pre-commit hooks..."
    "$PRECOMMIT_IN_VENV" install --hook-type commit-msg --hook-type pre-commit --hook-type pre-push
    print_success "Pre-commit hooks installed (commit-msg, pre-commit, pre-push)"
fi

echo ""

# 3. Clean build if requested
if [[ "$CLEAN_BUILD" == true ]]; then
    print_info "Cleaning build directory: ${BUILD_DIR}"
    if [[ -d "$BUILD_DIR" ]]; then
        rm -rf "$BUILD_DIR"
        print_success "Build directory cleaned"
    else
        print_info "Build directory doesn't exist, skipping clean"
    fi
fi

# 4. Configure CMake
print_info "Configuring CMake..."

CMAKE_ARGS=(
    -S "${SOURCE_DIR}"
    -B "${BUILD_DIR}"
    -DCMAKE_BUILD_TYPE="${BUILD_TYPE}"
    -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}"
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
    -DBUILD_SHARED_LIBS=ON
)

if [[ "$BUILD_TESTS" == false ]]; then
    CMAKE_ARGS+=(-DBUILD_TESTING=OFF)
fi

if [[ "$VERBOSE" == true ]]; then
    cmake "${CMAKE_ARGS[@]}"
else
    cmake "${CMAKE_ARGS[@]}" > /dev/null
fi

print_success "CMake configuration complete"

# 5. Build
if [[ "$TESTS_ONLY" == false ]]; then
    print_info "Building project..."

    BUILD_ARGS=(
        --build "${BUILD_DIR}"
        --config "${BUILD_TYPE}"
        -j "${JOBS}"
    )

    if [[ "$VERBOSE" == true ]]; then
        BUILD_ARGS+=(--verbose)
    fi

    cmake "${BUILD_ARGS[@]}"
    print_success "Build complete"
fi

# 6. Build tests if needed
if [[ "$RUN_TESTS" == true && "$BUILD_TESTS" == true ]]; then
    if [[ "$TESTS_ONLY" == true ]]; then
        print_info "Building tests..."
    else
        print_info "Building test targets..."
    fi

    TEST_BUILD_ARGS=(
        --build "${BUILD_DIR}"
        --config "${BUILD_TYPE}"
        -j "${JOBS}"
    )

    if [[ "$VERBOSE" == true ]]; then
        TEST_BUILD_ARGS+=(--verbose)
    fi

    cmake "${TEST_BUILD_ARGS[@]}"
    print_success "Tests built"
fi

# 7. Run tests if requested
if [[ "$RUN_TESTS" == true ]]; then
    print_info "Running tests..."

    cd "${BUILD_DIR}"

    if [[ "$VERBOSE" == true ]]; then
        ctest --output-on-failure -C "${BUILD_TYPE}"
    else
        ctest --output-on-failure -C "${BUILD_TYPE}"
    fi

    TEST_EXIT_CODE=$?

    cd "${SOURCE_DIR}"

    if [[ $TEST_EXIT_CODE -eq 0 ]]; then
        print_success "All tests passed"
    else
        print_error "Some tests failed (exit code: $TEST_EXIT_CODE)"
        exit $TEST_EXIT_CODE
    fi
fi

# 8. Install if prefix was specified and not in tests-only mode
if [[ -n "$INSTALL_PREFIX" && "$TESTS_ONLY" == false ]]; then
    print_info "Installing to ${INSTALL_PREFIX}..."

    cmake --install "${BUILD_DIR}" --config "${BUILD_TYPE}"

    print_success "Installation complete"
fi

# 9. Build documentation if requested
if [[ "$BUILD_DOCS" == true ]]; then
    print_info "Building documentation..."

    DOCS_BUILD_ARGS=(
        --build "${BUILD_DIR}"
        --config "${BUILD_TYPE}"
        --target docs
    )

    if [[ "$VERBOSE" == true ]]; then
        DOCS_BUILD_ARGS+=(--verbose)
    fi

    cmake "${DOCS_BUILD_ARGS[@]}"
    print_success "Documentation built successfully"
    print_info "Documentation location: ${BUILD_DIR}/docs/html/index.html"

    # Open documentation if requested
    if [[ "$OPEN_DOCS" == true ]]; then
        DOCS_INDEX="${BUILD_DIR}/docs/html/index.html"
        if [[ -f "$DOCS_INDEX" ]]; then
            print_info "Opening documentation in browser..."
            if command -v open &> /dev/null; then
                # macOS
                open "$DOCS_INDEX"
            elif command -v xdg-open &> /dev/null; then
                # Linux
                xdg-open "$DOCS_INDEX"
            elif command -v start &> /dev/null; then
                # Windows (Git Bash, Cygwin, WSL)
                start "$DOCS_INDEX"
            else
                print_warning "Could not detect browser opener. Please open manually: $DOCS_INDEX"
            fi
        else
            print_error "Documentation index not found at: $DOCS_INDEX"
        fi
    fi
fi

echo ""
print_success "========================================"
print_success "  Build completed successfully!"
print_success "========================================"
print_info "Build directory: ${BUILD_DIR}"
if [[ "$TESTS_ONLY" == false ]]; then
    print_info "Install prefix:  ${INSTALL_PREFIX}"
fi
echo ""
print_info "To use pre-commit, clang-format, and clang-tidy manually:"
print_info "  source .venv/bin/activate"
echo ""
