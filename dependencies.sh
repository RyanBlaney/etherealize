#!/bin/bash

install_dependencies() {
    
    case "$1" in
        "Windows")
            echo "Windows support not yet implemented."
            ;;
        "Mac")
            echo "Installing macOS dependencies..."
            brew install kdabir/tap/has go python3 python3-pip openssh fzf yazi
            ;;
        "Arch")
            echo "Installing Arch Linux dependencies..."
            sudo pacman -S go python3 python-pip openssh fzf yazi
            ;;
        "Ubuntu")
            echo "Installing Ubuntu/Debian dependencies..."
            sudo apt update && sudo apt install -y golang python3 python3-pip openssh fzf yazi
            ;;
        "CentOS")
            echo "Installing CentOS dependencies..."
            sudo yum groupinstall "Development Tools"
            sudo yum install -y gcc gcc-c++ make cmake gettext
            sudo yum install -y epel-release golang python3 python3-pip openssh fzf yazi
            ;;
        *)
            echo "Unsupported OS: $1"
            ;;
    esac

    # Install universal Rust-based tools
    echo "Installing Rust-based tools..."
    cargo install ripgrep exa bat zoxide silver fd-find

    build_neovim
    build_luarocks
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
    echo "Building LuaRocks from source..."
    curl -R -O https://luarocks.org/releases/luarocks-3.9.1.tar.gz
    tar zxpf luarocks-3.9.1.tar.gz
    cd luarocks-3.9.1
    ./configure --lua-version=5.1 --with-lua-include=/usr/include
    make
    sudo make install
    cd ..
    rm -rf luarocks-3.9.1.tar.gz luarocks-3.9.1
    echo "LuaRocks installed successfully!"
}

