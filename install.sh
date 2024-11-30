#/bin/bash

# Prompt for sudo password at the start
echo "This script requires administrative privileges."
sudo -v

# Keep the sudo session alive for the duration of the script
# This will run `sudo -v` in the background every 60 seconds
# until the script finishes.
(while true; do sudo -v; sleep 60; done) &

# Store the PID of the background process
KEEP_ALIVE_PID=$!

# Ensure the script cleans up the background process on exit
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

# Add the custom Bash configuration
echo "Adding Bash configurations..."
if ! grep -q "source ~/.etherealize/bashrc_additions" ~/.bashrc; then
    echo "source ~/.etherealize/bashrc_additions" >> ~/.bashrc
    echo "Custom Bash configuration added to ~/.bashrc"
fi

# Reload Bash
echo "Reloading Bash configuration..."
source ~/.bashrc

echo "Etherealize setup completed successfully!"
