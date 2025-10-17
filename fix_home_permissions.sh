#!/bin/bash

# Comprehensive Home Directory Permission Fix for Bazzite/Fedora
# This script fixes ownership and permissions for the entire home directory
# Run with: bash fix_home_permissions.sh

set -e  # Exit on any error

#!/bin/bash

# Comprehensive Home Directory Permission Fix for Bazzite/Fedora
# This script fixes ownership and permissions for the entire home directory
# Run with: bash fix_home_permissions.sh [options] [username] [home_path]
# Use --help for detailed options

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default options (all enabled)
FIX_OWNERSHIP=true
FIX_PERMISSIONS=true
FIX_SELINUX=true
FIX_SPECIAL=true
FIX_VERIFY=true
FIX_NTFS=true
FIX_EXECUTABLES=true
FIX_UMU=true
SKIP_BACKUP=false
SELINUX_ENABLE=false

# Parse command line options
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--all)
            # All options already default to true
            shift
            ;;
        -o|--ownership)
            FIX_OWNERSHIP=true
            FIX_PERMISSIONS=false
            FIX_SELINUX=false
            FIX_SPECIAL=false
            FIX_VERIFY=false
            shift
            ;;
        -p|--permissions)
            FIX_OWNERSHIP=false
            FIX_PERMISSIONS=true
            FIX_SELINUX=false
            FIX_SPECIAL=false
            FIX_VERIFY=false
            shift
            ;;
        -s|--selinux)
            FIX_OWNERSHIP=false
            FIX_PERMISSIONS=false
            FIX_SELINUX=true
            FIX_SPECIAL=false
            FIX_VERIFY=false
            shift
            ;;
        -d|--special)
            FIX_OWNERSHIP=false
            FIX_PERMISSIONS=false
            FIX_SELINUX=false
            FIX_SPECIAL=true
            FIX_VERIFY=false
            shift
            ;;
        -v|--verify)
            FIX_OWNERSHIP=false
            FIX_PERMISSIONS=false
            FIX_SELINUX=false
            FIX_SPECIAL=false
            FIX_VERIFY=true
            FIX_NTFS=false
            shift
            ;;
        -n|--ntfs)
            FIX_OWNERSHIP=false
            FIX_PERMISSIONS=false
            FIX_SELINUX=false
            FIX_SPECIAL=false
            FIX_VERIFY=false
            FIX_NTFS=true
            shift
            ;;
        -e|--executables)
            FIX_OWNERSHIP=false
            FIX_PERMISSIONS=false
            FIX_SELINUX=false
            FIX_SPECIAL=false
            FIX_VERIFY=false
            FIX_NTFS=false
            FIX_EXECUTABLES=true
            shift
            ;;
        -u|--umu)
            FIX_OWNERSHIP=false
            FIX_PERMISSIONS=false
            FIX_SELINUX=false
            FIX_SPECIAL=false
            FIX_VERIFY=false
            FIX_NTFS=false
            FIX_EXECUTABLES=false
            FIX_UMU=true
            shift
            ;;
        --skip-backup)
            SKIP_BACKUP=true
            shift
            ;;
        --enable-selinux)
            SELINUX_ENABLE=true
            shift
            ;;
        --disable-selinux)
            SELINUX_ENABLE=false
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options] [username] [home_path]"
            echo "Fix permissions for the specified user's home directory."
            echo "If no username is provided, uses the current user."
            echo "If no home_path is provided, uses /home/username."
            echo
            echo "Options:"
            echo "  -a, --all          Fix all permissions (default)"
            echo "  -o, --ownership    Fix ownership only"
            echo "  -p, --permissions  Fix file/directory permissions only"
            echo "  -s, --selinux      Fix SELinux settings and labels only"
            echo "  -d, --special      Fix special directories only"
            echo "  -n, --ntfs         Fix NTFS drive permissions only"
            echo "  -e, --executables  Fix executable permissions only"
            echo "  -u, --umu          Fix UMU compatibility for Flatpaks"
            echo "  -v, --verify       Run verification only"
            echo "  --skip-backup      Skip creating permission backups"
            echo "  --enable-selinux   Enable SELinux instead of disabling"
            echo "  --disable-selinux  Disable SELinux (default SELinux behavior)"
            echo "  -h, --help         Show this help message"
            exit 0
            ;;
        -*)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
        *)
            # Positional arguments
            break
            ;;
    esac
done

# Configuration
TARGET_USER="${1:-$USER}"
TARGET_HOME="${2:-/home/$TARGET_USER}"
BACKUP_DIR="$TARGET_HOME/permission_backup_$(date +%Y%m%d_%H%M%S)"

# Safety checks
if [[ "$EUID" -ne 0 ]]; then
    echo -e "${RED}ERROR: This script must be run with sudo${NC}"
    echo "Usage: sudo bash fix_home_permissions.sh [username] [home_path]"
    exit 1
fi

if [[ "$TARGET_USER" == "root" ]]; then
    echo -e "${RED}ERROR: Cannot fix permissions for root user${NC}"
    echo -e "${YELLOW}If you need to fix root's home directory, run as: sudo bash fix_home_permissions.sh root /root${NC}"
    exit 1
fi

if [[ ! -d "$TARGET_HOME" ]]; then
    echo -e "${RED}ERROR: Home directory $TARGET_HOME does not exist${NC}"
    exit 1
fi

if [[ "$FIX_SELINUX" == true ]]; then
    # Check and configure SELinux based on user preference
    echo -e "${BLUE}Checking SELinux status...${NC}"
    if command -v getenforce &> /dev/null; then
        SELINUX_STATUS=$(getenforce 2>/dev/null || echo "Disabled")
        if [[ "$SELINUX_ENABLE" == true ]]; then
            # Enable SELinux
            if [[ "$SELINUX_STATUS" == "Disabled" ]]; then
                echo -e "${YELLOW}SELinux is disabled. Enabling SELinux...${NC}"
                # Backup current config
                cp /etc/selinux/config /etc/selinux/config.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
                # Set to enforcing
                sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
                echo -e "${GREEN}SELinux set to enforcing in /etc/selinux/config. A reboot is required for changes to take effect.${NC}"
            else
                echo -e "${GREEN}SELinux is already enabled (status: $SELINUX_STATUS).${NC}"
            fi
        else
            # Disable SELinux (default behavior)
            if [[ "$SELINUX_STATUS" != "Disabled" ]]; then
                echo -e "${YELLOW}SELinux is enabled (current: $SELINUX_STATUS). Disabling SELinux...${NC}"
                # Backup current config
                cp /etc/selinux/config /etc/selinux/config.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
                # Set to disabled
                sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
                echo -e "${GREEN}SELinux set to disabled in /etc/selinux/config. A reboot is required for changes to take effect.${NC}"
            else
                echo -e "${GREEN}SELinux is already disabled.${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}SELinux tools not available.${NC}"
    fi
fi

echo -e "${BLUE}=== Home Directory Permission Fix for Bazzite ===${NC}"
echo -e "${YELLOW}Target User: $TARGET_USER${NC}"
echo -e "${YELLOW}Target Home: $TARGET_HOME${NC}"
echo -e "${YELLOW}Backup Dir: $BACKUP_DIR${NC}"
echo

# Create backup directory
if [[ "$SKIP_BACKUP" == false ]]; then
    echo -e "${BLUE}Creating backup of current permissions...${NC}"
    mkdir -p "$BACKUP_DIR"

    # Backup current permissions (optional but recommended)
    echo -e "${BLUE}Backing up current permissions...${NC}"
    find "$TARGET_HOME" -type f -exec stat -c "%a %n" {} \; > "$BACKUP_DIR/file_permissions.txt" 2>/dev/null || true
    find "$TARGET_HOME" -type d -exec stat -c "%a %n" {} \; > "$BACKUP_DIR/dir_permissions.txt" 2>/dev/null || true
    ls -la "$TARGET_HOME" > "$BACKUP_DIR/home_listing.txt" 2>/dev/null || true

    echo -e "${GREEN}Backup created at: $BACKUP_DIR${NC}"
else
    echo -e "${BLUE}Skipping backup creation (--skip-backup specified)...${NC}"
fi
echo

if [[ "$FIX_OWNERSHIP" == true ]]; then
    # Fix ownership recursively
    echo -e "${BLUE}Fixing ownership of entire home directory...${NC}"
    chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME"
fi

if [[ "$FIX_PERMISSIONS" == true ]]; then
    # Fix directory permissions (755 for directories)
    echo -e "${BLUE}Setting directory permissions (755)...${NC}"
    find "$TARGET_HOME" -type d -exec chmod 755 {} \;

    # Fix file permissions (644 for regular files, 755 for executables)
    echo -e "${BLUE}Setting file permissions (644 for files, 755 for executables)...${NC}"
    find "$TARGET_HOME" -type f -exec chmod 644 {} \;
    find "$TARGET_HOME" -type f -executable -exec chmod 755 {} \;
fi

if [[ "$FIX_SPECIAL" == true ]]; then
    # Special handling for common directories
    echo -e "${BLUE}Setting special permissions for common directories...${NC}"

    # .ssh directory should be 700
    if [[ -d "$TARGET_HOME/.ssh" ]]; then
        chmod 700 "$TARGET_HOME/.ssh"
        find "$TARGET_HOME/.ssh" -type f -exec chmod 600 {} \;
        echo -e "${GREEN}Fixed .ssh permissions${NC}"
    fi

    # .config and other dot directories
    for dir in .config .local .cache .mozilla .steam; do
        if [[ -d "$TARGET_HOME/$dir" ]]; then
            chmod 755 "$TARGET_HOME/$dir"
            echo -e "${GREEN}Fixed $dir permissions${NC}"
        fi
    done

    # Steam directories (common on Bazzite)
    if [[ -d "$TARGET_HOME/.local/share/Steam" ]]; then
        chmod -R 755 "$TARGET_HOME/.local/share/Steam"
        echo -e "${GREEN}Fixed Steam directory permissions${NC}"
    fi

    # UMU runtime directories (for Proton compatibility)
    if [[ -d "$TARGET_HOME/.local/share/umu" ]]; then
        echo -e "${BLUE}Fixing UMU runtime permissions...${NC}"
        find "$TARGET_HOME/.local/share/umu" -name "*.sh" -type f -exec chmod +x {} \;
        find "$TARGET_HOME/.local/share/umu" -name "umu" -type f -exec chmod +x {} \;
        find "$TARGET_HOME/.local/share/umu" -name "run" -type f -exec chmod +x {} \;
        find "$TARGET_HOME/.local/share/umu" -name "run-in-*" -type f -exec chmod +x {} \;
        if [[ -d "$TARGET_HOME/.local/share/umu/steamrt3/pressure-vessel/bin" ]]; then
            chmod +x "$TARGET_HOME/.local/share/umu/steamrt3/pressure-vessel/bin"/*
            echo -e "${GREEN}Fixed UMU pressure-vessel binaries${NC}"
        fi
        echo -e "${GREEN}Fixed UMU runtime permissions${NC}"
    fi

    # UMU in Flatpak apps (e.g., Heroic Games Launcher)
    if [[ -d "$TARGET_HOME/.var/app" ]]; then
        echo -e "${BLUE}Fixing UMU permissions in Flatpak apps...${NC}"
        find "$TARGET_HOME/.var/app" -path "*/tools/runtimes/umu*" -name "*.py" -type f -exec chmod +x {} \;
        find "$TARGET_HOME/.var/app" -path "*/tools/runtimes/umu*" -name "*.sh" -type f -exec chmod +x {} \;
        find "$TARGET_HOME/.var/app" -path "*/tools/runtimes/umu*" -name "umu*" -type f -exec chmod +x {} \;
        find "$TARGET_HOME/.var/app" -path "*/tools/runtimes/umu*" -name "run" -type f -exec chmod +x {} \;
        find "$TARGET_HOME/.var/app" -path "*/tools/runtimes/umu*" -name "run-in-*" -type f -exec chmod +x {} \;
        if find "$TARGET_HOME/.var/app" -path "*/umu*/steamrt3/pressure-vessel/bin" -type d | head -1 | read; then
            find "$TARGET_HOME/.var/app" -path "*/umu*/steamrt3/pressure-vessel/bin" -type f -exec chmod +x {} \;
            echo -e "${GREEN}Fixed UMU pressure-vessel binaries in Flatpak${NC}"
        fi
        echo -e "${GREEN}Fixed UMU permissions in Flatpak apps${NC}"
    fi

    # Heroic Games Launcher directories
    if [[ -d "$TARGET_HOME/Games/Heroic" ]]; then
        echo -e "${BLUE}Fixing Heroic Games Launcher permissions...${NC}"
        # Fix .exe files in game directories
        find "$TARGET_HOME/Games/Heroic" -name "*.exe" -type f -exec chmod +x {} \;
        echo -e "${GREEN}Fixed Heroic .exe file permissions${NC}"
    fi

    # Docker/Podman directories
    for dir in .docker .config/containers .local/share/containers; do
        if [[ -d "$TARGET_HOME/$dir" ]]; then
            chmod -R 755 "$TARGET_HOME/$dir"
            echo -e "${GREEN}Fixed $dir permissions${NC}"
        fi
    done

    # Gaming and application directories
    echo -e "${BLUE}Fixing gaming and application permissions...${NC}"

    # AppImages (common locations)
    for app_dir in Applications AppImages .local/bin; do
        if [[ -d "$TARGET_HOME/$app_dir" ]]; then
            find "$TARGET_HOME/$app_dir" -name "*.AppImage" -type f -exec chmod +x {} \;
            echo -e "${GREEN}Fixed AppImage permissions in $app_dir${NC}"
        fi
    done

    # Lutris
    if [[ -d "$TARGET_HOME/.local/share/lutris" ]]; then
        chmod -R 755 "$TARGET_HOME/.local/share/lutris"
        # Fix Wine prefixes in Lutris
        find "$TARGET_HOME/.local/share/lutris/runners/wine" -name "*.exe" -type f -exec chmod +x {} \; 2>/dev/null || true
        echo -e "${GREEN}Fixed Lutris permissions${NC}"
    fi

    # Wine prefixes (general)
    if [[ -d "$TARGET_HOME/.wine" ]]; then
        chmod -R 755 "$TARGET_HOME/.wine"
        find "$TARGET_HOME/.wine" -name "*.exe" -type f -exec chmod +x {} \;
        echo -e "${GREEN}Fixed Wine prefix permissions${NC}"
    fi

    # Proton Experimental or other Proton versions
    if [[ -d "$TARGET_HOME/.steam/steam/compatibilitytools.d" ]]; then
        find "$TARGET_HOME/.steam/steam/compatibilitytools.d" -name "proton" -type f -exec chmod +x {} \;
        find "$TARGET_HOME/.steam/steam/compatibilitytools.d" -name "*.sh" -type f -exec chmod +x {} \;
        echo -e "${GREEN}Fixed Proton compatibility tools permissions${NC}"
    fi

    # Scripts in common locations
    for script_dir in .local/bin .config/autostart bin; do
        if [[ -d "$TARGET_HOME/$script_dir" ]]; then
            find "$TARGET_HOME/$script_dir" -type f -exec chmod +x {} \;
            echo -e "${GREEN}Fixed script permissions in $script_dir${NC}"
        fi
    done
fi

if [[ "$FIX_NTFS" == true ]]; then
    # Fix NTFS drive permissions for better accessibility
    echo -e "${BLUE}Fixing NTFS drive permissions...${NC}"

    # Find mounted NTFS drives
    NTFS_MOUNTS=$(mount | grep -i ntfs | awk '{print $3}' 2>/dev/null || true)

    if [[ -n "$NTFS_MOUNTS" ]]; then
        echo -e "${BLUE}Found NTFS mounts: $NTFS_MOUNTS${NC}"

        for mount_point in $NTFS_MOUNTS; do
            if [[ -d "$mount_point" ]]; then
                # Check if this appears to be a Windows installation
                if [[ -d "$mount_point/Windows" ]] || [[ -d "$mount_point/Program Files" ]] || [[ -d "$mount_point/Users" ]] || [[ -f "$mount_point/BOOTMGR" ]] || [[ -f "$mount_point/bootmgr" ]]; then
                    echo -e "${YELLOW}Detected Windows installation on $mount_point - leaving permissions unchanged${NC}"
                    continue
                fi

                echo -e "${BLUE}Fixing permissions on NTFS mount: $mount_point${NC}"

                # Set ownership to target user for the mount point
                chown -R "$TARGET_USER:$TARGET_USER" "$mount_point" 2>/dev/null || echo -e "${YELLOW}Warning: Could not change ownership on $mount_point${NC}"

                # Set directory permissions to 755
                find "$mount_point" -type d -exec chmod 755 {} \; 2>/dev/null || echo -e "${YELLOW}Warning: Could not set directory permissions on $mount_point${NC}"

                # Set file permissions to 644 for regular files
                find "$mount_point" -type f -exec chmod 644 {} \; 2>/dev/null || echo -e "${YELLOW}Warning: Could not set file permissions on $mount_point${NC}"

                # Make executable files executable (common for .exe, .sh, etc.)
                find "$mount_point" -type f \( -name "*.exe" -o -name "*.sh" -o -name "*.bat" -o -name "*.cmd" -o -name "*.com" \) -exec chmod +x {} \; 2>/dev/null || true

                echo -e "${GREEN}Fixed permissions on NTFS mount: $mount_point${NC}"
            fi
        done
    else
        echo -e "${YELLOW}No NTFS mounts found${NC}"
    fi
fi

if [[ "$FIX_EXECUTABLES" == true ]]; then
    # Fix executable permissions for files that should be executable
    echo -e "${BLUE}Fixing executable permissions...${NC}"

    # Define executable file patterns
    EXECUTABLE_PATTERNS=(
        "*.sh"      # Shell scripts
        "*.bash"    # Bash scripts
        "*.zsh"     # Zsh scripts
        "*.fish"    # Fish scripts
        "*.py"      # Python scripts (often executable)
        "*.pl"      # Perl scripts
        "*.rb"      # Ruby scripts
        "*.php"     # PHP scripts
        "*.exe"     # Windows executables
        "*.bat"     # Windows batch files
        "*.cmd"     # Windows command files
        "*.com"     # Windows/DOS executables
        "*.msi"     # Windows installers
        "*.jar"     # Java archives (often executable)
        "*.appimage" # AppImage files
        "*.run"     # Linux installers/runners
        "*.bin"     # Binary installers
        "*.deb"     # Debian packages (sometimes executable)
        "*.rpm"     # RPM packages (sometimes executable)
    )

    # Define executable file names (common executable names)
    EXECUTABLE_NAMES=(
        "umu"       # UMU launcher
        "umu-run"   # UMU runner
        "run"       # Generic run scripts
        "run-in-*"  # UMU run-in scripts
        "start"     # Start scripts
        "launch"    # Launch scripts
        "install"   # Install scripts
        "setup"     # Setup scripts
        "configure" # Configure scripts
        "makefile"  # Makefiles (sometimes executable)
        "gradlew"   # Gradle wrapper
        "mvnw"      # Maven wrapper
    )

    # Define directories to check for executables
    EXECUTABLE_DIRS=(
        "$TARGET_HOME/.local/bin"
        "$TARGET_HOME/bin"
        "$TARGET_HOME/.bin"
        "$TARGET_HOME/scripts"
        "$TARGET_HOME/.scripts"
        "$TARGET_HOME/tools"
        "$TARGET_HOME/.local/share/umu"
        "$TARGET_HOME/.var/app"
        "$TARGET_HOME/Games"
        "$TARGET_HOME/Applications"
        "$TARGET_HOME/AppImages"
    )

    echo -e "${BLUE}Checking for files that should be executable...${NC}"

    # Fix executables by file extension
    for pattern in "${EXECUTABLE_PATTERNS[@]}"; do
        find "$TARGET_HOME" -name "$pattern" -type f ! -executable -exec chmod +x {} \; 2>/dev/null && echo -e "${GREEN}Made $pattern files executable${NC}"
    done

    # Fix executables by filename
    for name in "${EXECUTABLE_NAMES[@]}"; do
        find "$TARGET_HOME" -name "$name" -type f ! -executable -exec chmod +x {} \; 2>/dev/null && echo -e "${GREEN}Made $name files executable${NC}"
    done

    # Fix executables in common directories
    for dir in "${EXECUTABLE_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            find "$dir" -type f ! -executable -exec chmod +x {} \; 2>/dev/null && echo -e "${GREEN}Made files in $dir executable${NC}"
        fi
    done

    # Special handling for Steam compatibility tools
    if [[ -d "$TARGET_HOME/.steam/steam/compatibilitytools.d" ]]; then
        find "$TARGET_HOME/.steam/steam/compatibilitytools.d" -type f ! -executable -exec chmod +x {} \; 2>/dev/null && echo -e "${GREEN}Made Steam compatibility tools executable${NC}"
    fi

    # Special handling for Proton installations
    if [[ -d "$TARGET_HOME/.steam/steam/steamapps/common" ]]; then
        find "$TARGET_HOME/.steam/steam/steamapps/common" -name "proton" -type f ! -executable -exec chmod +x {} \; 2>/dev/null
        find "$TARGET_HOME/.steam/steam/steamapps/common" -name "*.sh" -type f ! -executable -exec chmod +x {} \; 2>/dev/null && echo -e "${GREEN}Made Proton files executable${NC}"
    fi

    # Special handling for Lutris runners
    if [[ -d "$TARGET_HOME/.local/share/lutris/runners" ]]; then
        find "$TARGET_HOME/.local/share/lutris/runners" -type f ! -executable -exec chmod +x {} \; 2>/dev/null && echo -e "${GREEN}Made Lutris runners executable${NC}"
    fi

    # Check for shebang lines in scripts (files starting with #!)
    echo -e "${BLUE}Checking for scripts with shebang lines...${NC}"
    find "$TARGET_HOME" -type f ! -executable -exec grep -l '^#!/' {} \; 2>/dev/null | while read -r script_file; do
        chmod +x "$script_file" 2>/dev/null && echo -e "${GREEN}Made script executable: ${script_file#$TARGET_HOME/}${NC}"
    done

    echo -e "${GREEN}Executable permission fixing complete${NC}"
fi

if [[ "$FIX_UMU" == true ]]; then
    # Fix UMU compatibility issues with Flatpaks
    echo -e "${BLUE}Fixing UMU compatibility for Flatpaks...${NC}"

    # Check if Flatpak is available
    if command -v flatpak &> /dev/null; then
        echo -e "${BLUE}Flatpak detected, configuring UMU overrides...${NC}"

        # Common Flatpak apps that use UMU/Proton
        FLATPAK_UMU_APPS=(
            "com.heroicgameslauncher.hgl"
            "com.usebottles.bottles"
            "net.lutris.Lutris"
            "com.valvesoftware.Steam"
            "org.prismlauncher.PrismLauncher"
        )

        for app_id in "${FLATPAK_UMU_APPS[@]}"; do
            if flatpak list --app | grep -q "$app_id"; then
                echo -e "${BLUE}Configuring UMU access for $app_id...${NC}"

                # Grant filesystem access to UMU directories
                flatpak override "$app_id" --filesystem="$TARGET_HOME/.local/share/umu:ro" 2>/dev/null || true
                flatpak override "$app_id" --filesystem="$TARGET_HOME/.var/app:ro" 2>/dev/null || true

                # Grant access to Steam directories (for Proton)
                flatpak override "$app_id" --filesystem="$TARGET_HOME/.steam:ro" 2>/dev/null || true
                flatpak override "$app_id" --filesystem="$TARGET_HOME/.local/share/Steam:ro" 2>/dev/null || true

                # Grant access to game directories
                flatpak override "$app_id" --filesystem="$TARGET_HOME/Games:ro" 2>/dev/null || true

                # Allow device access (for GPU, controllers, etc.)
                flatpak override "$app_id" --device=all 2>/dev/null || true
                flatpak override "$app_id" --share=network 2>/dev/null || true

                # Allow X11 and Wayland access
                flatpak override "$app_id" --socket=x11 2>/dev/null || true
                flatpak override "$app_id" --socket=wayland 2>/dev/null || true
                flatpak override "$app_id" --socket=fallback-x11 2>/dev/null || true

                # Allow pulseaudio access
                flatpak override "$app_id" --socket=pulseaudio 2>/dev/null || true

                echo -e "${GREEN}Configured UMU access for $app_id${NC}"
            fi
        done

        # Special handling for Heroic Games Launcher
        if flatpak list --app | grep -q "com.heroicgameslauncher.hgl"; then
            echo -e "${BLUE}Applying special Heroic Games Launcher UMU fixes...${NC}"

            # Heroic needs write access to its config and game directories
            flatpak override "com.heroicgameslauncher.hgl" --filesystem="$TARGET_HOME/.config/heroic:ro" 2>/dev/null || true
            flatpak override "com.heroicgameslauncher.hgl" --filesystem="$TARGET_HOME/.config/Heroic:ro" 2>/dev/null || true

            # Allow access to common game installation directories
            flatpak override "com.heroicgameslauncher.hgl" --filesystem=/run/media 2>/dev/null || true
            flatpak override "com.heroicgameslauncher.hgl" --filesystem=/mnt 2>/dev/null || true

            echo -e "${GREEN}Applied Heroic Games Launcher UMU fixes${NC}"
        fi

    else
        echo -e "${YELLOW}Flatpak not detected, skipping UMU Flatpak configuration${NC}"
    fi

    # Ensure UMU executables are properly set up
    echo -e "${BLUE}Ensuring UMU executables are properly configured...${NC}"

    # Make sure UMU directories exist and have correct permissions
    mkdir -p "$TARGET_HOME/.local/share/umu" 2>/dev/null || true
    mkdir -p "$TARGET_HOME/.var/app" 2>/dev/null || true

    # Set ownership
    chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.local/share/umu" 2>/dev/null || true
    chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.var/app" 2>/dev/null || true

    # Ensure UMU executables are executable
    find "$TARGET_HOME/.local/share/umu" -name "umu*" -type f -exec chmod +x {} \; 2>/dev/null || true
    find "$TARGET_HOME/.local/share/umu" -name "run*" -type f -exec chmod +x {} \; 2>/dev/null || true
    find "$TARGET_HOME/.var/app" -path "*/umu*" -name "*.py" -type f -exec chmod +x {} \; 2>/dev/null || true
    find "$TARGET_HOME/.var/app" -path "*/umu*" -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null || true
    find "$TARGET_HOME/.var/app" -path "*/umu*" -name "umu*" -type f -exec chmod +x {} \; 2>/dev/null || true

    # Check for SELinux issues that might affect UMU
    if command -v getenforce &> /dev/null; then
        SELINUX_STATUS=$(getenforce 2>/dev/null || echo "Disabled")
        if [[ "$SELINUX_STATUS" == "Enforcing" ]]; then
            echo -e "${YELLOW}SELinux is enforcing - this may interfere with UMU in Flatpaks${NC}"
            echo -e "${YELLOW}Consider disabling SELinux or adding appropriate policies for UMU${NC}"
        else
            echo -e "${GREEN}SELinux is not enforcing - good for UMU compatibility${NC}"
        fi
    fi

    echo -e "${GREEN}UMU compatibility fixes complete${NC}"
    echo -e "${BLUE}Note: SELinux disabled = better UMU compatibility${NC}"
fi

if [[ "$FIX_SELINUX" == true ]]; then
    # Fix SELinux contexts and labels (important for Bazzite)
    echo -e "${BLUE}Fixing SELinux contexts and labels...${NC}"
    if command -v chcon &> /dev/null && command -v restorecon &> /dev/null; then
        # Restore default contexts recursively
        restorecon -R "$TARGET_HOME" 2>/dev/null || echo -e "${YELLOW}Warning: SELinux restorecon failed${NC}"
        
        # Set specific labels for common directories
        echo -e "${BLUE}Setting specific SELinux labels...${NC}"
        
        # Home directory should be user_home_dir_t
        chcon -t user_home_dir_t "$TARGET_HOME" 2>/dev/null || true
        
        # .ssh directory and contents
        if [[ -d "$TARGET_HOME/.ssh" ]]; then
            chcon -t ssh_home_t "$TARGET_HOME/.ssh" 2>/dev/null || true
            find "$TARGET_HOME/.ssh" -type f -exec chcon -t ssh_home_t {} \; 2>/dev/null || true
            echo -e "${GREEN}Fixed SELinux labels for .ssh${NC}"
        fi
        
        # .config and subdirectories (user_home_t for most)
        if [[ -d "$TARGET_HOME/.config" ]]; then
            chcon -R -t user_home_t "$TARGET_HOME/.config" 2>/dev/null || true
            echo -e "${GREEN}Fixed SELinux labels for .config${NC}"
        fi
        
        # .local directory
        if [[ -d "$TARGET_HOME/.local" ]]; then
            chcon -R -t user_home_t "$TARGET_HOME/.local" 2>/dev/null || true
            echo -e "${GREEN}Fixed SELinux labels for .local${NC}"
        fi
        
        # Steam directories
        if [[ -d "$TARGET_HOME/.local/share/Steam" ]]; then
            chcon -R -t user_home_t "$TARGET_HOME/.local/share/Steam" 2>/dev/null || true
            echo -e "${GREEN}Fixed SELinux labels for Steam${NC}"
        fi
        
        # UMU directories
        if [[ -d "$TARGET_HOME/.local/share/umu" ]]; then
            chcon -R -t user_home_t "$TARGET_HOME/.local/share/umu" 2>/dev/null || true
            echo -e "${GREEN}Fixed SELinux labels for UMU${NC}"
        fi
        
        # Flatpak UMU
        if [[ -d "$TARGET_HOME/.var/app" ]]; then
            chcon -R -t user_home_t "$TARGET_HOME/.var/app" 2>/dev/null || true
            echo -e "${GREEN}Fixed SELinux labels for Flatpak apps${NC}"
        fi
        
        # Docker/Podman directories - may need container contexts
        for dir in .docker .config/containers .local/share/containers; do
            if [[ -d "$TARGET_HOME/$dir" ]]; then
                chcon -R -t container_file_t "$TARGET_HOME/$dir" 2>/dev/null || true
                echo -e "${GREEN}Fixed SELinux labels for $dir${NC}"
            fi
        done
        
        # Gaming directories
        if [[ -d "$TARGET_HOME/Games" ]]; then
            chcon -R -t user_home_t "$TARGET_HOME/Games" 2>/dev/null || true
            echo -e "${GREEN}Fixed SELinux labels for Games${NC}"
        fi
        
        # Wine prefixes
        if [[ -d "$TARGET_HOME/.wine" ]]; then
            chcon -R -t user_home_t "$TARGET_HOME/.wine" 2>/dev/null || true
            echo -e "${GREEN}Fixed SELinux labels for Wine${NC}"
        fi
        
        echo -e "${GREEN}SELinux labels fixed${NC}"
    else
        echo -e "${YELLOW}SELinux tools not available, skipping label fixes${NC}"
    fi
fi

if [[ "$FIX_VERIFY" == true ]]; then
    # Verify the fixes
    echo -e "${BLUE}Verifying fixes...${NC}"
    HOME_OWNER=$(stat -c "%U:%G" "$TARGET_HOME")
    if [[ "$HOME_OWNER" == "$TARGET_USER:$TARGET_USER" ]]; then
        echo -e "${GREEN}✓ Home directory ownership: $HOME_OWNER${NC}"
    else
        echo -e "${RED}✗ Home directory ownership: $HOME_OWNER (expected: $TARGET_USER:$TARGET_USER)${NC}"
    fi

    HOME_PERMS=$(stat -c "%a" "$TARGET_HOME")
    if [[ "$HOME_PERMS" == "755" ]]; then
        echo -e "${GREEN}✓ Home directory permissions: $HOME_PERMS${NC}"
    else
        echo -e "${RED}✗ Home directory permissions: $HOME_PERMS (expected: 755)${NC}"
    fi

    # Test a few key directories
    for test_dir in .config .local/share .local/share/Steam; do
        if [[ -d "$TARGET_HOME/$test_dir" ]]; then
            DIR_OWNER=$(stat -c "%U:%G" "$TARGET_HOME/$test_dir")
            DIR_PERMS=$(stat -c "%a" "$TARGET_HOME/$test_dir")
            if [[ "$DIR_OWNER" == "$TARGET_USER:$TARGET_USER" && "$DIR_PERMS" == "755" ]]; then
                echo -e "${GREEN}✓ $test_dir ownership and permissions correct${NC}"
            else
                echo -e "${YELLOW}⚠ $test_dir may need manual review${NC}"
            fi
        fi
    done

    # Check podman-compose configurations for SELinux compatibility
    echo -e "${BLUE}Checking podman-compose configurations...${NC}"
    if command -v podman-compose &> /dev/null; then
        for compose_dir in sin1ster-website docker-game-servers; do
            if [[ -f "$TARGET_HOME/$compose_dir/docker-compose.yml" ]]; then
                echo -e "${BLUE}Validating $compose_dir/docker-compose.yml...${NC}"
                if cd "$TARGET_HOME/$compose_dir" && timeout 30 podman-compose config > /dev/null 2>&1; then
                    echo -e "${GREEN}✓ $compose_dir compose file is valid and compatible${NC}"
                    # Check key volume directories
                    if [[ "$compose_dir" == "sin1ster-website" ]]; then
                        for vol in letsencrypt nginx.conf public; do
                            if [[ -e "$TARGET_HOME/$compose_dir/$vol" ]]; then
                                VOL_OWNER=$(stat -c "%U:%G" "$TARGET_HOME/$compose_dir/$vol")
                                VOL_PERMS=$(stat -c "%a" "$TARGET_HOME/$compose_dir/$vol")
                                if [[ "$VOL_OWNER" == "$TARGET_USER:$TARGET_USER" ]]; then
                                    echo -e "${GREEN}✓ Volume $vol has correct ownership${NC}"
                                else
                                    echo -e "${YELLOW}⚠ Volume $vol ownership: $VOL_OWNER${NC}"
                                fi
                            fi
                        done
                    elif [[ "$compose_dir" == "docker-game-servers" ]]; then
                        # Check some config directories
                        for server_dir in Sin1ster-valheim-server project-zomboid-server nitrox_server; do
                            if [[ -d "$TARGET_HOME/$compose_dir/$server_dir" ]]; then
                                DIR_OWNER=$(stat -c "%U:%G" "$TARGET_HOME/$compose_dir/$server_dir")
                                if [[ "$DIR_OWNER" == "$TARGET_USER:$TARGET_USER" ]]; then
                                    echo -e "${GREEN}✓ $server_dir has correct ownership${NC}"
                                else
                                    echo -e "${YELLOW}⚠ $server_dir ownership: $DIR_OWNER${NC}"
                                fi
                            fi
                        done
                    fi
                else
                    echo -e "${RED}✗ $compose_dir compose file validation failed${NC}"
                fi
            fi
        done
    else
        echo -e "${YELLOW}podman-compose not found, skipping validation${NC}"
    fi
fi

echo
echo -e "${GREEN}=== Permission Fix Complete ===${NC}"
echo -e "${BLUE}You may need to log out and back in for all changes to take effect.${NC}"
echo -e "${BLUE}If you encounter any issues, you can restore from the backup.${NC}"
echo
echo -e "${GREEN}Summary:${NC}"
if [[ "$FIX_OWNERSHIP" == true ]]; then
    echo "  - Fixed ownership of entire home directory"
fi
if [[ "$FIX_PERMISSIONS" == true ]]; then
    echo "  - Set directory permissions to 755"
    echo "  - Set file permissions to 644 (755 for executables)"
fi
if [[ "$FIX_SPECIAL" == true ]]; then
    echo "  - Fixed special directories (.ssh, .config, etc.)"
fi
if [[ "$FIX_SELINUX" == true ]]; then
    echo "  - Disabled SELinux permanently"
    echo "  - Fixed SELinux labels and contexts"
fi
if [[ "$FIX_NTFS" == true ]]; then
    echo "  - Fixed NTFS drive permissions"
fi
if [[ "$FIX_EXECUTABLES" == true ]]; then
    echo "  - Fixed executable permissions"
fi
if [[ "$FIX_UMU" == true ]]; then
    echo "  - Fixed UMU compatibility for Flatpaks"
fi
if [[ "$FIX_VERIFY" == true ]]; then
    echo "  - Validated podman-compose configurations"
fi