#!/bin/bash

# LanguageTool Uninstaller for macOS
# Completely removes LanguageTool and related configurations.
# This script is part of a privacy-focused solution for offline grammar and spell checking.

set -e  # Exit on error

# Color output for readability
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="$HOME/.languagetool"          # Default installation directory
PLIST="$HOME/Library/LaunchAgents/org.languagetool.server.plist"  # launchd service configuration file
LANGUAGETOOL_SERVER_JAR="$INSTALL_DIR/LanguageTool-6.6/languagetool-server.jar"  # Path to languagetool-server.jar

# Force mode flag (for CI environments)
FORCE_MODE=false

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -f|--force) FORCE_MODE=true ;;   # Skip validation checks if --force flag is provided
    -h|--help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  -f, --force   Skip validation checks and remove LanguageTool files directly"
      exit 0
      ;;
    *) echo "Unknown parameter: $1"; exit 1 ;;
  esac
  shift
done

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

# Skip validation checks in CI environments or if --force flag is set
if [ "$FORCE_MODE" = true ]; then
  step "Running in force mode - skipping validation checks"
else
  # Step 1: Check if the server is running
  step "Checking if LanguageTool server is running..."
  if pgrep -f languagetool-server.jar > /dev/null; then
    step "LanguageTool server is running."
  else
    fail "LanguageTool server is not running. Cannot uninstall."
  fi

  # Step 2: Verify if the server's API is accessible
  step "Verifying LanguageTool server API..."
  if curl -s http://localhost:8081/v2/check > /dev/null; then
    success "LanguageTool API is responding."
  else
    fail "LanguageTool API is not responding. Ensure the server is configured correctly."
  fi
fi

# Step 3: Stop running LanguageTool processes
step "Stopping LanguageTool server..."
if pgrep -f languagetool-server.jar > /dev/null; then
  pkill -f languagetool-server.jar
  success "Stopped LanguageTool server processes."
else
  echo "No running LanguageTool processes found."
fi

# Step 4: Remove launchd service configuration
step "Removing launchd service..."
if [ -f "$PLIST" ]; then
  rm -f "$PLIST"
  success "Removed LanguageTool service configuration."
else
  echo "No LanguageTool service found."
fi

# Step 5: Remove LanguageTool files
step "Removing LanguageTool installation directory..."
if [ -d "$INSTALL_DIR" ]; then
  rm -rf "$INSTALL_DIR"
  success "Removed LanguageTool files."
else
  echo "No LanguageTool installation directory found at $INSTALL_DIR."
fi

# Step 6: Clean up temporary files
step "Cleaning up temporary files..."
rm -f /tmp/languagetool.out /tmp/languagetool.err /tmp/languagetool.log
success "Cleaned up temporary files."

section "Uninstallation Complete"
echo -e "${GREEN}LanguageTool has been successfully removed from your system.${NC}"
