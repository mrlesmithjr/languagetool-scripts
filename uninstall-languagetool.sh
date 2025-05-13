#!/bin/bash

# LanguageTool Uninstaller for macOS
# Completely removes LanguageTool and related configuration

set -e  # Exit on error

# Color output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="$HOME/.languagetool"
PLIST="$HOME/Library/LaunchAgents/org.languagetool.server.plist"

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

section "LanguageTool Uninstaller"

# Confirm uninstallation
read -p "Are you sure you want to uninstall LanguageTool? (y/n) " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Uninstall cancelled."
  exit 0
fi

# Stop any running processes
step "Stopping LanguageTool processes..."
if pgrep -f languagetool-server.jar > /dev/null; then
  pkill -f languagetool-server.jar
  success "Stopped running processes"
else
  echo "No running LanguageTool processes found"
fi

# Unload the service
step "Removing launchd service..."
if launchctl list | grep -q "org.languagetool.server"; then
  launchctl unload "$PLIST" 2>/dev/null || true
  success "Service unloaded"
else
  echo "No loaded service found"
fi

# Remove plist files
if [ -f "$PLIST" ]; then
  rm -f "$PLIST"
  success "Removed service configuration"
fi

if [ -f "$PLIST.backup" ]; then
  rm -f "$PLIST.backup"
  success "Removed backup service configuration"
fi

# Remove installation directory
if [ -d "$INSTALL_DIR" ]; then
  step "Removing LanguageTool files..."
  rm -rf "$INSTALL_DIR"
  success "Removed installation directory"
fi

# Clean up log files
step "Cleaning up log files..."
rm -f /tmp/languagetool.out /tmp/languagetool.err
success "Removed log files"

# Note: This script intentionally does not remove Java, as it might be used by other applications

section "Uninstallation Complete"
echo -e "${GREEN}LanguageTool has been completely removed from your system.${NC}"
