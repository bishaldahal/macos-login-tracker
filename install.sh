#!/bin/bash

# Installation script for macOS Login Tracker
# This script downloads and sets up the login tracker for easy use

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Configuration
SCRIPT_NAME="login_tracker.sh"
REPO_URL="https://raw.githubusercontent.com/bishaldahal/macos-login-tracker/main"
INSTALL_DIR="$HOME/.local/bin"
SYMLINK_NAME="login-tracker"

print_color $BLUE "macOS Login Tracker - Installation Script"
print_color $BLUE "========================================"
echo ""

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_color $RED "Error: This script is designed for macOS only"
    exit 1
fi

# Check if curl is available
if ! command -v curl &> /dev/null; then
    print_color $RED "Error: curl is required but not installed"
    exit 1
fi

# Create installation directory
if [ ! -d "$INSTALL_DIR" ]; then
    print_color $YELLOW "Creating installation directory: $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
fi

# Download the script
print_color $YELLOW "Downloading login tracker script..."
if curl -fsSL "$REPO_URL/$SCRIPT_NAME" -o "$INSTALL_DIR/$SCRIPT_NAME"; then
    print_color $GREEN "✓ Successfully downloaded $SCRIPT_NAME"
else
    print_color $RED "✗ Failed to download script"
    exit 1
fi

# Make it executable
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
print_color $GREEN "✓ Made script executable"

# Create symlink for easier access
if [ ! -f "$INSTALL_DIR/$SYMLINK_NAME" ]; then
    ln -sf "$INSTALL_DIR/$SCRIPT_NAME" "$INSTALL_DIR/$SYMLINK_NAME"
    print_color $GREEN "✓ Created symlink: $SYMLINK_NAME"
fi

# Check if install directory is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    print_color $YELLOW "⚠ Installation directory is not in your PATH"
    echo ""
    print_color $BLUE "To add it to your PATH, add this line to your shell profile:"
    echo "export PATH=\"\$PATH:$INSTALL_DIR\""
    echo ""
    print_color $BLUE "For zsh (default on macOS), add to ~/.zshrc:"
    echo "echo 'export PATH=\"\$PATH:$INSTALL_DIR\"' >> ~/.zshrc"
    echo "source ~/.zshrc"
    echo ""
    print_color $BLUE "For bash, add to ~/.bash_profile:"
    echo "echo 'export PATH=\"\$PATH:$INSTALL_DIR\"' >> ~/.bash_profile"
    echo "source ~/.bash_profile"
    echo ""
fi

# Test the installation
if [ "$UPDATE_MODE" = true ]; then
    print_color $YELLOW "Testing update..."
else
    print_color $YELLOW "Testing installation..."
fi

if "$INSTALL_DIR/$SCRIPT_NAME" --help &>/dev/null; then
    if [ "$UPDATE_MODE" = true ]; then
        print_color $GREEN "✓ Update successful!"
    else
        print_color $GREEN "✓ Installation successful!"
    fi
else
    if [ "$UPDATE_MODE" = true ]; then
        print_color $RED "✗ Update test failed"
    else
        print_color $RED "✗ Installation test failed"
    fi
    exit 1
fi

echo ""
if [ "$UPDATE_MODE" = true ]; then
    print_color $GREEN "🎉 Update Complete!"
    echo ""
    print_color $BLUE "Your login tracker has been updated to the latest version."
    echo ""
    print_color $BLUE "To check the version:"
    if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
        echo "  $SYMLINK_NAME --help"
    else
        echo "  $INSTALL_DIR/$SYMLINK_NAME --help"
    fi
else
    print_color $GREEN "🎉 Installation Complete!"
    echo ""
    print_color $BLUE "Usage:"
    if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
        echo "  $SYMLINK_NAME                    # Default: last 30 days"
        echo "  $SYMLINK_NAME -d 7               # Last 7 days"
        echo "  $SYMLINK_NAME -o report.csv      # Custom output file"
        echo "  $SYMLINK_NAME --help             # Show help"
    else
        echo "  $INSTALL_DIR/$SYMLINK_NAME                    # Default: last 30 days"
        echo "  $INSTALL_DIR/$SYMLINK_NAME -d 7               # Last 7 days"
        echo "  $INSTALL_DIR/$SYMLINK_NAME -o report.csv      # Custom output file"
        echo "  $INSTALL_DIR/$SYMLINK_NAME --help             # Show help"
    fi
    echo ""
    print_color $BLUE "Example - Generate a weekly report:"
    if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
        echo "  $SYMLINK_NAME -d 7 -o weekly_report.csv"
    else
        echo "  $INSTALL_DIR/$SYMLINK_NAME -d 7 -o weekly_report.csv"
    fi
    echo ""
    print_color $BLUE "To update to the latest version in the future:"
    echo "  curl -fsSL https://raw.githubusercontent.com/bishaldahal/macos-login-tracker/main/install.sh | bash -s -- --update"
fi
echo ""
print_color $GREEN "Happy time tracking! ⏰"