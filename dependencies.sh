#!/bin/bash

set -euo pipefail
shopt -s inherit_errexit

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Logging setup
readonly LOG_FILE="${HOME}/etherealize_install_$(date +%Y%m%d_%H%M%S).log"
declare -a FAILED_PACKAGES=()
declare -a SUCCESS_PACKAGES=()

# Logging functions
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    case "$level" in
        "SUCCESS") echo -e "${GREEN}✓${NC} $message" ;;
        "ERROR")   echo -e "${RED}✗${NC} $message" ;;
        "WARNING") echo -e "${YELLOW}⚠${NC} $message" ;;
        "INFO")    echo -e "${BLUE}ℹ${NC} $message" ;;
    esac
}

log_success() { log_message "SUCCESS" "$1"; }
log_error()   { log_message "ERROR" "$1"; }
log_warning() { log_message "WARNING" "$1"; }
log_info()    { log_message "INFO" "$1"; }

# OS Detection (enhanced from helpers.sh)
detect_os() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        Linux*)  echo "linux" ;;
        *)       echo "unknown" ;;
    esac
}

# Check for Xcode Command Line Tools (macOS only)
check_xcode_tools() {
    [[ "$(detect_os)" != "macos" ]] && return 0
    
    if xcode-select -p &>/dev/null && [[ -d "$(xcode-select -p)" ]]; then
        return 0
    fi
    
    if pkgutil --pkg-info=com.apple.pkg.CLTools_Executables &>/dev/null; then
        return 0
    fi
    
    return 1
}

install_xcode_tools() {
    if check_xcode_tools; then
        log_success "Xcode Command Line Tools already installed"
        return 0
    fi
    
    log_info "Installing Xcode Command Line Tools..."
    xcode-select --install 2>&1 | grep -q "already installed" && return 0
    
    local timeout=300
    local elapsed=0
    
    while ! check_xcode_tools && [[ $elapsed -lt $timeout ]]; do
        log_info "Waiting for Xcode Command Line Tools installation..."
        sleep 10
        ((elapsed += 10))
    done
    
    if check_xcode_tools; then
        log_success "Xcode Command Line Tools installation completed"
        return 0
    else
        log_error "Xcode Command Line Tools installation failed or timed out"
        return 1
    fi
}

# Homebrew installation with multiple fallback methods
install_homebrew() {
    if command -v brew &>/dev/null; then
        log_success "Homebrew already installed"
        return 0
    fi
    
    log_info "Installing Homebrew..."
    
    # Method 1: Official installer
    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || eval "$(/usr/local/bin/brew shellenv)"
        log_success "Homebrew installed successfully"
        return 0
    fi
    
    # Method 2: Git clone fallback
    log_warning "Official installer failed, trying git clone method..."
    local brew_dir
    if [[ "$(uname -m)" == "arm64" ]]; then
        brew_dir="/opt/homebrew"
    else
        brew_dir="/usr/local"
    fi
    
    if ! [[ -w "$(dirname "$brew_dir")" ]]; then
        sudo mkdir -p "$brew_dir" && sudo chown "$(whoami):admin" "$brew_dir"
    fi
    
    if git clone https://github.com/Homebrew/brew "$brew_dir" 2>/dev/null; then
        eval "$($brew_dir/bin/brew shellenv)"
        log_success "Homebrew installed via git clone"
        return 0
    fi
    
    log_error "All Homebrew installation methods failed"
    return 1
}

# Package installation with fallback strategies
install_package_safe() {
    local package="$1"
    local os=$(detect_os)
    
    case "$os" in
        macos)
            if brew install "$package" 2>/dev/null; then
                SUCCESS_PACKAGES+=("$package")
                log_success "Installed $package via Homebrew"
                return 0
            else
                FAILED_PACKAGES+=("$package")
                log_error "Failed to install $package"
                return 1
            fi
            ;;
        linux)
            # Preserve existing Linux package installation logic
            install_linux_package "$package"
            ;;
        *)
            log_error "Unsupported operating system: $os"
            return 1
            ;;
    esac
}

# Install Homebrew cask packages
install_cask_safe() {
    local cask="$1"
    
    if brew install --cask "$cask" 2>/dev/null; then
        SUCCESS_PACKAGES+=("$cask (cask)")
        log_success "Installed $cask cask"
        return 0
    else
        FAILED_PACKAGES+=("$cask (cask)")
        log_error "Failed to install $cask cask"
        return 1
    fi
}

# Rust/Cargo installation
install_rust() {
    if command -v cargo &>/dev/null; then
        log_success "Rust/Cargo already installed"
        return 0
    fi
    
    log_info "Installing Rust and Cargo..."
    
    # Set non-interactive mode
    export RUSTUP_INIT_SKIP_PATH_CHECK=yes
    
    if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y;  then
        source ~/.cargo/env
        log_success "Rust and Cargo installed successfully"
        return 0
    else
        log_error "Rust installation failed"
        return 1
    fi
}

# LuaRocks installation
install_luarocks() {
    if command -v luarocks &>/dev/null; then
        log_success "LuaRocks already installed"
        return 0
    fi
    
    local os=$(detect_os)
    case "$os" in
        macos)
            if brew install luarocks  2>/dev/null; then
                log_success "LuaRocks installed via Homebrew"
                return 0
            fi
            ;;
        linux)
            # Preserve existing Linux LuaRocks installation
            install_linux_luarocks
            return $?
            ;;
    esac
    
    log_error "LuaRocks installation failed"
    return 1
}

# Enhanced tablet driver installation
install_tablet_driver() {
    local os=$(detect_os)
    [[ "$os" != "macos" ]] && return 0
    
    log_info "Tablet driver installation requires manual setup on macOS"
    log_info "Recommended: Download OpenTabletDriver from GitHub releases"
    log_info "Alternative: Download official Huion driver from huion.com"
    log_info "Both require Accessibility permissions in System Preferences"
    
    return 0
}

# macOS-specific window management setup
setup_window_management() {
    local os=$(detect_os)
    [[ "$os" != "macos" ]] && return 0
    
    log_info "Setting up window management (Yabai + skhd)..."
    
    # Install yabai and skhd
    if brew install koekeishiya/formulae/yabai koekeishiya/formulae/skhd  2>/dev/null; then
        log_success "Yabai and skhd installed"
        
        # Create configuration directories
        mkdir -p ~/.config/yabai ~/.config/skhd
        
        # Start services
        if brew services start yabai && brew services start skhd;  then
            log_success "Yabai and skhd services started"
        else
            log_warning "Failed to start services - manual configuration required"
        fi
        
        log_warning "Manual setup required:"
        log_warning "1. Grant Accessibility permissions in System Preferences"
        log_warning "2. Configure ~/.config/yabai/yabairc and ~/.config/skhd/skhdrc"
        log_warning "3. For advanced features, consider disabling SIP partially"
        
        return 0
    else
        log_error "Failed to install window management tools"
        return 1
    fi
}

# Main dependency installation function
install_dependencies() {
    local os=$(detect_os)
    log_info "Starting dependency installation for $os"
    
    case "$os" in
        macos)
            # macOS-specific setup
            install_xcode_tools || log_warning "Xcode tools installation had issues"
            install_homebrew || { log_error "Homebrew installation failed"; return 1; }
            
            # Core packages
            local -a packages=(
                "nvim" "fzf" "fd" "ripgrep" "btop" "lsd" "lazygit" "k9s"
                "yazi" "ffmpeg" "sevenzip" "jq" "poppler" "zoxide" "imagemagick"
            )
            
            for package in "${packages[@]}"; do
                install_package_safe "$package"
            done
            
            # Cask installations
            install_cask_safe "ghostty" 
            install_cask_safe "font-symbols-only-nerd-font" || log_warning "Nerd font installation failed"
            
            # Special installations
            install_rust
            install_luarocks
            setup_window_management
            install_tablet_driver
            ;;
            
        linux)
            # Preserve existing Linux installation logic
            install_linux_dependencies
            ;;
            
        *)
            log_error "Unsupported operating system: $os"
            return 1
            ;;
    esac
}

# Verification function
verify_installations() {
    local -a tools=("nvim" "fzf" "fd" "rg" "btop" "lsd" "lazygit" "k9s" "yazi")
    local os=$(detect_os)
    
    [[ "$os" == "macos" ]] && tools+=("brew" "cargo")
    
    log_info "Verifying installations..."
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            local version
            version=$("$tool" --version 2>/dev/null | head -n1 | cut -d' ' -f2 2>/dev/null || echo "installed")
            log_success "$tool verified: $version"
        else
            log_warning "$tool not found in PATH"
        fi
    done
}

# Final report generation
generate_report() {
    echo -e "\n${BLUE}=== ETHEREALIZE DEPENDENCY INSTALLATION REPORT ===${NC}"
    echo "OS: $(detect_os)"
    echo "Log file: $LOG_FILE"
    echo ""
    
    if [[ ${#SUCCESS_PACKAGES[@]} -gt 0 ]]; then
        echo -e "${GREEN}Successfully installed packages:${NC}"
        printf '%s\n' "${SUCCESS_PACKAGES[@]}" | sed 's/^/  ✓ /'
        echo ""
    fi
    
    if [[ ${#FAILED_PACKAGES[@]} -gt 0 ]]; then
        echo -e "${RED}Failed package installations:${NC}"
        printf '%s\n' "${FAILED_PACKAGES[@]}" | sed 's/^/  ✗ /'
        echo ""
        echo -e "${YELLOW}Note: Some failures may not affect core functionality${NC}"
    else
        echo -e "${GREEN}All package installations completed successfully!${NC}"
    fi
    
    echo -e "${BLUE}===============================================${NC}"
}

# Setup error handling
trap 'log_error "Script interrupted"; generate_report; exit 130' INT
trap 'log_error "Script terminated"; generate_report; exit 143' TERM
trap 'generate_report' EXIT

# Main execution
main() {
    log_info "Etherealize dependency installation started"
    
    install_dependencies
    verify_installations
    
    log_info "Dependency installation completed"
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
