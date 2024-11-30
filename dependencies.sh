#!/bin/bash

install_dependencies() {
    
    case "$1" in
        "Windows")
            echo "Windows support not yet implemented."
            ;;
        "Mac")
            echo "Installing macOS dependencies..."
            brew install kdabir/tap/has go python3 python3-pip openssh fzf
            build_firacode

            mkdir -p "$HOME/Library/Preferences/rs.silver/"
            cp -r "$CONFIG_DIR/silver.toml" "$HOME/Library/Preferences/rs.silver/silver.toml"
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

    # Install universal Rust-based tools
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
}

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

