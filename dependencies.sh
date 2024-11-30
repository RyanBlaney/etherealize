#!/bin/bash

install_dependencies() {
    # Install universal Rust-based tools
    echo "Installing Rust-based tools..."
    cargo install fzf ripgrep exa bat zoxide yazi silver fd-find

    case "$1" in
        "Windows")
            echo "Windows support not yet implemented."
            ;;
        "Mac")
            echo "Installing macOS dependencies..."
            brew install kdabir/tap/has neovim git luarocks go python3 python3-pip openssh 
            ;;
        "Arch")
            echo "Installing Arch Linux dependencies..."
            sudo pacman -S neovim git luarocks go python3 python-pip openssh
            ;;
        "Ubuntu")
            echo "Installing Ubuntu/Debian dependencies..."
            sudo apt update && sudo apt install -y neovim git luarocks golang python3 python3-pip openssh
            ;;
        "CentOS")
            echo "Installing CentOS dependencies..."
            sudo yum install -y epel-release neovim git luarocks golang python3 python3-pip openssh
            ;;
        *)
            echo "Unsupported OS: $1"
            ;;
    esac
}

