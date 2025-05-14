#!/bin/bash

# LanguageTool Installation & Setup Script for macOS
# This script installs a local LanguageTool server, which provides a privacy-focused alternative to cloud-based grammar checkers.
# It integrates seamlessly with tools like Obsidian, VSCode, and other text editors for offline grammar and spell-checking.

set -e  # Exit on error

# Color output for clarity
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Default configuration values
DEFAULT_VERSION="6.6"
USE_SNAPSHOT=false
PORT=8081
INSTALL_DIR="$HOME/.languagetool"
PLIST="$HOME/Library/LaunchAgents/org.languagetool.server.plist"
LANGUAGETOOL_SERVER_JAR="$INSTALL_DIR/LanguageTool-${DEFAULT_VERSION}/languagetool-server.jar"

# Parse command-line arguments for custom setup
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -v|--version) VERSION="$2"; shift ;;  # Set specific LanguageTool version
    -s|--snapshot) USE_SNAPSHOT=true ;;   # Use snapshot version for development builds
    -p|--port) PORT="$2"; shift ;;        # Set a custom server port
    -h|--help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  -v, --version VERSION   Specify LanguageTool version (default: $DEFAULT_VERSION)"
      echo "  -s, --snapshot          Use snapshot version from internal repository"
      echo "  -p, --port PORT         Specify port for the server (default: 8081)"
      echo "  -h, --help              Show this help message"
      exit 0
      ;;
    *) echo "Unknown parameter: $1"; exit 1 ;;  # Handle invalid parameters
  esac
  shift
done

# Set version if not specified
if [ -z "$VERSION" ]; then
  VERSION="$DEFAULT_VERSION"
fi

# Determine URL based on version and snapshot flag
if [ "$USE_SNAPSHOT" = true ]; then
  LT_URL="https://internal1.languagetool.org/snapshots/LanguageTool-${VERSION}.zip"
else
  LT_URL="https://languagetool.org/download/LanguageTool-${VERSION}.zip"
fi

# Print section header
section() {
  echo -e "\n${BLUE}==== $1 ====${NC}"
}

# Print step information
step() {
  echo -e "${YELLOW}→ $1${NC}"
}

# Print success message
success() {
  echo -e "${GREEN}✓ $1${NC}"
}

# Print error message and exit
fail() {
  echo -e "${RED}✗ $1${NC}"
  exit 1
}

# Step 1: Check system requirements
section "LanguageTool Setup (Version $VERSION)"
step "Using URL: $LT_URL"
step "Checking system requirements..."

# Check if Homebrew is installed
if ! command -v brew &>/dev/null; then
  echo "Homebrew is required but not installed."
  read -p "Would you like to install Homebrew now? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    fail "Homebrew is required to continue. Please install it manually and run this script again."
  fi
fi

# Step 2: Setup Java
section "Java Setup"
step "Checking for Java installation..."

# Install or update Java
brew install --quiet openjdk

# Verify Java was installed
if ! command -v java &>/dev/null; then
  step "Creating Java symlinks..."
  sudo mkdir -p /Library/Java/JavaVirtualMachines/
  sudo ln -sfn "$(brew --prefix)/opt/openjdk/libexec/openjdk.jdk" /Library/Java/JavaVirtualMachines/openjdk.jdk
  
  JAVA_PATH="$(brew --prefix)/opt/openjdk/bin"
  SHELL_CONFIG="$HOME/.zshrc"
  if [ -f "$HOME/.bash_profile" ]; then
    SHELL_CONFIG="$HOME/.bash_profile"
  fi
  
  if ! grep -q "$JAVA_PATH" "$SHELL_CONFIG"; then
    step "Adding Java to your PATH..."
    echo "export PATH=\"$JAVA_PATH:\$PATH\"" >> "$SHELL_CONFIG"
    export PATH="$JAVA_PATH:$PATH"
  fi
fi

# Get the absolute path to Java executable
JAVA_PATH=$(which java)

# Verify Java is working
if ! "$JAVA_PATH" -version &>/dev/null; then
  fail "Java installation failed. Please install Java manually and try again."
else
  JAVA_VERSION=$("$JAVA_PATH" -version 2>&1 | awk -F '"' '/version/ {print $2}')
  success "Java $JAVA_VERSION is installed and working"
fi

# Step 3: Download and Install LanguageTool
section "LanguageTool Installation"
step "Creating installation directory..."
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Backup existing LanguageTool directory if updating
if [ -d "$INSTALL_DIR/LanguageTool-$VERSION" ]; then
  step "Updating existing LanguageTool $VERSION installation..."
  launchctl unload "$PLIST" 2>/dev/null || true
  pkill -f languagetool-server.jar 2>/dev/null || true
  mv "$INSTALL_DIR/LanguageTool-$VERSION" "$INSTALL_DIR/LanguageTool-$VERSION.backup-$(date +%Y%m%d%H%M%S)"
  success "Backed up previous installation"
fi

# Download LanguageTool zip file
step "Downloading LanguageTool $VERSION..."
curl -L -o "LanguageTool-$VERSION.zip" "$LT_URL" || fail "Download failed"

# Extract downloaded files
step "Extracting files..."
unzip -o -q "LanguageTool-$VERSION.zip" || fail "Extraction failed"
rm "LanguageTool-$VERSION.zip"
success "LanguageTool files installed to $INSTALL_DIR"

# Step 4: Create launchd plist file for automatic startup
section "Service Configuration"
step "Creating launchd service..."

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>org.languagetool.server</string>
  <key>ProgramArguments</key>
  <array>
    <string>${JAVA_PATH}</string>
    <string>-Xmx512m</string>
    <string>-cp</string>
    <string>${INSTALL_DIR}/LanguageTool-${VERSION}/languagetool-server.jar</string>
    <string>org.languagetool.server.HTTPServer</string>
    <string>--port</string>
    <string>${PORT}</string>
    <string>--allow-origin</string>
    <string>*</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>WorkingDirectory</key>
  <string>${INSTALL_DIR}/LanguageTool-${VERSION}</string>
  <key>StandardOutPath</key>
  <string>/tmp/languagetool.out</string>
  <key>StandardErrorPath</key>
  <string>/tmp/languagetool.err</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>${JAVA_PATH%/*}:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>
</dict>
</plist>
EOF

success "Service configuration created"

# Step 5: Start the LanguageTool service
section "Starting LanguageTool Service"
step "Loading service..."
launchctl unload "$PLIST" 2>/dev/null || true
launchctl load "$PLIST"

# Wait for the service to start
step "Starting server..."
sleep 3

# Step 6: Verification
if curl -s "http://localhost:${PORT}" > /dev/null; then
  section "Verification"
  success "LanguageTool is running at http://localhost:${PORT}"
  echo
  echo -e "${GREEN}==========================================${NC}"
  echo -e "${GREEN}  LanguageTool $VERSION successfully installed!    ${NC}"
  echo -e "${GREEN}==========================================${NC}"
  echo
  echo "For Obsidian LanguageTool Plugin configuration:"
  echo "1. Install the LanguageTool plugin from Community Plugins"
  echo "2. Set the API URL to: http://localhost:${PORT}"
  echo "3. Enable 'Auto check on file open' and 'Auto check on text change'"
  echo
  echo "To update in the future, run: $0 --version NEW_VERSION"
  echo "To uninstall, run: ./uninstall-languagetool.sh"
  echo
else
  fail "LanguageTool server is not running. Please check the logs at /tmp/languagetool.err"
fi
