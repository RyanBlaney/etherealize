#!/bin/bash
# Enhanced helpers.sh with improved macOS support

# OS Detection (existing function enhanced)
detect_os() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        Linux*)  echo "linux" ;;
        CYGWIN*) echo "cygwin" ;;
        MINGW*)  echo "mingw" ;;
        *)       echo "unknown" ;;
    esac
}

# Enhanced architecture detection
detect_arch() {
    uname -m
}

# Homebrew prefix detection
get_brew_prefix() {
    if command -v brew &>/dev/null; then
        brew --prefix
    elif [[ -x "/opt/homebrew/bin/brew" ]]; then
        echo "/opt/homebrew"
    elif [[ -x "/usr/local/bin/brew" ]]; then
        echo "/usr/local"
    else
        return 1
    fi
}

# Shell configuration file detection
get_shell_config() {
    local os=$(detect_os)
    
    case "$os" in
        macos)
            if [[ "$SHELL" == */zsh ]]; then
                echo "$HOME/.zshrc"
            else
                echo "$HOME/.bash_profile"
            fi
            ;;
        linux)
            echo "$HOME/.bashrc"
            ;;
        *)
            echo "$HOME/.profile"
            ;;
    esac
}

# Check if running on Apple Silicon
is_apple_silicon() {
    [[ "$(detect_os)" == "macos" && "$(detect_arch)" == "arm64" ]]
}

# Cross-platform command existence check
command_exists() {
    command -v "$1" &>/dev/null
}

# Enhanced sudo check
check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        echo "This script requires sudo privileges. Please enter your password:"
        sudo -v || {
            echo "Error: Unable to obtain sudo privileges"
            return 1
        }
    fi
    
    # Keep sudo alive
    while true; do 
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done 2>/dev/null &
}

# macOS permission helper
check_accessibility_permission() {
    local app="$1"
    
    if ! command_exists osascript; then
        return 1
    fi
    
    osascript -e "
        tell application \"System Events\"
            try
                set accessibilityEnabled to UI elements enabled
                if not accessibilityEnabled then
                    return false
                end if
            on error
                return false
            end try
        end tell
        return true
    " &>/dev/null
}

# Environment setup helper
setup_environment() {
    local os=$(detect_os)
    
    case "$os" in
        macos)
            # Setup Homebrew environment
            if command_exists brew; then
                eval "$(brew shellenv)"
            fi
            
            # Add common paths
            export PATH="/usr/local/bin:$PATH"
            export PATH="$HOME/.local/bin:$PATH"
            
            # Rust environment
            [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
            ;;
        linux)
            # Preserve existing Linux environment setup
            setup_linux_environment
            ;;
    esac
}

# Cross-platform process management
kill_process_by_name() {
    local process_name="$1"
    local os=$(detect_os)
    
    case "$os" in
        macos)
            pkill -f "$process_name" 2>/dev/null || true
            ;;
        linux)
            killall "$process_name" 2>/dev/null || true
            ;;
    esac
}

# Network connectivity check
check_network() {
    local urls=("https://github.com" "https://raw.githubusercontent.com")
    
    for url in "${urls[@]}"; do
        if curl -s --connect-timeout 5 --max-time 10 "$url" &>/dev/null; then
            return 0
        fi
    done
    
    return 1
}

# Enhanced path management
add_to_path() {
    local new_path="$1"
    local shell_config
    shell_config=$(get_shell_config)
    
    if [[ ":$PATH:" != *":$new_path:"* ]] && [[ -d "$new_path" ]]; then
        echo "export PATH=\"$new_path:\$PATH\"" >> "$shell_config"
        export PATH="$new_path:$PATH"
    fi
}

# System information gathering
get_system_info() {
    local os=$(detect_os)
    local arch=$(detect_arch)
    
    echo "OS: $os"
    echo "Architecture: $arch"
    echo "Shell: $SHELL"
    
    case "$os" in
        macos)
            echo "macOS Version: $(sw_vers -productVersion)"
            [[ -x "$(command -v brew)" ]] && echo "Homebrew: $(brew --version | head -n1)"
            ;;
        linux)
            [[ -f /etc/os-release ]] && echo "Distribution: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
            ;;
    esac
}

# Cross-platform service management
manage_service() {
    local action="$1"
    local service="$2"
    local os=$(detect_os)
    
    case "$os" in
        macos)
            case "$action" in
                start)   brew services start "$service" ;;
                stop)    brew services stop "$service" ;;
                restart) brew services restart "$service" ;;
                status)  brew services list | grep "$service" ;;
            esac
            ;;
        linux)
            case "$action" in
                start)   sudo systemctl start "$service" ;;
                stop)    sudo systemctl stop "$service" ;;
                restart) sudo systemctl restart "$service" ;;
                status)  systemctl status "$service" ;;
            esac
            ;;
    esac
}
