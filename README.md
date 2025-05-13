# LanguageTool for macOS with Obsidian Integration

This repository contains scripts to set up a local LanguageTool server on macOS that works with Obsidian and other applications. It provides a privacy-focused alternative to cloud-based grammar checkers like Grammarly.

## Features

- ✅ **Complete Privacy**: All grammar and spell checking happens locally on your machine
- ✅ **No Usage Limits**: Unlimited checking without subscription fees
- ✅ **Automatic Startup**: Server starts automatically when you log in
- ✅ **Obsidian Integration**: Works seamlessly with the Obsidian LanguageTool plugin
- ✅ **Easy Updates**: Simple command to update to newer versions
- ✅ **Version Flexibility**: Install official releases or development snapshots

## Requirements

- macOS (tested on macOS 12 and later)
- [Homebrew](https://brew.sh/) (will be installed if not present)
- At least 1GB of free disk space

## Installation

1. Clone this repository or download the scripts
2. Make the scripts executable:
   ```bash
   chmod +x install-languagetool.sh uninstall-languagetool.sh
   ```
3. Run the installation script:
   ```bash
   ./install-languagetool.sh
   ```

The script will:

- Install Java if needed
- Download and configure LanguageTool
- Set up automatic startup via launchd
- Display configuration instructions for Obsidian

## Updating

To update to a newer version of LanguageTool:

```bash
# Update to the latest official release
./install-languagetool.sh --version 6.6

# Update to a development snapshot
./install-languagetool.sh --version 20250508-snapshot --snapshot
```

## Obsidian Configuration

After installation:

1. Install the LanguageTool plugin from Obsidian's Community Plugins
2. Configure the plugin with:
   - Server URL: `http://localhost:8081`
   - Ensure "Auto check on file open" and "Auto check on text change" are enabled

## Uninstallation

To remove LanguageTool completely:

```bash
./uninstall-languagetool.sh
```

## Troubleshooting

If you encounter issues:

- Check server logs: `cat /tmp/languagetool.err`
- Verify the server is running: `curl -I http://localhost:8081`
- Test the API: `curl -d "language=en-US&text=This is a test." http://localhost:8081/v2/check`
- Restart the service:
  ```bash
  launchctl unload ~/Library/LaunchAgents/org.languagetool.server.plist
  launchctl load ~/Library/LaunchAgents/org.languagetool.server.plist
  ```

## Advanced Usage

The installation script supports several options:

```
Usage: ./install-languagetool.sh [options]
Options:
  -v, --version VERSION   Specify LanguageTool version (default: 6.6)
  -s, --snapshot          Use snapshot version from internal repository
  -p, --port PORT         Specify port for the server (default: 8081)
  -h, --help              Show this help message
```

## Credits

- [LanguageTool](https://languagetool.org/) - Open-source proofreading software
- This setup is inspired by the need for a privacy-focused grammar checking solution
- Special thanks to the Obsidian community for plugin development

## License

These scripts are provided under the MIT License.
