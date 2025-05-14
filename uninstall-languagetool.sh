#!/bin/bash

# LanguageTool Uninstaller for macOS
# Completely removes LanguageTool and related configurations.
# This script is part of a privacy-focused solution for offline grammar and spell checking.

set -e  # Exit on error

# Color output for better readability
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="$HOME/.languagetool"          # Default installation directory
PLIST="$HOME/Library/LaunchAgents/org.languagetool.server.plist"  # launchd service configuration file

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

section "LanguageTool Uninstallation Process"

# Confirm uninstallation
read -p "Are you sure you want to uninstall LanguageTool? This will remove the local server and all related files. (y/n) " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Uninstallation cancelled."
  exit 0
fi

# Check if the server is running
step "Checking if LanguageTool server is running..."
if pgrep -f languagetool-server.jar > /dev/null; then
  step "LanguageTool server is running."
else
  fail "LanguageTool server is not running. Please ensure the server is active before uninstalling."
fi

# Stop any running LanguageTool processes
step "Stopping any running LanguageTool processes..."
if pgrep -f languagetool-server.jar > /dev/null; then
  pkill -f languagetool-server.jar
  success "Stopped LanguageTool server processes"
else
  echo "No running LanguageTool processes found"
fi

# Remove launchd service (if loaded)
step "Removing launchd service..."
if launchctl list | grep -q "org.languagetool.server"; then
  launchctl unload "$PLIST" 2>/dev/null || true
  success "LanguageTool launchd service unloaded"
else
  echo "No loaded LanguageTool service found"
fi

# Remove plist configuration files
step "Removing service configuration files..."
if [ -f "$PLIST" ]; then
  rm -f "$PLIST"
  success "Removed LanguageTool service configuration"
else
  echo "No LanguageTool plist configuration found"
fi

# Remove backup plist configuration file
if [ -f "$PLIST.backup" ]; then
  rm -f "$PLIST.backup"
  success "Removed backup service configuration"
fi

# Remove LanguageTool installation files
if [ -d "$INSTALL_DIR" ]; then
  step "Removing LanguageTool installation directory..."
  rm -rf "$INSTALL_DIR"
  success "Removed LanguageTool installation files"
else
  echo "No installation directory found at $INSTALL_DIR"
fi

# Clean up temporary log files
step "Cleaning up log files..."
rm -f /tmp/languagetool.out /tmp/languagetool.err
success "Removed LanguageTool log files"

# Note: This script intentionally does not remove Java, as it might be used by other applications on your system

section "Uninstallation Complete"
echo -e "${GREEN}LanguageTool has been successfully removed from your system.${NC}"
