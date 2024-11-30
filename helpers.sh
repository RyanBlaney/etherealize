#!/bin/bash

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v pacman &> /dev/null; then
            echo "Arch"
        elif command -v apt &> /dev/null; then
            echo "Ubuntu"
        elif command -v yum &> /dev/null; then
            echo "CentOS"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Mac"
    elif [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* ]]; then
        echo "Windows"
    else
        echo "Unknown"
    fi
}
