#!/bin/bash

# Conda Setup Script
# This script configures conda in bash

set -e  # Exit on any error

CONDA_PATH="/raid/software/miniconda3"
CONDA_INIT_SCRIPT="$CONDA_PATH/etc/profile.d/conda.sh"

echo "=== Conda Setup Script ==="
echo

# Check if conda installation exists
if [ ! -f "$CONDA_INIT_SCRIPT" ]; then
    echo "Error: Conda installation not found at $CONDA_PATH"
    echo "Please check the conda installation path."
    exit 1
fi

# Function to add conda to bashrc if not already present
setup_conda_in_bash() {
    local bashrc_file="$HOME/.bashrc"
    local conda_source_line="source $CONDA_INIT_SCRIPT"
    
    echo "Setting up conda in bash..."
    
    # Check if conda is already sourced in bashrc
    if grep -Fxq "$conda_source_line" "$bashrc_file" 2>/dev/null; then
        echo "? Conda is already configured in ~/.bashrc"
    else
        echo "Adding conda to ~/.bashrc..."
        echo "" >> "$bashrc_file"
        echo "# Conda setup" >> "$bashrc_file"
        echo "$conda_source_line" >> "$bashrc_file"
        echo "? Added conda to ~/.bashrc"
    fi
}

# Function to source conda for current session
source_conda() {
    echo "Sourcing conda for current session..."
    source "$CONDA_INIT_SCRIPT"
    echo "? Conda sourced successfully"
}

# Main execution
main() {
    echo "Setting up conda in bash environment..."
    setup_conda_in_bash
    
    echo
    echo "Sourcing conda for current session..."
    source_conda
    
    echo
    echo "Testing conda installation..."
    if command -v conda >/dev/null 2>&1; then
        echo "? Conda is working correctly"
        echo "Conda version: $(conda --version)"
    else
        echo "? Conda command not found in current session"
        echo "You may need to restart your shell or run: source ~/.bashrc"
    fi
    
    echo
    echo "=== Conda Setup Complete! ==="
    echo
    echo "Next steps:"
    echo "1. If conda command is not working, restart your shell or run: source ~/.bashrc"
    echo "2. Run 'conda env list' to see available environments"
    echo "3. Use the install_jupyter_kernel.sh script to set up Jupyter kernels"
}

# Run main function
main