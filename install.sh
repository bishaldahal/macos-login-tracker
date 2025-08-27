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

# Auto-configure PATH if needed
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    print_color $YELLOW "Adding $INSTALL_DIR to your PATH..."
    
    # Detect shell and appropriate config file
    if [[ "$SHELL" == *"zsh"* ]] || [[ -n "$ZSH_VERSION" ]]; then
        SHELL_CONFIG="$HOME/.zshrc"
        SHELL_NAME="zsh"
    elif [[ "$SHELL" == *"bash"* ]] || [[ -n "$BASH_VERSION" ]]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            SHELL_CONFIG="$HOME/.bash_profile"
        else
            SHELL_CONFIG="$HOME/.bashrc"
        fi
        SHELL_NAME="bash"
    else
        SHELL_CONFIG="$HOME/.profile"
        SHELL_NAME="shell"
    fi
    
    # Create config file if it doesn't exist
    touch "$SHELL_CONFIG"
    
    # Check if PATH export already exists
    if ! grep -q "export PATH.*$INSTALL_DIR" "$SHELL_CONFIG" 2>/dev/null; then
        echo "" >> "$SHELL_CONFIG"
        echo "# Added by macOS Login Tracker installer" >> "$SHELL_CONFIG"
        echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$SHELL_CONFIG"
        print_color $GREEN "✓ Added $INSTALL_DIR to $SHELL_CONFIG"
        
        # Source the config for current session
        export PATH="$PATH:$INSTALL_DIR"
        print_color $GREEN "✓ PATH updated for current session"
        
        print_color $BLUE "💡 To use in new terminal sessions, restart your terminal or run:"
        print_color $BLUE "   source $SHELL_CONFIG"
    else
        print_color $YELLOW "⚠ PATH entry already exists in $SHELL_CONFIG"
    fi
else
    print_color $GREEN "✓ Installation directory already in PATH"
fi

# Test the installation
print_color $YELLOW "Testing installation..."
if "$INSTALL_DIR/$SCRIPT_NAME" --help &>/dev/null; then
    print_color $GREEN "✓ Installation successful!"
else
    print_color $RED "✗ Installation test failed"
    exit 1
fi

echo ""
print_color $GREEN "🎉 Installation Complete!"
echo ""
print_color $BLUE "✨ You can now use the login tracker from anywhere:"
echo ""
print_color $GREEN "Basic Usage:"
echo "  $SYMLINK_NAME                    # Analyze last 30 days"
echo "  $SYMLINK_NAME -d 7               # Analyze last 7 days"
echo "  $SYMLINK_NAME -o report.csv      # Save to custom file"
echo "  $SYMLINK_NAME --help             # Show all options"
echo ""
print_color $BLUE "📊 Quick Example - Generate a weekly report:"
echo "  $SYMLINK_NAME -d 7 -o weekly_report.csv"
echo ""
print_color $BLUE "🔄 To update to the latest version in the future:"
echo "  $SYMLINK_NAME --update"
echo ""
print_color $GREEN "Happy time tracking! ⏰"