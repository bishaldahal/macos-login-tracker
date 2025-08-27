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

print_color $BLUE "🕒 Installing macOS Login Tracker..."
echo ""

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_color $RED "❌ This tool only works on Mac computers"
    exit 1
fi

# Check if curl is available
if ! command -v curl &> /dev/null; then
    print_color $RED "❌ Unable to download. Please check your internet connection."
    exit 1
fi

# Create installation directory quietly
mkdir -p "$INSTALL_DIR" 2>/dev/null

# Download and install
print_color $BLUE "📥 Setting up your time tracker..."
if curl -fsSL "$REPO_URL/$SCRIPT_NAME" -o "$INSTALL_DIR/$SCRIPT_NAME" 2>/dev/null; then
    chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
    
    # Create symlink for easier access
    ln -sf "$INSTALL_DIR/$SCRIPT_NAME" "$INSTALL_DIR/$SYMLINK_NAME" 2>/dev/null
else
    print_color $RED "❌ Installation failed. Please check your internet connection and try again."
    exit 1
fi

# Configure command access
print_color $BLUE "⚙️  Configuring terminal access..."
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    # Detect shell and config file
    if [[ "$SHELL" == *"zsh"* ]] || [[ -n "$ZSH_VERSION" ]]; then
        SHELL_CONFIG="$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        SHELL_CONFIG="$HOME/.bash_profile"
    else
        SHELL_CONFIG="$HOME/.profile"
    fi
    
    # Add to PATH if not already there
    touch "$SHELL_CONFIG"
    if ! grep -q "export PATH.*$INSTALL_DIR" "$SHELL_CONFIG" 2>/dev/null; then
        echo "" >> "$SHELL_CONFIG"
        echo "# macOS Login Tracker" >> "$SHELL_CONFIG"
        echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$SHELL_CONFIG"
    fi
    
    # Update current session
    export PATH="$PATH:$INSTALL_DIR"
fi

# Quick test
if "$INSTALL_DIR/$SCRIPT_NAME" --help &>/dev/null; then
    print_color $GREEN "✅ Installation successful!"
else
    print_color $RED "❌ Installation failed. Please try again."
    exit 1
fi

echo ""
print_color $GREEN "🎉 All done! Your time tracker is ready to use."
echo ""
print_color $BLUE "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_color $YELLOW "💡 WHAT TO DO NEXT:"
echo ""
print_color $GREEN "1️⃣  Open a new Terminal window (or restart this one)"
echo ""
print_color $GREEN "2️⃣  Type this command to see your work hours:"
echo "   login-tracker"
echo ""
print_color $GREEN "3️⃣  Want just the last week? Try this:"
echo "   login-tracker -d 7"
echo ""
print_color $BLUE "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_color $YELLOW "� The tool will create a spreadsheet file that opens automatically"
print_color $YELLOW "📈 Perfect for tracking your office hours and productivity!"
echo ""
print_color $BLUE "Need help? Type: login-tracker --help"
print_color $GREEN "Happy time tracking! ⏰"