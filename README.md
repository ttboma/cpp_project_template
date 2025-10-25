# C++ Project Template

A modern C++20 project template with automated build scripts, testing, documentation, and code quality tools.

## Features

- **Modern C++20** standard
- **CMake** build system (v3.25+) with presets
- **Google Test** for unit testing
- **Doxygen** for documentation generation
- **Automated build script** (`build.sh`) with multiple options
- **Code quality tools**:
  - clang-format for code formatting
  - clang-tidy for static analysis
  - pre-commit hooks for automatic checks
- **Virtual environment** for Python-based development tools
- **Cross-platform** support (macOS, Linux)

## Prerequisites

- CMake ≥ 3.25
- C++20 compatible compiler (GCC, Clang, AppleClang)
- Python ≥ 3.8 (for development tools)
- Doxygen (optional, for documentation)

## Quick Start

1. **Clone or copy this template**:
   ```bash
   git clone <your-repo-url> my-cpp-project
   cd my-cpp-project
   ```

2. **Customize the project**:
   - Update project name in `CMakeLists.txt` (change `MyProject` to your project name)
   - Update project description in `CMakeLists.txt`
   - Modify `build.sh` help text if needed (change "leetcode_cpp project" to your project name)

3. **Build the project**:
   ```bash
   ./build.sh
   ```

   On first run, this will:
   - Create a Python virtual environment (`.venv/`)
   - Install pre-commit, clang-format, clang-tidy
   - Configure and build the project
   - Install pre-commit hooks

4. **Run tests**:
   ```bash
   ./build.sh -r
   ```

5. **Build documentation**:
   ```bash
   ./build.sh --open-docs
   ```

## Build Script Usage

```bash
./build.sh [OPTIONS]
```

### Options

- `-h, --help` - Show help message
- `-c, --clean` - Clean build (remove build directory first)
- `-t, --type TYPE` - Build type: Debug, Release, RelWithDebInfo, MinSizeRel (default: Release)
- `-d, --build-dir DIR` - Custom build directory
- `-j, --jobs N` - Number of parallel jobs (default: auto-detected)
- `-r, --run-tests` - Run tests after building
- `-i, --install PREFIX` - Install to PREFIX directory
- `-v, --verbose` - Verbose build output
- `--no-tests` - Don't build tests
- `--tests-only` - Build and run tests only
- `--docs` - Build documentation
- `--open-docs` - Build and open documentation in browser

### Examples

```bash
# Clean debug build with tests
./build.sh -c -t Debug -r

# Release build with documentation
./build.sh -t Release --open-docs

# Quick test verification
./build.sh --tests-only

# Production build and install
./build.sh -c -t Release -i /usr/local
```

## Running Tests

```bash
# Using --test-dir to specify build directory
ctest --test-dir out/build/x64-Darwin-Debug --output-on-failure

# List all tests
ctest --test-dir out/build/x64-Darwin-Debug -N

# Run specific test
ctest --test-dir out/build/x64-Darwin-Debug -R "AddTest" --output-on-failure

# Verbose output
ctest --test-dir out/build/x64-Darwin-Debug --output-on-failure -V
```

## Code Quality Tools

### Activate Virtual Environment

First, activate the virtual environment where tools are installed:

```bash
source .venv/bin/activate
```

### clang-format

```bash
# Format a specific file
clang-format -i -style=file src/mylib.cpp

# Format all C++ files
find . \( -name "*.cpp" -o -name "*.hpp" \) -not -path "./out/*" | xargs clang-format -i -style=file

# Check formatting without modifying
clang-format --dry-run --Werror -style=file src/mylib.cpp
```

### clang-tidy

```bash
# Run on a specific file
clang-tidy -p out/build/x64-Darwin-Debug src/mylib.cpp

# Run with automatic fixes
clang-tidy -p out/build/x64-Darwin-Debug --fix src/mylib.cpp

# Run on all source files
find src -name "*.cpp" | xargs clang-tidy -p out/build/x64-Darwin-Debug
```

### pre-commit Hooks

```bash
# Run on all files
pre-commit run --all-files

# Run on staged files only
pre-commit run

# Run specific hook
pre-commit run clang-format --all-files
```

**Note**: Pre-commit hooks automatically run on `git commit` and `git push` - no need to activate virtual environment for this.

## Project Structure

```
.
├── bin/                    # Executable applications
│   ├── CMakeLists.txt
│   └── main.cpp
├── src/                    # Source code libraries
│   ├── CMakeLists.txt
│   └── mylib.cpp
├── include/                # Public header files
│   └── mylib.hpp
├── tests/                  # Unit tests (Google Test)
│   ├── CMakeLists.txt
│   └── test_mylib.cpp
├── cmake/                  # CMake modules and utilities
│   ├── FindDependency.cmake
│   └── RequireOutOfSourceBuilds.cmake
├── docs/                   # Documentation
│   └── CMakeLists.txt
├── build.sh                # Build automation script
├── CMakeLists.txt          # Root CMake configuration
├── CMakePresets.json       # CMake presets
├── .clang-format           # Code formatting rules
├── .clang-tidy             # Static analysis rules
├── .pre-commit-config.yaml # Pre-commit hooks configuration
└── .gitignore              # Git ignore patterns
```

## Customizing the Template

### Adding New Source Files

1. Add `.cpp` files to `src/`
2. Add `.hpp` files to `include/`
3. Update `src/CMakeLists.txt` to include new source files

### Adding New Tests

1. Create test files in `tests/`
2. Update `tests/CMakeLists.txt` to include new test files

### Adding Dependencies

Edit `cmake/FindDependency.cmake` or use `find_package()` in CMakeLists.txt.

### Modifying Build Settings

Edit the root `CMakeLists.txt` to:
- Change C++ standard
- Add compiler flags
- Configure installation rules
- Add new subdirectories

## Development Workflow

1. **Make changes** to source code
2. **Build**: `./build.sh -t Debug`
3. **Run tests**: `./build.sh -r` or `ctest --test-dir out/build/x64-Darwin-Debug`
4. **Format code**: `pre-commit run --all-files` (or let git hooks do it)
5. **Commit**: Git hooks will automatically run checks
6. **Build documentation**: `./build.sh --open-docs`

## CI/CD Integration

The build script is designed for CI/CD pipelines:

```bash
# CI build and test
./build.sh -c -t Release -r -v

# Exit code will be non-zero if build or tests fail
```

## License

Choose your license and add it to this section.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and code quality checks
5. Submit a pull request
