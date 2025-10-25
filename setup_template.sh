#!/usr/bin/env bash

# Script to initialize a new project from this template

set -e

echo "C++ Project Template Setup"
echo "=========================="
echo ""

# Get project name
read -p "Enter your project name (e.g., my-awesome-project): " PROJECT_NAME

if [[ -z "$PROJECT_NAME" ]]; then
    echo "Error: Project name cannot be empty"
    exit 1
fi

# Get project description
read -p "Enter project description: " PROJECT_DESC

if [[ -z "$PROJECT_DESC" ]]; then
    PROJECT_DESC="A modern C++ project"
fi

echo ""
echo "Creating project: $PROJECT_NAME"
echo "Description: $PROJECT_DESC"
echo ""

# Update CMakeLists.txt
echo "Updating CMakeLists.txt..."
sed -i.bak "s/MyProject/${PROJECT_NAME}/g" CMakeLists.txt
sed -i.bak "s/Modern C++ Project Template/${PROJECT_DESC}/g" CMakeLists.txt
rm CMakeLists.txt.bak

# Update build.sh help text
echo "Updating build.sh..."
sed -i.bak "s/leetcode_cpp project/${PROJECT_NAME} project/g" build.sh
rm build.sh.bak

# Update README.md
echo "Updating README.md..."
sed -i.bak "1s/.*/# ${PROJECT_NAME}/" README.md
sed -i.bak "3s/.*/A modern C++20 project: ${PROJECT_DESC}/" README.md
rm README.md.bak

# Initialize git repository if not already initialized
if [[ ! -d .git ]]; then
    echo "Initializing git repository..."
    git init
    git add .
    git commit -m "Initial commit from C++ template"
fi

echo ""
echo "✓ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Review and customize files as needed"
echo "  2. Run: ./build.sh"
echo "  3. Run tests: ./build.sh -r"
echo "  4. Generate docs: ./build.sh --open-docs"
echo ""
echo "Happy coding!"
