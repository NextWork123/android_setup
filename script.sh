#!/bin/bash

# Current Linux Distribution
distro=$(grep ^ID= /etc/os-release | cut -d= -f2 | tr '[:upper:]' '[:lower:]' | sed 's/\"//g')

# Ask for user name and email for Github
if [ -z "$(git config --global user.name)" ] || [ -z "$(git config --global user.email)" ]; then
  echo "Enter your Github name and email to configure Git:"
  read -p "Name: " YOUR_NAME
  read -p "Email: " YOUR_EMAIL
  git config --global user.name "$YOUR_NAME"
  git config --global user.email "$YOUR_EMAIL"
else
  echo "Git is already configured with the following details:"
  echo "Name: $(git config --global user.name)"
  echo "Email: $(git config --global user.email)"
  read -p "Do you want to change these details? [y/N]: " change_details
  if [ "$change_details" == "y" ] || [ "$change_details" == "Y" ]; then
    read -p "Enter new name: " YOUR_NAME
    read -p "Enter new email: " YOUR_EMAIL
    git config --global user.name "$YOUR_NAME"
    git config --global user.email "$YOUR_EMAIL"
  fi
fi

# Cloning of akhilnarang Scripts in '/home/$USER/scripts' and execution
SCRIPT_DIR=~/scripts
if [[ ! -f scripts/setup/android_build_env.sh ]]; then
  git clone https://github.com/akhilnarang/scripts $SCRIPT_DIR
  #
  # Abort the script if it failed to clone.
  # Problems with github? Problems with the user's internet?
  # What do I know?
  #
  if [ $? -ne 0 ]; then
    echo "Failled to clone akhilnarang/scripts in $SCRIPT_DIR"
    exit 1
  fi
fi
cd $SCRIPT_DIR

# Installation of necessary packages
case "$distro" in
  "ubuntu" | "debian" | "linuxmint" | "kali")
    ./setup/android_build_env.sh
    ;;
  "arch" | "manjaro" | "arcolinux" | "garuda" | "artix" | "cachyos")
    ./setup/arch-manjaro.sh
    ;;
  "solus")
    ./setup/solus.sh
    ;;
  "fedora" | "centos")
    ./setup/fedora.sh
    ;;
  *)
    echo "Distribution Not Supported"
    exit 1
    ;;
esac

# Check if ccache config is already present in .bashrc
if ! grep -q 'Generated ccache config' "$HOME/.bashrc"; then
  echo "Configuring ccache..."

  # Set default ccache directory if custom directory is not set
  directory_ccache_custom=${directory_ccache_custom:-$HOME/.aosp_ccache}

  # Create ccache directory and set permissions
  mkdir -p "$directory_ccache_custom"
  sudo mount --bind "$HOME/.ccache" "$directory_ccache_custom"
  sudo chmod -R 777 "$directory_ccache_custom"

  # Append ccache config to .bashrc
  cat << EOF >> "$HOME/.bashrc"

# Generated ccache config
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
export CCACHE_DIR="$directory_ccache_custom"
ccache -M 50G -F 0
EOF
fi
