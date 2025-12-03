#!/bin/bash
set -e

echo "=== Lux AI Season 2 - Vast.ai Setup Script ==="

# Configure Git (you may want to customize these)
echo "Configuring Git..."
git config --global user.name "haozliu"
git config --global user.email "haozliu@ethz.ch"
git config --global init.defaultBranch main

# Setup SSH key for GitHub
echo "Setting up SSH key for GitHub..."
SSH_DIR="$HOME/.ssh"
SSH_KEY="$SSH_DIR/id_ed25519"

# Generate SSH key if it doesn't exist
if [ ! -f "$SSH_KEY" ]; then
    echo "Generating new SSH key..."
    ssh-keygen -t ed25519 -C "haozliu@ethz.ch" -f "$SSH_KEY" -N ""
    echo "SSH key generated successfully!"
else
    echo "SSH key already exists at $SSH_KEY"
fi

# Start ssh-agent and add the key
echo "Adding SSH key to ssh-agent..."
eval "$(ssh-agent -s)"
ssh-add "$SSH_KEY" || true

# Configure SSH config for GitHub
SSH_CONFIG="$SSH_DIR/config"
if [ ! -f "$SSH_CONFIG" ] || ! grep -q "Host github.com" "$SSH_CONFIG"; then
    echo "Configuring SSH for GitHub..."
    cat >> "$SSH_CONFIG" << EOF

Host github.com
    HostName github.com
    User git
    IdentityFile $SSH_KEY
    IdentitiesOnly yes
EOF
    chmod 600 "$SSH_CONFIG"
fi

# Display public key for user to add to GitHub
echo ""
echo "=== SSH Public Key ==="
echo "Please add the following public key to your GitHub account:"
echo "Go to: https://github.com/settings/keys"
echo ""
cat "$SSH_KEY.pub"
echo ""
echo "Press Enter after you've added the key to GitHub, or Ctrl+C to exit and add it later..."
read -r

# Test SSH connection to GitHub
echo "Testing SSH connection to GitHub..."
ssh -T git@github.com -o StrictHostKeyChecking=no || echo "Note: If you see 'Permission denied', make sure you've added the SSH key to your GitHub account."

# Configure Git to use SSH for GitHub URLs
echo "Configuring Git to use SSH for GitHub..."
git config --global url."git@github.com:".insteadOf "https://github.com/"

# Initialize conda for bash shell
echo "Initializing conda..."
conda init bash
eval "$(conda shell.bash hook)"

# Create conda environment as per Getting Started guide
echo "Creating conda environment 'luxai_s2' with Python 3.8..."
conda create -n "luxai_s2" "python==3.8" -y

# Activate the environment
echo "Activating conda environment..."
conda activate luxai_s2

# Install Lux AI Season 2 packages
echo "Installing Lux AI Season 2 environment..."
pip install numpy pygame termcolor matplotlib gymnasium scipy pettingzoo vec_noise && \
pip uninstall gym gym-notices -y 2>/dev/null; \
pip install --upgrade luxai_s2 --no-deps

# Install GPU version if GPU is available (optional)
if command -v nvidia-smi &> /dev/null; then
    echo "GPU detected. Installing GPU-optimized version (juxai-s2)..."
    pip install numpy pygame termcolor matplotlib gymnasium scipy pettingzoo vec_noise && \
    pip uninstall gym gym-notices -y 2>/dev/null; \
    pip install juxai-s2 --no-deps
else
    echo "No GPU detected. Skipping GPU-optimized version installation."
fi

# Verify installation
echo "Verifying installation..."
python -c "import luxai_s2; print(f'Lux AI S2 version: {luxai_s2.__version__}')" || echo "Warning: Could not verify luxai_s2 installation"

if command -v nvidia-smi &> /dev/null; then
    python -c "import jux; print('Jux (GPU version) installed successfully')" || echo "Warning: Could not verify jux installation"
fi

echo ""
echo "=== Setup Complete ==="
echo "To activate the environment, run:"
echo "  conda activate luxai_s2"
echo ""
echo "To verify installation, run:"
echo "  luxai-s2 kits/python/main.py kits/python/main.py -v 2 -o replay.json"
echo ""
echo "Repository location: $(pwd)"

