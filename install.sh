#!/bin/bash
# Enhanced install.sh with macOS integration

# Prompt for sudo password at the start
echo "This script requires administrative privileges."
sudo -v

# Keep the sudo session alive for the duration of the script
(while true; do sudo -v; sleep 60; done) &
KEEP_ALIVE_PID=$!
trap 'kill $KEEP_ALIVE_PID' EXIT

# Constants
CONFIG_DIR="$HOME/.etherealize"
NVIM_DIR="$HOME/.config/nvim"

# Include helpers
source "$CONFIG_DIR/helpers.sh"

# Detect OS
OS=$(detect_os)
echo "Detected OS: $OS"

# Ensure Rust is installed
if ! command -v cargo &> /dev/null; then
    echo "Rust is not installed. Installing..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "Rust is already installed."
fi

# Install dependencies
echo "Installing dependencies..."
source "$CONFIG_DIR/dependencies.sh"
install_dependencies "$OS"

# Install Neovim configuration
echo "Installing Neovim configuration..."
if [[ ! -d "$NVIM_DIR" ]]; then
    git clone https://github.com/RyanBlaney/deployable-neovim-config.git "$NVIM_DIR"
else
    echo "Neovim configuration already exists. Updating..."
    git -C "$NVIM_DIR" pull
fi

# Install Neovim plugins
if command -v nvim &> /dev/null; then
    echo "Installing Neovim plugins..."
    nvim --headless +LazySync +qall
else
    echo "Neovim is not installed. Skipping plugin installation."
fi

# Configure shell environment
configure_shell() {
    local shell_config
    
    # Determine the correct shell config file
    if [[ "$OS" == "Mac" ]]; then
        # macOS defaults to zsh since Catalina
        if [[ "$SHELL" == */zsh ]] || [[ -z "$BASH_VERSION" ]]; then
            shell_config="$HOME/.zshrc"
            echo "Configuring zsh (macOS default)..."
        else
            shell_config="$HOME/.bash_profile"
            echo "Configuring bash on macOS..."
        fi
    else
        shell_config="$HOME/.bashrc"
        echo "Configuring bash on Linux..."
    fi
    
    # Create the config file if it doesn't exist
    touch "$shell_config"
    
    # Add bashrc_additions source line
    if ! grep -q "bashrc_additions" "$shell_config" 2>/dev/null; then
        echo "" >> "$shell_config"
        echo "# Etherealize configuration" >> "$shell_config"
        echo "if [[ -f \"\$HOME/.etherealize/bashrc_additions\" ]]; then" >> "$shell_config"
        echo "    source \"\$HOME/.etherealize/bashrc_additions\"" >> "$shell_config"
        echo "fi" >> "$shell_config"
        echo "Custom configuration added to $shell_config"
    else
        echo "Etherealize configuration already present in $shell_config"
    fi
    
    # macOS-specific shell configuration
    if [[ "$OS" == "Mac" ]]; then
        # Ensure Homebrew is in PATH for future sessions
        if command -v brew &>/dev/null && ! grep -q "brew shellenv" "$shell_config" 2>/dev/null; then
            echo "" >> "$shell_config"
            echo "# Homebrew PATH configuration" >> "$shell_config"
            echo "eval \"\$(brew shellenv)\"" >> "$shell_config"
            echo "Added Homebrew PATH to $shell_config"
        fi
    fi
}

# Call configure_shell function
configure_shell

# Reload shell configuration
echo "Reloading shell configuration..."
case "$OS" in
    "Mac")
        # macOS typically uses zsh
        if [[ "$SHELL" == */zsh ]] || [[ -n "$ZSH_VERSION" ]]; then
            echo "Reloading zsh configuration..."
            source ~/.zshrc 2>/dev/null || echo "Please restart your terminal or run: source ~/.zshrc"
        else
            echo "Reloading bash configuration..."
            source ~/.bash_profile 2>/dev/null || echo "Please restart your terminal or run: source ~/.bash_profile"
        fi
        ;;
    *)
        echo "Reloading bash configuration..."
        source ~/.bashrc 2>/dev/null || echo "Please restart your terminal or run: source ~/.bashrc"
        ;;
esac

echo "Etherealize setup completed successfully!"

# macOS-specific final instructions
if [[ "$OS" == "Mac" ]]; then
    echo ""
    echo "macOS-specific setup notes:"
    echo "1. Grant Accessibility permissions to Yabai and skhd in System Preferences"
    echo "2. Consider installing Presentify from the Mac App Store for presentations"
    echo "3. OpenTabletDriver can be downloaded from: https://github.com/OpenTabletDriver/OpenTabletDriver/releases"
    echo "4. Restart your terminal or run the appropriate source command above"
fi
