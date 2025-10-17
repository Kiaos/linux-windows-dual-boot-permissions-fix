# Permission Fixes Workspace

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This workspace contains scripts to fix common permission issues on Linux systems, particularly for gaming and application directories.

## Scripts

- `fix_home_permissions.sh`: Comprehensive script to fix ownership and permissions for the entire home directory, with special handling for gaming applications like Steam, Heroic, Lutris, and Wine.

## Usage

Run the script with sudo:

```bash
sudo bash fix_home_permissions.sh [username] [home_path]
```

If no arguments are provided, it uses the current user and their home directory.

## What it fixes

- Sets correct ownership (user:user) for all files and directories
- Sets directory permissions to 755
- Sets file permissions to 644 (755 for executables)
- Special handling for:
  - SSH keys (.ssh)
  - Configuration directories (.config, .local, etc.)
  - Gaming directories (Steam, Heroic, Lutris, Wine prefixes)
  - AppImages
  - Proton compatibility tools
  - Docker/Podman containers
- Restores SELinux contexts

## Safety

The script creates a backup of current permissions before making changes. Check the backup directory if you need to restore anything.

## Requirements

- Bash shell
- sudo access
- SELinux tools (optional, for context restoration)

## Credits

This project was developed with assistance from:

- **GitHub Copilot** - AI-powered code completion and suggestions in VS Code
- **Grok** - Fast AI assistance for code development and problem-solving

Special thanks to the open-source community and the Bazzite/Fedora communities for their contributions and support.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

The MIT License allows anyone to:
- Use this software for any purpose
- Modify and distribute the software
- Fork and create derivative works
- Use commercially
- Private use

Just keep the original copyright notice and license text in all copies.