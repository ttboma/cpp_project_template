#!/usr/bin/env python3
"""
Cross-platform build script for LeetCode C++ project.

This script provides a unified interface for building the C++ project
across Darwin (macOS), Linux, and Windows platforms.
"""

import argparse
import os
import platform
import shutil
import subprocess
import sys
import venv
from pathlib import Path

# Colors for terminal output
class Colors:
    """ANSI color codes for terminal output."""
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    NC = '\033[0m'  # No Color

    @classmethod
    def is_supported(cls) -> bool:
        """Check if colors are supported in the current terminal."""
        return (
            hasattr(sys.stdout, 'isatty') and sys.stdout.isatty() and
            os.environ.get('TERM') != 'dumb' and
            platform.system() != 'Windows'  # Windows cmd doesn't support ANSI by default
        )

class Logger:
    """Simple logger with colored output."""

    def __init__(self, use_colors: bool = True):
        self.use_colors = use_colors and Colors.is_supported()

    def _print(self, level: str, message: str, color: str = Colors.NC):
        """Print a message with optional color formatting."""
        if self.use_colors:
            print(f"{color}[{level}]{Colors.NC} {message}")
        else:
            print(f"[{level}] {message}")

    def info(self, message: str):
        self._print("INFO", message, Colors.BLUE)

    def success(self, message: str):
        self._print("SUCCESS", message, Colors.GREEN)

    def warning(self, message: str):
        self._print("WARNING", message, Colors.YELLOW)

    def error(self, message: str):
        self._print("ERROR", message, Colors.RED)

class PlatformDetector:
    """Detect and handle platform-specific differences."""

    @staticmethod
    def get_system() -> str:
        """Get the current operating system."""
        return platform.system()

    @staticmethod
    def get_cpu_count() -> int:
        """Get the number of CPU cores."""
        try:
            if platform.system() == "Darwin":
                result = subprocess.run(
                    ["sysctl", "-n", "hw.ncpu"],
                    capture_output=True, text=True, check=True
                )
                return int(result.stdout.strip())
            elif platform.system() == "Linux":
                return os.cpu_count() or 4
            elif platform.system() == "Windows":
                return int(os.environ.get('NUMBER_OF_PROCESSORS', '4'))
            else:
                return 4
        except (subprocess.CalledProcessError, ValueError):
            return 4

    @staticmethod
    def get_venv_activate_script(venv_path: Path) -> Path:
        """Get the path to the virtual environment activation script."""
        if platform.system() == "Windows":
            return venv_path / "Scripts" / "activate.bat"
        else:
            return venv_path / "bin" / "activate"

    @staticmethod
    def get_venv_python(venv_path: Path) -> Path:
        """Get the path to the Python executable in the virtual environment."""
        if platform.system() == "Windows":
            return venv_path / "Scripts" / "python.exe"
        else:
            return venv_path / "bin" / "python"

    @staticmethod
    def get_venv_executable(venv_path: Path, name: str) -> Path:
        """Get the path to an executable in the virtual environment."""
        if platform.system() == "Windows":
            return venv_path / "Scripts" / f"{name}.exe"
        else:
            return venv_path / "bin" / name

    @staticmethod
    def open_file(file_path: Path):
        """Open a file with the default application."""
        system = platform.system()
        if system == "Darwin":
            subprocess.run(["open", str(file_path)])
        elif system == "Linux":
            subprocess.run(["xdg-open", str(file_path)])
        elif system == "Windows":
            subprocess.run(["start", str(file_path)], shell=True)
        else:
            raise RuntimeError(f"Unsupported platform: {system}")

class DependencyChecker:
    """Check for required build dependencies."""

    def __init__(self, logger: Logger):
        self.logger = logger

    def check_cmake(self) -> bool:
        """Check if CMake is available."""
        try:
            result = subprocess.run(
                ["cmake", "--version"],
                capture_output=True, text=True, check=True
            )
            version_line = result.stdout.strip().split('\n')[0]
            self.logger.success(f"CMake found: {version_line}")
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            self.logger.error("CMake not found. Please install CMake and add it to PATH.")
            self.logger.error("Download from: https://cmake.org/download/")
            return False

    def check_cpp_compiler(self) -> bool:
        """Check if a C++ compiler is available."""
        compilers = ["clang++", "g++", "cl"]

        for compiler in compilers:
            try:
                result = subprocess.run(
                    [compiler, "--version"],
                    capture_output=True, text=True, check=True
                )
                version_line = result.stdout.strip().split('\n')[0]
                self.logger.success(f"C++ compiler found: {compiler} - {version_line}")
                return True
            except (subprocess.CalledProcessError, FileNotFoundError):
                continue

        self.logger.error("No C++ compiler found. Please install one of:")
        self.logger.error("  - Clang (recommended)")
        self.logger.error("  - GCC")
        self.logger.error("  - MSVC (Windows)")
        return False

    def check_doxygen(self, required: bool = False) -> bool:
        """Check if Doxygen is available."""
        try:
            result = subprocess.run(
                ["doxygen", "--version"],
                capture_output=True, text=True, check=True
            )
            version = result.stdout.strip()
            self.logger.success(f"Doxygen found: {version}")
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            if required:
                self.logger.error("Doxygen not found. Cannot build documentation without Doxygen.")
                self.logger.error("Please install Doxygen first.")
                return False
            else:
                self.logger.warning("Doxygen not found. Documentation generation will be skipped.")
                system = platform.system()
                if system == "Darwin":
                    self.logger.warning("Install with: brew install doxygen")
                elif system == "Linux":
                    self.logger.warning("Install with: apt-get install doxygen (Ubuntu/Debian)")
                elif system == "Windows":
                    self.logger.warning("Download from: https://www.doxygen.nl/download.html")
                return False

    def check_python(self) -> bool:
        """Check if Python 3 is available."""
        try:
            result = subprocess.run(
                [sys.executable, "--version"],
                capture_output=True, text=True, check=True
            )
            version_line = result.stdout.strip()
            self.logger.success(f"Python found: {version_line}")
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            self.logger.error("Python 3 not found. This script requires Python 3.")
            return False

class VirtualEnvironmentManager:
    """Manage Python virtual environment."""

    def __init__(self, logger: Logger, source_dir: Path):
        self.logger = logger
        self.source_dir = source_dir
        self.venv_dir = source_dir / ".venv"
        self.detector = PlatformDetector()

    def create_or_update(self):
        """Create or update the virtual environment."""
        self.logger.info("Setting up Python virtual environment...")

        # Create virtual environment if it doesn't exist
        if not self.venv_dir.exists():
            self.logger.info(f"Creating virtual environment at {self.venv_dir}...")
            venv.create(self.venv_dir, with_pip=True)
            self.logger.success("Virtual environment created")
        else:
            self.logger.info("Virtual environment already exists")

        # Get Python executable in venv
        python_exe = self.detector.get_venv_python(self.venv_dir)

        # Upgrade pip
        self.logger.info("Upgrading pip...")
        subprocess.run([
            str(python_exe), "-m", "pip", "install", "--upgrade", "pip", "-q"
        ], check=True)

        # Install required packages
        packages = ["pre-commit", "clang-format", "clang-tidy"]

        for package in packages:
            executable = self.detector.get_venv_executable(self.venv_dir, package)
            if not executable.exists():
                self.logger.info(f"Installing {package} in virtual environment...")
                subprocess.run([
                    str(python_exe), "-m", "pip", "install", package, "-q"
                ], check=True)
                self.logger.success(f"{package} installed")
            else:
                # Get version info
                try:
                    result = subprocess.run([
                        str(executable), "--version"
                    ], capture_output=True, text=True, check=True)
                    version = result.stdout.strip().split('\n')[0]
                    self.logger.success(f"{package} found in venv: {version}")
                except subprocess.CalledProcessError:
                    self.logger.success(f"{package} already installed")

    def install_precommit_hooks(self):
        """Install pre-commit hooks if configuration exists."""
        precommit_config = self.source_dir / ".pre-commit-config.yaml"
        if precommit_config.exists():
            self.logger.info("Installing pre-commit hooks...")
            precommit_exe = self.detector.get_venv_executable(self.venv_dir, "pre-commit")

            subprocess.run([
                str(precommit_exe), "install",
                "--hook-type", "commit-msg",
                "--hook-type", "pre-commit",
                "--hook-type", "pre-push"
            ], cwd=self.source_dir, check=True)

            self.logger.success("Pre-commit hooks installed (commit-msg, pre-commit, pre-push)")

class BuildConfiguration:
    """Build configuration and validation."""

    VALID_BUILD_TYPES = ["Debug", "Release", "RelWithDebInfo", "MinSizeRel"]

    def __init__(self, args: argparse.Namespace, source_dir: Path):
        self.source_dir = source_dir
        self.build_type = args.type
        self.build_dir = Path(args.build_dir) if args.build_dir else None
        self.install_prefix = Path(args.install) if args.install else None
        self.jobs = args.jobs
        self.clean_build = args.clean
        self.run_tests = args.run_tests
        self.verbose = args.verbose
        self.build_tests = not args.no_tests
        self.tests_only = args.tests_only
        self.build_docs = args.docs or args.open_docs
        self.open_docs = args.open_docs

        # Apply tests_only implications
        if self.tests_only:
            self.run_tests = True
            self.build_tests = True

        self._validate_and_set_defaults()

    def _validate_and_set_defaults(self):
        """Validate configuration and set defaults."""
        # Validate build type
        if self.build_type not in self.VALID_BUILD_TYPES:
            raise ValueError(f"Invalid build type: {self.build_type}. "
                           f"Valid types: {', '.join(self.VALID_BUILD_TYPES)}")

        # Set default build directory
        if self.build_dir is None:
            self.build_dir = self.source_dir / "out" / "build" / self.build_type

        # Set default install prefix
        if self.install_prefix is None:
            self.install_prefix = self.source_dir / "out" / "install" / self.build_type

    def display_summary(self, logger: Logger):
        """Display build configuration summary."""
        logger.info("========================================")
        logger.info("  LeetCode C++ Build Script (Python)")
        logger.info("========================================")
        logger.info(f"Platform:         {platform.system()} {platform.machine()}")
        logger.info(f"Build Type:       {self.build_type}")
        logger.info(f"Build Directory:  {self.build_dir}")
        logger.info(f"Install Prefix:   {self.install_prefix}")
        logger.info(f"Parallel Jobs:    {self.jobs}")
        logger.info(f"Clean Build:      {self.clean_build}")
        logger.info(f"Run Tests:        {self.run_tests}")
        logger.info(f"Build Tests:      {self.build_tests}")
        logger.info(f"Tests Only:       {self.tests_only}")
        logger.info(f"Build Docs:       {self.build_docs}")
        logger.info(f"Open Docs:        {self.open_docs}")
        logger.info("========================================")
        print()

class CMakeBuildSystem:
    """Handle CMake configuration and building."""

    def __init__(self, logger: Logger, config: BuildConfiguration):
        self.logger = logger
        self.config = config

    def configure(self):
        """Configure CMake."""
        self.logger.info("Configuring CMake...")

        cmake_args = [
            "cmake",
            "-S", str(self.config.source_dir),
            "-B", str(self.config.build_dir),
            f"-DCMAKE_BUILD_TYPE={self.config.build_type}",
            f"-DCMAKE_INSTALL_PREFIX={self.config.install_prefix}",
            "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON",
            "-DBUILD_SHARED_LIBS=ON"
        ]

        if not self.config.build_tests:
            cmake_args.append("-DBUILD_TESTING=OFF")

        # Run cmake configure
        if self.config.verbose:
            subprocess.run(cmake_args, check=True)
        else:
            subprocess.run(cmake_args, check=True,
                         stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)

        self.logger.success("CMake configuration complete")

    def build(self):
        """Build the project."""
        if not self.config.tests_only:
            self.logger.info("Building project...")

            build_args = [
                "cmake", "--build", str(self.config.build_dir),
                "--config", self.config.build_type,
                "-j", str(self.config.jobs)
            ]

            if self.config.verbose:
                build_args.append("--verbose")

            subprocess.run(build_args, check=True)
            self.logger.success("Build complete")

    def create_compile_commands_symlink(self):
        """Create symlink for IDE support."""
        compile_commands = self.config.build_dir / "compile_commands.json"
        if compile_commands.exists():
            self.logger.info("Creating compile_commands.json symlink for IDE support...")

            symlink_path = self.config.source_dir / "compile_commands.json"
            relative_path = os.path.relpath(compile_commands, self.config.source_dir)

            # Remove existing symlink/file
            if symlink_path.exists() or symlink_path.is_symlink():
                symlink_path.unlink()

            try:
                # Try to create symlink
                symlink_path.symlink_to(relative_path)
                self.logger.success(f"IDE symlink created: compile_commands.json -> {relative_path}")
            except OSError:
                # Fallback to copying on Windows if symlink fails
                shutil.copy2(compile_commands, symlink_path)
                self.logger.success("IDE file copied: compile_commands.json (symlink not supported)")

    def build_tests(self):
        """Build test targets."""
        if self.config.run_tests and self.config.build_tests:
            if self.config.tests_only:
                self.logger.info("Building tests...")
            else:
                self.logger.info("Building test targets...")

            test_build_args = [
                "cmake", "--build", str(self.config.build_dir),
                "--config", self.config.build_type,
                "-j", str(self.config.jobs)
            ]

            if self.config.verbose:
                test_build_args.append("--verbose")

            subprocess.run(test_build_args, check=True)
            self.logger.success("Tests built")

    def run_tests(self):
        """Run tests using CTest."""
        if self.config.run_tests:
            self.logger.info("Running tests...")

            test_args = [
                "ctest", "--test-dir", str(self.config.build_dir),
                "--output-on-failure", "--config", self.config.build_type
            ]

            result = subprocess.run(test_args)

            if result.returncode == 0:
                self.logger.success("All tests passed")
            else:
                self.logger.error(f"Some tests failed (exit code: {result.returncode})")
                return False
        return True

    def install(self):
        """Install the project."""
        if not self.config.tests_only:
            self.logger.info(f"Installing to {self.config.install_prefix}...")

            install_args = [
                "cmake", "--install", str(self.config.build_dir),
                "--config", self.config.build_type
            ]

            subprocess.run(install_args, check=True)
            self.logger.success("Installation complete")

    def build_docs(self):
        """Build documentation."""
        if self.config.build_docs:
            self.logger.info("Building documentation...")

            docs_args = [
                "cmake", "--build", str(self.config.build_dir),
                "--config", self.config.build_type,
                "--target", "docs"
            ]

            if self.config.verbose:
                docs_args.append("--verbose")

            try:
                subprocess.run(docs_args, check=True)
                self.logger.success("Documentation built successfully")

                docs_index = self.config.build_dir / "docs" / "html" / "index.html"
                self.logger.info(f"Documentation location: {docs_index}")

                if self.config.open_docs and docs_index.exists():
                    self.logger.info("Opening documentation in browser...")
                    try:
                        PlatformDetector.open_file(docs_index)
                    except RuntimeError as e:
                        self.logger.warning(f"Could not open documentation: {e}")
                        self.logger.warning(f"Please open manually: {docs_index}")
                elif self.config.open_docs:
                    self.logger.error(f"Documentation index not found at: {docs_index}")

            except subprocess.CalledProcessError:
                self.logger.warning("Documentation build failed")

def create_arg_parser() -> argparse.ArgumentParser:
    """Create command line argument parser."""
    parser = argparse.ArgumentParser(
        description="Cross-platform build script for LeetCode C++ project",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python build.py                          # Build Release version
  python build.py -c -t Debug              # Clean build in Debug mode
  python build.py -t Debug -r              # Build Debug and run tests
  python build.py --tests-only             # Build and run tests only
  python build.py -i /usr/local            # Build and install to /usr/local
  python build.py --docs                   # Build documentation
  python build.py --open-docs              # Build and open documentation in browser
        """
    )

    # Build options
    parser.add_argument(
        "-c", "--clean", action="store_true",
        help="Clean build (remove build directory first)"
    )
    parser.add_argument(
        "-t", "--type", default="Release",
        choices=BuildConfiguration.VALID_BUILD_TYPES,
        help="Build type (default: Release)"
    )
    parser.add_argument(
        "-d", "--build-dir",
        help="Build directory (default: <source>/out/build/<type>)"
    )
    parser.add_argument(
        "-j", "--jobs", type=int, default=PlatformDetector.get_cpu_count(),
        help=f"Number of parallel jobs (default: {PlatformDetector.get_cpu_count()})"
    )

    # Test options
    parser.add_argument(
        "-r", "--run-tests", action="store_true",
        help="Run tests after building"
    )
    parser.add_argument(
        "--no-tests", action="store_true",
        help="Don't build tests"
    )
    parser.add_argument(
        "--tests-only", action="store_true",
        help="Build and run tests only (implies --run-tests)"
    )

    # Install options
    parser.add_argument(
        "-i", "--install",
        help="Install to PREFIX directory (default: <source>/out/install/<type>)"
    )

    # Documentation options
    parser.add_argument(
        "--docs", action="store_true",
        help="Build documentation (requires Doxygen)"
    )
    parser.add_argument(
        "--open-docs", action="store_true",
        help="Build and open documentation in browser (implies --docs)"
    )

    # Output options
    parser.add_argument(
        "-v", "--verbose", action="store_true",
        help="Verbose build output"
    )

    return parser

def main() -> int:
    """Main entry point."""
    # Get script directory
    source_dir = Path(__file__).parent.resolve()

    # Parse arguments
    parser = create_arg_parser()
    args = parser.parse_args()

    # Initialize logger
    logger = Logger()

    try:
        # Create build configuration
        config = BuildConfiguration(args, source_dir)
        config.display_summary(logger)

        # Check dependencies
        logger.info("Checking dependencies...")
        checker = DependencyChecker(logger)

        if not checker.check_python():
            return 1

        if not checker.check_cmake():
            return 1

        if not checker.check_cpp_compiler():
            return 1

        if not checker.check_doxygen(config.build_docs):
            if config.build_docs:
                return 1

        print()

        # Setup virtual environment
        venv_manager = VirtualEnvironmentManager(logger, source_dir)
        venv_manager.create_or_update()
        venv_manager.install_precommit_hooks()

        print()

        # Clean build if requested
        if config.clean_build:
            logger.info(f"Cleaning build directory: {config.build_dir}")
            if config.build_dir.exists():
                shutil.rmtree(config.build_dir)
                logger.success("Build directory cleaned")
            else:
                logger.info("Build directory doesn't exist, skipping clean")

        # Build system operations
        build_system = CMakeBuildSystem(logger, config)

        # Configure CMake
        build_system.configure()

        # Build project
        build_system.build()

        # Create IDE support files
        build_system.create_compile_commands_symlink()

        # Build tests if needed
        build_system.build_tests()

        # Run tests if requested
        if not build_system.run_tests():
            return 1

        # Install project
        build_system.install()

        # Build documentation
        build_system.build_docs()

        # Final success message
        print()
        logger.success("========================================")
        logger.success("  Build completed successfully!")
        logger.success("========================================")
        logger.info(f"Build directory: {config.build_dir}")
        if not config.tests_only:
            logger.info(f"Install prefix:  {config.install_prefix}")
        print()
        logger.info("To use pre-commit, clang-format, and clang-tidy manually:")
        if platform.system() == "Windows":
            logger.info(f"  {source_dir}/.venv/Scripts/activate.bat")
        else:
            logger.info(f"  source {source_dir}/.venv/bin/activate")
        print()

        return 0

    except KeyboardInterrupt:
        logger.error("Build interrupted by user")
        return 130
    except Exception as e:
        logger.error(f"Build failed: {e}")
        if args.verbose:
            import traceback
            traceback.print_exc()
        return 1

if __name__ == "__main__":
    sys.exit(main())
