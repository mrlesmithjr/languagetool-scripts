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

# Command line flags
DRY_RUN=false
FORCE_MODE=false
YES_MODE=false

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -d|--dry-run) DRY_RUN=true ;;   # Enable dry-run mode (skip actual deletion)
    -f|--force) FORCE_MODE=true ;;   # Skip validation checks if --force flag is provided
    -y|--yes) YES_MODE=true ;;       # Auto-confirm deletion
    -h|--help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  -d, --dry-run   Simulate the uninstallation without deleting any files"
      echo "  -f, --force     Skip validation checks and remove LanguageTool files directly"
      echo "  -y, --yes       Automatically confirm deletion without prompting"
      echo "  -h, --help      Show this help message"
      exit 0
      ;;
    *) echo "Unknown parameter: $1"; echo "Use -h or --help for usage information"; exit 1 ;;
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

# Print warning message (non-fatal)
warning() {
  echo -e "${YELLOW}⚠ $1${NC}"
}

# Print error message and exit
fail() {
  echo -e "${RED}✗ $1${NC}"
  exit 1
}

section "LanguageTool Uninstallation Process"

# Confirm uninstallation unless --yes or --force flag is provided
if [ "$YES_MODE" = false ] && [ "$FORCE_MODE" = false ]; then
  read -p "Are you sure you want to uninstall LanguageTool? This will remove the local server and all related files. (y/n) " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Uninstallation cancelled."
    exit 0
  fi
else
  if [ "$FORCE_MODE" = true ]; then
    step "Running in force mode - skipping validation and confirmation"
  else
    step "Running in auto-confirm mode - skipping confirmation"
  fi
fi

# Validation checks (only if not in force mode)
if [ "$FORCE_MODE" = false ]; then
  # Check if LanguageTool is installed
  if [ ! -d "$INSTALL_DIR" ]; then
    warning "LanguageTool installation directory not found at $INSTALL_DIR"
    if [ -f "$PLIST" ]; then
      step "However, service configuration exists - will remove that"
    else
      warning "No LanguageTool installation found to uninstall"
      exit 0
    fi
  fi

  # Check if the server is running
  step "Checking if LanguageTool server is running..."
  if pgrep -f languagetool-server.jar > /dev/null; then
    success "LanguageTool server is running"
    
    # Verify if the server's API is accessible
    step "Verifying LanguageTool server API..."
    if curl -s http://localhost:8081/v2/check > /dev/null; then
      success "LanguageTool API is responding"
    else
      warning "LanguageTool API is not responding, but will proceed with uninstallation"
    fi
  else
    warning "LanguageTool server is not running, but will proceed with uninstallation"
  fi
fi

# Stop running LanguageTool processes
step "Stopping LanguageTool server processes..."
if [ "$DRY_RUN" = true ]; then
  echo "Dry-run mode: Stopping LanguageTool server processes (skipped)"
else
  # Use multiple approaches to ensure the process is stopped
  pkill -f languagetool-server.jar 2>/dev/null || true
  sleep 1
  
  # If process is still running, try a more forceful approach
  if pgrep -f languagetool-server.jar > /dev/null; then
    warning "Process still running, trying forceful termination..."
    pkill -9 -f languagetool-server.jar 2>/dev/null || true
    sleep 1
    
    if pgrep -f languagetool-server.jar > /dev/null; then
      warning "Unable to terminate LanguageTool processes - they may need to be stopped manually"
    else
      success "Stopped LanguageTool processes with forceful termination"
    fi
  else
    # Either the process was never running or we successfully stopped it
    if [ "$FORCE_MODE" = true ] || ! pgrep -f languagetool-server.jar > /dev/null 2>&1; then
      success "No running LanguageTool processes detected"
    else
      success "Stopped LanguageTool server processes"
    fi
  fi
fi

# Unload launchd service
step "Unloading launchd service..."
if [ "$DRY_RUN" = true ]; then
  echo "Dry-run mode: Unloading launchd service (skipped)"
else
  if [ -f "$PLIST" ]; then
    launchctl unload "$PLIST" 2>/dev/null || true
    success "Unloaded launchd service"
  else
    warning "No launchd service configuration found"
  fi
fi

# Remove launchd service configuration
step "Removing launchd service configuration..."
if [ "$DRY_RUN" = true ]; then
  echo "Dry-run mode: Removing launchd service configuration (skipped)"
else
  if [ -f "$PLIST" ]; then
    rm -f "$PLIST"
    success "Removed LanguageTool service configuration"
  else
    warning "No LanguageTool service configuration found"
  fi
  
  # Check for backup files
  if [ -f "${PLIST}.backup" ]; then
    rm -f "${PLIST}.backup"
    success "Removed backup service configuration"
  fi
fi

# Remove LanguageTool files
step "Removing LanguageTool installation directory..."
if [ "$DRY_RUN" = true ]; then
  echo "Dry-run mode: Removing LanguageTool installation directory (skipped)"
else
  if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    success "Removed LanguageTool files"
  else
    warning "No LanguageTool installation directory found"
  fi
fi

# Clean up temporary files
step "Cleaning up temporary files..."
if [ "$DRY_RUN" = true ]; then
  echo "Dry-run mode: Cleaning up temporary files (skipped)"
else
  rm -f /tmp/languagetool.out /tmp/languagetool.err /tmp/languagetool.log
  success "Cleaned up temporary files"
fi

if [ "$DRY_RUN" = true ]; then
  section "Dry Run Complete"
  echo -e "${GREEN}This was a dry run. No files were actually deleted.${NC}"
else
  section "Uninstallation Complete"
  echo -e "${GREEN}LanguageTool has been successfully removed from your system.${NC}"
fi
