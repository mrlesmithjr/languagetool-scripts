# LanguageTool Setup for macOS with Obsidian and VSCode Integration

This repository contains scripts to set up a **local LanguageTool server** on **macOS**, providing a **privacy-focused alternative** to cloud-based grammar checkers like **Grammarly**. It enables seamless integration with tools like **Obsidian**, **VSCode**, and other text editors for offline grammar and spell checking.

## Features

- ✅ **Complete Privacy**: Grammar and spell checking happens **locally** on your machine—no data sent to external servers.
- ✅ **Unlimited Usage**: No daily usage limits or subscription fees.
- ✅ **Automatic Startup**: LanguageTool server starts automatically when you log in to your macOS system.
- ✅ **Seamless Obsidian Integration**: Easily integrates with the **Obsidian LanguageTool plugin** for grammar checking within your notes.
- ✅ **VSCode Integration**: Supports real-time grammar checking in **VSCode** via the **LTeX extension**.
- ✅ **Simple Updates**: A simple command to update **LanguageTool** to the latest version or snapshots.
- ✅ **Customizable Version**: Install official releases or development snapshots based on your needs.

## Requirements

- **macOS** (Tested on macOS 12 and later)
- [**Homebrew**](https://brew.sh/) (installed automatically if not present)
- **Java 17** or higher (install via Homebrew if necessary)
- At least **1GB of free disk space**

## Installation

1. Clone this repository or download the scripts:

   ```bash
   git clone https://github.com/mrlesmithjr/languagetool-scripts.git
   cd languagetool-scripts
   ```

2. Make the scripts executable:

   ```bash
   chmod +x install-languagetool.sh uninstall-languagetool.sh
   ```

3. Run the installation script:
   ```bash
   ./install-languagetool.sh
   ```

The script will:

- Install **Java** if it’s not already installed.
- Download and configure **LanguageTool**.
- Set up **launchd** for automatic startup on macOS.
- Provide instructions for integrating **Obsidian** and **VSCode** with the local LanguageTool server.

## Updating LanguageTool

To update **LanguageTool** to a newer version, run:

```bash
# Update to the latest official release
./install-languagetool.sh --version 6.6

# Update to a development snapshot
./install-languagetool.sh --version 20250508-snapshot --snapshot
```

## Obsidian Configuration

Once LanguageTool is installed:

1. Install the **LanguageTool** plugin from the **Obsidian Community Plugins** store.
2. Configure the plugin with the following settings:
   - **Server URL**: `http://localhost:8081`
   - Enable **"Auto check on file open"** and **"Auto check on text change"** for real-time grammar checking.

## VSCode Configuration

For **VSCode** integration, use the **LTeX extension** to connect to the **local LanguageTool server**:

1. Install the **LTeX** extension in **VSCode**.
2. Configure the extension to use your local server:
   ```json
   {
     "ltex.server": "http://127.0.0.1:8081",
     "ltex.enabled": true,
     "ltex.language": "en",
     "ltex.autoCheck": true
   }
   ```

## Uninstallation

To remove **LanguageTool** completely from your system:

```bash
./uninstall-languagetool.sh
```

## Troubleshooting

If you encounter issues:

- Check server logs: `cat /tmp/languagetool.err`
- Verify the server is running: `curl -I http://localhost:8081`
- Test the API directly: `curl -d "language=en-US&text=This is a test." http://localhost:8081/v2/check`
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

- **LanguageTool** - Open-source proofreading software.
- This setup is inspired by the need for a **privacy-focused grammar checking solution**.
- Special thanks to the **Obsidian** and **VSCode** communities for their plugin development.

## License

These scripts are provided under the **MIT License**.
