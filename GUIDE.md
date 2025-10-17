# Home Directory Permission Fix Guide for Bazzite/Fedora

This guide explains how to use the `fix_home_permissions.sh` script to fix ownership and permissions issues in your home directory on Bazzite or Fedora systems.

## Overview

The script provides comprehensive permission fixing for home directories, with support for selective fixing of specific permission types. It's particularly useful for Bazzite users dealing with podman-compose, gaming applications, and SELinux compatibility issues.

## Quick Start

### Fix Everything (Default)
```bash
sudo bash fix_home_permissions.sh
```

### Fix Specific Issues
```bash
# Fix only ownership
sudo bash fix_home_permissions.sh -o

# Fix only permissions
sudo bash fix_home_permissions.sh -p

# Fix only SELinux settings
sudo bash fix_home_permissions.sh -s

# Fix only special directories
sudo bash fix_home_permissions.sh -d

# Fix only NTFS drive permissions
sudo bash fix_home_permissions.sh -n

# Fix only executable permissions
sudo bash fix_home_permissions.sh -e

# Fix only UMU compatibility
sudo bash fix_home_permissions.sh -u

# Run verification only
sudo bash fix_home_permissions.sh -v
```

## Command Line Options

| Option | Long Form | Description |
|--------|-----------|-------------|
| `-a` | `--all` | Fix all permissions (default) |
| `-o` | `--ownership` | Fix ownership only |
| `-p` | `--permissions` | Fix file/directory permissions only |
| `-s` | `--selinux` | Fix SELinux settings and labels only |
| `-d` | `--special` | Fix special directories only |
| `-n` | `--ntfs` | Fix NTFS drive permissions only |
| `-e` | `--executables` | Fix executable permissions only |
| `-u` | `--umu` | Fix UMU compatibility for Flatpaks |
| `-v` | `--verify` | Run verification only |
| `--skip-backup` | N/A | Skip creating permission backups |
| `--enable-selinux` | N/A | Enable SELinux instead of disabling |
| `--disable-selinux` | N/A | Disable SELinux (default SELinux behavior) |
| `-h` | `--help` | Show help message |

## Detailed Usage

### Basic Syntax
```bash
sudo bash fix_home_permissions.sh [options] [username] [home_path]
```

### Parameters
- `username`: Target user (defaults to current user or SUDO_USER)
- `home_path`: Home directory path (defaults to /home/username)

### Examples

#### Fix permissions for current user
```bash
sudo bash fix_home_permissions.sh
```

#### Fix permissions for specific user
```bash
sudo bash fix_home_permissions.sh kiaos
```

#### Fix permissions for user with custom home path
```bash
sudo bash fix_home_permissions.sh kiaos /home/kiaos
```

#### Combine options
```bash
# Fix ownership and permissions only
sudo bash fix_home_permissions.sh -o -p

# Fix SELinux and special directories
sudo bash fix_home_permissions.sh -s -d
```

## What Each Option Does

### Ownership (`-o`, `--ownership`)
- Recursively changes ownership of entire home directory to `user:user`
- Essential for fixing permission denied errors

### Permissions (`-p`, `--permissions`)
- Sets directory permissions to `755` (rwxr-xr-x)
- Sets file permissions to `644` (rw-r--r--) for regular files
- Sets executable permissions to `755` (rwxr-xr-x) for executable files

### SELinux (`-s`, `--selinux`)
- **Default behavior**: Disables SELinux permanently in `/etc/selinux/config`
- **With `--enable-selinux`**: Enables SELinux and sets to enforcing mode
- **With `--disable-selinux`**: Disables SELinux (same as default)
- Restores SELinux contexts using `restorecon`
- Sets specific SELinux labels for common directories:
  - Home directory: `user_home_dir_t`
  - `.ssh`: `ssh_home_t`
  - `.config`, `.local`, etc.: `user_home_t`
  - Docker/Podman dirs: `container_file_t`

### Special Directories (`-d`, `--special`)
Fixes permissions for gaming and application directories:
- `.ssh` (700 for directory, 600 for files)
- `.config`, `.local`, `.cache`, `.mozilla`, `.steam`
- Steam directories
- UMU runtime directories (for Proton compatibility)
- Flatpak UMU applications
- Heroic Games Launcher
- Docker/Podman directories
- Gaming applications (Lutris, Wine prefixes)
- Proton compatibility tools
- Script directories

### NTFS Drives (`-n`, `--ntfs`)
Fixes permissions on mounted NTFS drives for better accessibility:
- Detects mounted NTFS filesystems automatically using system mount information
- **Automatically detects Windows installations** (by presence of `Windows/`, `Program Files/`, `Users/` directories or `BOOTMGR` file) and leaves them unchanged
- Sets ownership to target user for all files and directories
- Sets directory permissions to `755` (rwxr-xr-x)
- Sets file permissions to `644` (rw-r--r--) for regular files
- Makes executable files (`.exe`, `.sh`, `.bat`, etc.) executable
- Only affects actually mounted NTFS drives (leaves unmounted drives untouched)
- Ensures any user account can access drive contents
- Allows any program run by current user to use drive contents

### Executables (`-e`, `--executables`)
Ensures files that should be executable have the correct permissions:
- **File extensions**: Makes `.sh`, `.bash`, `.zsh`, `.fish`, `.py`, `.pl`, `.rb`, `.php`, `.exe`, `.bat`, `.cmd`, `.com`, `.msi`, `.jar`, `.appimage`, `.run`, `.bin`, `.deb`, `.rpm` files executable
- **Common names**: Makes files named `umu`, `umu-run`, `run`, `run-in-*`, `start`, `launch`, `install`, `setup`, `configure`, `makefile`, `gradlew`, `mvnw` executable
- **Directories**: Checks `~/.local/bin`, `~/bin`, `~/scripts`, `~/tools`, UMU directories, gaming folders, and AppImage directories
- **Shebang detection**: Finds scripts with `#!/` shebang lines and makes them executable
- **Special tools**: Fixes Steam compatibility tools, Proton installations, and Lutris runners
- Only affects files that are not already executable (safe to run multiple times)

### UMU Compatibility (`-u`, `--umu`)
Fixes UMU (Unified Minecraft Updater) compatibility issues with Flatpak applications:
- **Flatpak Overrides**: Grants Flatpak apps (Heroic, Bottles, Lutris, Steam) access to UMU directories
- **Filesystem Access**: Allows read access to `~/.local/share/umu`, `~/.var/app`, `~/.steam`, and game directories
- **Device Access**: Grants GPU, controller, and hardware access for gaming
- **Audio/Video**: Enables X11, Wayland, and PulseAudio access
- **Heroic Special Fixes**: Applies specific overrides for Heroic Games Launcher configuration
- **SELinux Check**: Warns if SELinux might interfere with UMU operations
- **Executable Setup**: Ensures all UMU binaries have correct permissions
- **Note**: SELinux disabled = better UMU compatibility with Flatpaks

### Verification (`-v`, `--verify`)
- Checks home directory ownership and permissions
- Validates key subdirectories
- Tests podman-compose configurations
- Verifies volume ownership for containers

### Backup Control
- **Default**: Creates backup of current permissions before making changes
- **With `--skip-backup`**: Skips backup creation for faster execution
- Backup location: `~/permission_backup_YYYYMMDD_HHMMSS/`
- Contains: file permissions, directory permissions, and directory listing
- Use backups to restore if something goes wrong

## Common Use Cases

### After Fresh Bazzite Install
```bash
sudo bash fix_home_permissions.sh
```

### Fix Podman-Compose Issues
```bash
sudo bash fix_home_permissions.sh -o -d -v
```

### Gaming Permission Issues
```bash
sudo bash fix_home_permissions.sh -d -s
```

### SELinux Boot Problems
```bash
sudo bash fix_home_permissions.sh -s
```

### NTFS Drive Access Issues
```bash
sudo bash fix_home_permissions.sh -n
```

### Executable Permission Issues
```bash
sudo bash fix_home_permissions.sh -e
```

### UMU Flatpak Compatibility Issues
```bash
sudo bash fix_home_permissions.sh -u
```

### Quick Ownership Fix
```bash
sudo bash fix_home_permissions.sh -o
```

### Fast Execution (Skip Backup)
```bash
sudo bash fix_home_permissions.sh --skip-backup
```

### Enable SELinux
```bash
sudo bash fix_home_permissions.sh -s --enable-selinux
```

### Disable SELinux Explicitly
```bash
sudo bash fix_home_permissions.sh -s --disable-selinux
```

## Troubleshooting

### Script Won't Run
- Ensure you're running with `sudo`
- Check that the script has execute permissions: `chmod +x fix_home_permissions.sh`

### SELinux Tools Not Available
- The script will skip SELinux operations if tools aren't installed
- This is normal on some minimal Fedora installations

### Permission Denied on Home Directory
- Make sure you're running as root/sudo
- Check that the target user exists

### Podman-Compose Validation Fails
- Ensure podman-compose is installed
- Check that docker-compose.yml files exist in the expected locations

## Safety Features

- **Backup Creation**: The script creates timestamped backups (currently disabled for speed)
- **Non-Destructive**: All operations are reversible
- **Verification**: Built-in checks to ensure fixes worked
- **Error Handling**: Continues execution even if some operations fail

## Advanced Usage

### Custom Home Directory
```bash
sudo bash fix_home_permissions.sh -a customuser /opt/customhome
```

### Selective SELinux Fixing
```bash
# Only fix SELinux labels without changing enforcement
sudo bash fix_home_permissions.sh -s -- username
```

### Batch Processing
```bash
# Fix multiple users (run separately for each)
for user in user1 user2 user3; do
    sudo bash fix_home_permissions.sh -a "$user"
done
```

## Output Explanation

The script provides colored output:
- **Blue**: Information and progress
- **Green**: Success messages and completion
- **Yellow**: Warnings (non-critical issues)
- **Red**: Errors (critical issues)

## Requirements

- Bash shell
- Root/sudo access
- Basic Unix tools (chmod, chown, find, etc.)
- SELinux tools (optional, for SELinux operations)
- podman-compose (optional, for validation)

## Compatibility

- **Bazzite** (all variants)
- **Fedora** (including Kinoite, Silverblue)
- **RHEL/CentOS** (with modifications)
- **Other RPM-based distributions**

## Support

If you encounter issues:
1. Run with `--help` for usage information
2. Check the verification output for specific errors
3. Review system logs for SELinux or permission issues
4. Ensure all required tools are installed

## Changelog

- **v6.0**: Added backup control and SELinux enable/disable options
- **v5.0**: Added UMU compatibility fixing for Flatpaks
- **v4.0**: Added executable permission fixing system
- **v3.0**: Added NTFS drive permission fixing
- **v2.0**: Added selective fixing options
- **v1.0**: Initial comprehensive permission fixing</content>
<parameter name="filePath">/home/Kiaos/permission-fixes/GUIDE.md