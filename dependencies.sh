#!/bin/bash
# Enhanced dependencies.sh with macOS support and robust error handling

set -euo pipefail

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
    [[ "$(detect_os)" != "Mac" ]] && return 0
    
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
        "Mac")
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
        "Arch"|"Ubuntu"|"CentOS")
            # This will be handled by the existing Linux logic in install_dependencies
            return 0
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
    
    if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
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
        "Mac")
            if brew install luarocks 2>/dev/null; then
                log_success "LuaRocks installed via Homebrew"
                return 0
            fi
            ;;
        "Arch"|"Ubuntu"|"CentOS")
            # Use the existing build_luarocks function for Linux
            build_luarocks
            return $?
            ;;
    esac
    
    log_error "LuaRocks installation failed"
    return 1
}

# Enhanced tablet driver installation
install_tablet_driver() {
    local os=$(detect_os)
    [[ "$os" != "Mac" ]] && return 0
    
    log_info "Tablet driver installation requires manual setup on macOS"
    log_info "Recommended: Download OpenTabletDriver from GitHub releases"
    log_info "Alternative: Download official Huion driver from huion.com"
    log_info "Both require Accessibility permissions in System Preferences"
    
    return 0
}

# macOS-specific window management setup
setup_window_management() {
    local os=$(detect_os)
    [[ "$os" != "Mac" ]] && return 0
    
    log_info "Setting up window management (Yabai + skhd)..."
    
    # Install yabai and skhd
    if brew install koekeishiya/formulae/yabai koekeishiya/formulae/skhd 2>/dev/null; then
        log_success "Yabai and skhd installed"
        
        # Create configuration directories
        mkdir -p ~/.config/yabai ~/.config/skhd
        
        # Start services
        if brew services start yabai && brew services start skhd; then
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
    local os="$1"
    
    # Initialize logging only for Mac (to avoid breaking Linux)
    if [[ "$os" == "Mac" ]]; then
        # Initialize log file and arrays for Mac
        readonly LOG_FILE="${HOME}/etherealize_install_$(date +%Y%m%d_%H%M%S).log"
        declare -a FAILED_PACKAGES=()
        declare -a SUCCESS_PACKAGES=()
        
        echo "Starting macOS dependency installation..." | tee -a "$LOG_FILE"
    fi
    
    case "$os" in
        "Windows")
            echo "Windows support not yet implemented."
            ;;
        "Mac")
            echo "Installing macOS dependencies..."
            install_mac_dependencies
            ;;
        "Arch")
            echo "Installing Arch Linux dependencies..."
            sudo pacman -S go python3 python-pip openssh fzf 
            build_firacode

            mkdir -p "$HOME/.config/silver"
            cp -r "$CONFIG_DIR/silver.toml" "$HOME/.config/silver/silver.toml"
           ;;
        "Ubuntu")
            echo "Installing Ubuntu/Debian dependencies..."
            sudo apt update && sudo apt install -y golang python3 python3-pip \
                openssh-server unzip build-essential fontconfig fzf libssl-dev cmake \
                gettext libtool libtool-bin autoconf automake g++ pkg-config curl doxygen
            build_firacode

            mkdir -p "$HOME/.config/silver"
            cp -r "$CONFIG_DIR/silver.toml" "$HOME/.config/silver/silver.toml"
            ;;
        "CentOS")
            echo "Installing CentOS dependencies..."
            sudo yum install -y gcc gcc-c++ make cmake gettext libevent libevent-devel ncurses ncurses-devel
            sudo yum install -y epel-release 
            sudo yum install -y golang python3 python3-pip openssh
            sudo dnf install fzf
            build_firacode

            mkdir -p "$HOME/.config/silver"
            cp -r "$CONFIG_DIR/silver.toml" "$HOME/.config/silver/silver.toml"
            ;;
        *)
            echo "Unsupported OS: $1"
            ;;
    esac

    # Install universal Rust-based tools (cross-platform)
    echo "Installing Rust-based tools..."
    cargo install ripgrep exa bat zoxide silver fd-find btop stylua
    cargo install --locked yazi-fm yazi-cli

    # Install ripgrep
    build_ripgrep
    
    # Install Golang tools
    go install mvdan.cc/gofumpt@latest
    go install github.com/segmentio/golines@latest
    go install golang.org/x/tools/cmd/goimports@latest

    build_neovim
    build_luarocks
    
    # Generate report only for Mac
    if [[ "$os" == "Mac" ]]; then
        generate_report
    fi
}

# New macOS-specific installation function
install_mac_dependencies() {
    # macOS-specific setup
    install_xcode_tools || log_warning "Xcode tools installation had issues"
    install_homebrew || { log_error "Homebrew installation failed"; return 1; }
    
    # Core packages via Homebrew
    local -a packages=(
        "neovim" "fzf" "fd" "ripgrep" "btop" "lsd" "lazygit" "k9s"
        "yazi" "ffmpeg" "sevenzip" "jq" "poppler" "zoxide" "imagemagick"
        "go" "python3" "openssh" "cmake" "pkg-config" "curl"
    )
    
    # Update Homebrew
    brew update || log_warning "Homebrew update failed"
    
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
    
    # macOS Silver config
    mkdir -p "$HOME/Library/Preferences/rs.silver/"
    [[ -f "$CONFIG_DIR/silver.toml" ]] && cp "$CONFIG_DIR/silver.toml" "$HOME/Library/Preferences/rs.silver/silver.toml"
}

# Verification function
verify_installations() {
    local -a tools=("nvim" "fzf" "fd" "rg" "btop" "lsd" "lazygit" "k9s" "yazi")
    local os=$(detect_os)
    
    [[ "$os" == "Mac" ]] && tools+=("brew" "cargo")
    
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

# Your existing Linux build functions (preserved)
build_ripgrep() {
    git clone https://github.com/BurntSushi/ripgrep.git ~/ripgrep
    cd ~/ripgrep
    cargo build --release --features 'pcre2'
    sudo mv target/release/rg ~/.cargo/bin/ripgrep
    rm -rf ~/ripgrep
}

build_firacode() {
    cd ~
    curl -L -o FiraCode.zip https://github.com/tonsky/FiraCode/releases/download/6.2/Fira_Code_v6.2.zip
    unzip FiraCode.zip -d FiraCode
    mkdir -p ~/.local/share/fonts
    cp FiraCode/ttf/*.ttf ~/.local/share/fonts/
    fc-cache -fv
    rm -rf ~/FiraCode.zip ~/FiraCode
}

build_firacode_mac() {
    cd ~
    curl -L -o FiraCode.zip https://github.com/tonsky/FiraCode/releases/download/6.2/Fira_Code_v6.2.zip
    unzip FiraCode.zip -d FiraCode
    mkdir -p ~/.local/share/fonts
    cp FiraCode/ttf/*.ttf ~/Library/Fonts/
    fc-cache -fv
    rm -rf ~/FiraCode.zip ~/FiraCode
}

build_tmux() {
    curl -L -O https://github.com/tmux/tmux/releases/download/3.5/tmux-3.5.tar.gz
    tar -zxf tmux-3.5.tar.gz
    cd tmux-3.5
    ./configure
    make
    sudo make install
    cd ..
    rm -rf tmux-3.5 tmux-3.5.tar.gz
}

build_neovim() {
    echo "Building Neovim from source..."
    git clone https://github.com/neovim/neovim.git ~/tmp/neovim
    cd ~/tmp/neovim
    git checkout stable
    make CMAKE_BUILD_TYPE=RelWithDebInfo
    sudo make install
    cd ~
    rm -rf ~/tmp/neovim
    if [ ! -s "~/tmp" ]; then
        rm -rf ~/tmp
    fi
    echo "Neovim installed successfully!"
}

build_luarocks() {
    echo "Building Lua from source..."
    curl -R -O https://www.lua.org/ftp/lua-5.4.4.tar.gz
    tar zxf lua-5.4.4.tar.gz
    cd lua-5.4.4
    make linux
    sudo make install
    cd ..
    rm -rf lua-5.4.4 lua-5.4.4.tar.gz

    echo "Building LuaRocks from source..."
    curl -R -O https://luarocks.github.io/luarocks/releases/luarocks-3.11.1.tar.gz
    tar zxpf luarocks-3.11.1.tar.gz
    cd luarocks-3.11.1
    ./configure --lua-suffix=5.4 --with-lua-include=/usr/local/include
    make
    sudo make install    
    cd ..
    rm -rf luarocks-3.11.1.tar.gz luarocks-3.11.1
    echo "LuaRocks installed successfully!"
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
