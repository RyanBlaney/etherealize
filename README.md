# **Etherealize: Seamlessly Illuminate Your Workflow**

Etherealize is a portable, open-source tool that simplifies the setup of a personalized development environment for `Bash`. It allows you to bring your workflow to any machine with a single command, installing everything you need and integrating modern, interactive tools into your terminal. Designed for developers who value speed, functionality, and consistency, Etherealize ensures your setup is always within reach, no matter the platform.

---

## **✨ What is Etherealize?**

Etherealize is a portable workflow setup script designed to install and configure an essential, feature-rich development environment. It focuses on:

- **Minimal Intrusion**: Your existing configurations remain untouched, as Etherealize extends and enhances them.
- **Adaptability**: Works seamlessly across operating systems, abstracting platform-specific complexities.
- **Efficiency**: Automates dependency installation, tool configuration, and environment setup so you can focus on what matters most.
- **Interactivity**: Enhances your shell experience with visually interactive tools and modern utilities.

---

## **💡 Features**

1. **Advanced Bash Enhancements**:
   - Integrated with **ble.sh** for smooth, modern line editing and autocompletions.
   - Lightweight and modular Bash configurations that complement your existing setup.

2. **Neovim Configuration**:
   - Deploys a comprehensive Neovim setup sourced from [deployable-neovim-config](https://github.com/RyanBlaney/deployable-neovim-config).
   - Automatically installs all plugins and dependencies to create a powerful text-editing environment.

3. **Rust-Powered Toolchain**:
   - Leverages the performance and flexibility of Rust-based tools:
     - **fzf**: Fuzzy finder for interactive file and history searches.
     - **ripgrep**: Fast and intuitive file searching.
     - **exa**: Modern `ls` replacement with rich output.
     - **bat**: A `cat` alternative with syntax highlighting.
     - **zoxide**: Lightning-fast directory navigation.
     - **fd**: A user-friendly `find` command replacement.
     - **silver**: A minimalist yet elegant prompt for a polished terminal experience.

4. **Cross-Platform Compatibility**:
   - Supports macOS, Arch Linux, Ubuntu, CentOS, NixOS, and more.
   - Automatically detects and adapts to your operating system.

5. **Essential Developer Tools**:
   - Installs and configures:
     - **Git**
     - **Luarocks**
     - **Golang**
     - **Python3** and **pip**
     - **xclip** for clipboard integration (on supported systems)
     - **openssh-server** for remote access.

---

## **🚀 Installation**

1. Clone the Etherealize repository:
   ```bash
   git clone git@github.com/RyanBlaney/etherealize.git ~/.etherealize
   ```
2. Run the installer:
    ```bash
    bash ~/etherealize/install.sh
    ```

## **📜 Philosophy**

**Etherealize** embodies a vision of simplicity and power. By seamlessly integrating modern tools, it transforms your terminal into a canvas of productivity and creativity. Each component is chosen with care to balance speed, functionality, and aesthetics, ensuring that your workflow feels as natural as it is effective.

## **🛠️ Customization**

**Etherealize** is designed to be modular and extendable. You can customize your setup by editing the following files:

- `~/.etherealize/bashrc_additions`: Add custom aliases, functions, or shell configurations.
- `~/.config/nvim/init.lua`: Tailor your Neovim environment to your needs.
- `~/.etherealize/dependencies.sh`: Add or modify dependencies for your workflow.

## **💎 Contributions**

**Etherealize** welcomes contributions to improve its functionality, compatibility, and elegance. Feel free to open issues or submit pull requests on the GitHub repository.

## **📘 License**

**Etherealize** is open-source and available under the MIT License.


