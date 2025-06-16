#!/bin/bash

# Include enhanced helpers
source "$(dirname "$0")/helpers.sh"

# OS-specific installation branches
case "$(detect_os)" in
    macos)
        log_info "Detected macOS - using Homebrew-based installation"
        source "$(dirname "$0")/dependencies.sh"
        ;;
    linux)
        log_info "Detected Linux - using existing installation method"
        # Keep existing Linux installation logic
        ;;
    *)
        log_error "Unsupported operating system"
        exit 1
        ;;
esac

# Shell configuration integration
configure_shell() {
    local shell_config
    shell_config=$(get_shell_config)
    
    # Add bashrc_additions source line
    if ! grep -q "bashrc_additions" "$shell_config" 2>/dev/null; then
        echo "" >> "$shell_config"
        echo "# Etherealize configuration" >> "$shell_config"
        echo "[[ -f \"\$HOME/.bashrc_additions\" ]] && source \"\$HOME/.bashrc_additions\"" >> "$shell_config"
    fi
    
    # macOS-specific shell configuration
    if [[ "$(detect_os)" == "macos" ]]; then
        # Ensure Homebrew is in PATH for future sessions
        if command -v brew &>/dev/null && ! grep -q "brew shellenv" "$shell_config" 2>/dev/null; then
            echo "eval \"\$(brew shellenv)\"" >> "$shell_config"
        fi
    fi
}
