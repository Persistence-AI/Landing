#!/bin/bash
# PersistenceAI Web Installer (Bash)
# This script can be downloaded and executed via:
#   curl -fsSL https://persistenceai.com/install | bash
#   wget -qO- https://persistenceai.com/install | bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

echo ""
echo -e "${MAGENTA}╔════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║     PersistenceAI Installer           ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════╝${NC}"
echo ""

# Configuration
BASE_URL="https://persistence-ai.github.io/Landing"
APP_NAME="persistenceai"
INSTALL_DIR="$HOME/.persistenceai/bin"
TEMP_DIR=$(mktemp -d)

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Detect platform and architecture
OS="unknown"
ARCH="unknown"

case "$(uname -s)" in
    Linux*)     OS="linux" ;;
    Darwin*)    OS="darwin" ;;
    *)          error "Unsupported operating system: $(uname -s)"; exit 1 ;;
esac

case "$(uname -m)" in
    x86_64)     ARCH="x64" ;;
    arm64|aarch64) ARCH="arm64" ;;
    *)          error "Unsupported architecture: $(uname -m)"; exit 1 ;;
esac

PLATFORM="$OS-$ARCH"
ZIP_NAME="$APP_NAME-$PLATFORM.zip"

# Check for musl (Alpine Linux)
if [ "$OS" = "linux" ] && ldd /bin/sh 2>&1 | grep -q musl; then
    PLATFORM="$OS-$ARCH-musl"
    ZIP_NAME="$APP_NAME-$PLATFORM.zip"
fi

info "Detected platform: $PLATFORM"

# Determine version
VERSION="${1:-latest}"

if [ "$VERSION" = "latest" ]; then
    info "Fetching latest version..."
    # Try website API first
    VERSION=$(curl -s "$BASE_URL/api/latest" 2>/dev/null | grep -o '"version":"[^"]*"' | cut -d'"' -f4 || echo "")
    
    # Fallback: GitHub API
    if [ -z "$VERSION" ]; then
        VERSION=$(curl -s "https://api.github.com/repos/Persistence-AI/Landing/releases/latest" 2>/dev/null | grep -o '"tag_name":"[^"]*"' | cut -d'"' -f4 | sed 's/^v//' || echo "")
    fi
    
    if [ -z "$VERSION" ]; then
        warning "Could not fetch latest version, using 'latest'"
        VERSION="latest"
    else
        info "Latest version: $VERSION"
    fi
else
    info "Installing version: $VERSION"
fi

# Build download URL
if [ "$VERSION" = "latest" ]; then
    DOWNLOAD_URL="$BASE_URL/download/$ZIP_NAME"
else
    DOWNLOAD_URL="$BASE_URL/download/v$VERSION/$ZIP_NAME"
fi

# Check if already installed
if command -v "$APP_NAME" >/dev/null 2>&1; then
    EXISTING_PATH=$(command -v "$APP_NAME")
    info "PersistenceAI is already installed at: $EXISTING_PATH"
    CURRENT_VERSION=$("$APP_NAME" --version 2>/dev/null | head -n1 || echo "unknown")
    info "Current version: $CURRENT_VERSION"
    
    if [ "$VERSION" != "latest" ] && [ "$CURRENT_VERSION" = "$VERSION" ]; then
        success "Version $VERSION is already installed!"
        exit 0
    fi
    
    read -p "Upgrade now? (y/N): " UPGRADE
    if [ "$UPGRADE" != "y" ] && [ "$UPGRADE" != "Y" ]; then
        exit 0
    fi
fi

# Create installation directory
info "Creating installation directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# Download
info "Downloading PersistenceAI from: $DOWNLOAD_URL"
ZIP_PATH="$TEMP_DIR/$ZIP_NAME"

if ! curl -fsSL -o "$ZIP_PATH" "$DOWNLOAD_URL"; then
    warning "Primary download failed, trying GitHub Releases..."
    
    # Fallback: GitHub Releases
    if [ "$VERSION" = "latest" ]; then
        GH_URL="https://github.com/Persistence-AI/Landing/releases/latest/download/persistenceai-$PLATFORM-v$VERSION.zip"
    else
        GH_URL="https://github.com/Persistence-AI/Landing/releases/download/v$VERSION/persistenceai-$PLATFORM-v$VERSION.zip"
    fi
    
    if ! curl -fsSL -o "$ZIP_PATH" "$GH_URL"; then
        error "All download methods failed"
        exit 1
    fi
    success "Download completed from GitHub"
else
    success "Download completed"
fi

# Verify download
if [ ! -f "$ZIP_PATH" ]; then
    error "Downloaded file not found"
    exit 1
fi

# Extract
info "Extracting archive..."
cd "$TEMP_DIR"
unzip -q "$ZIP_PATH" || tar -xzf "$ZIP_PATH" 2>/dev/null || {
    error "Failed to extract archive. Please ensure unzip or tar is installed."
    exit 1
}

# Find executable (could be in bin/ subdirectory or root)
EXE_PATH=""
if [ -f "bin/$APP_NAME" ]; then
    EXE_PATH="bin/$APP_NAME"
elif [ -f "$APP_NAME" ]; then
    EXE_PATH="$APP_NAME"
else
    error "Executable not found in archive"
    ls -la "$TEMP_DIR"
    exit 1
fi

# Move to install directory
TARGET_PATH="$INSTALL_DIR/$APP_NAME"
mv "$EXE_PATH" "$TARGET_PATH"
chmod +x "$TARGET_PATH"
success "Extraction completed"

# Add to PATH
SHELL_RC=""
case "$SHELL" in
    */zsh)  SHELL_RC="$HOME/.zshrc" ;;
    */bash) SHELL_RC="$HOME/.bashrc" ;;
    *)      SHELL_RC="$HOME/.profile" ;;
esac

if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    info "Adding PersistenceAI to PATH in $SHELL_RC"
    
    # Add export if not already present
    if ! grep -q "$INSTALL_DIR" "$SHELL_RC" 2>/dev/null; then
        echo "" >> "$SHELL_RC"
        echo "# PersistenceAI" >> "$SHELL_RC"
        echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$SHELL_RC"
    fi
    
    # Add to current session
    export PATH="$PATH:$INSTALL_DIR"
    success "Added to PATH"
else
    info "PersistenceAI is already in PATH"
fi

# Verify installation
info "Verifying installation..."
if [ -f "$TARGET_PATH" ]; then
    VERSION_OUTPUT=$("$TARGET_PATH" --version 2>/dev/null | head -n1 || echo "unknown")
    echo ""
    success "Installation successful!"
    echo ""
    info "PersistenceAI version: $VERSION_OUTPUT"
    info "Installation location: $INSTALL_DIR"
    echo ""
    warning "Note: You may need to restart your terminal or run 'source $SHELL_RC' for PATH changes to take effect."
    echo ""
    info "To use PersistenceAI, open a new terminal and run: $APP_NAME"
    info "For more information, visit: $BASE_URL/docs"
    echo ""
else
    error "Installation verification failed: executable not found"
    exit 1
fi

