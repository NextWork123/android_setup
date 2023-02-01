#!/bin/bash

# Current Linux Distribution
distro=$(lsb_release -si)

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

# Cloning of akhilnarang Scripts and execution
cd ~/
if [[ ! -f scripts/setup/android_build_env.sh ]]; then
  git clone https://github.com/akhilnarang/scripts
fi
cd ~/scripts

# Installation of necessary packages
case "$distro" in
  Ubuntu|Debian)
    ./setup/android_build_env.sh
    ;;
  Manjaro|Arch|cachyos)
    ./setup/arch-manjaro.sh
    ;;
  Solus)
    ./setup/solus.sh
    ;;
  Fedora)
    ./setup/fedora.sh
    ;;
  *)
    echo "Distribution Not Supported"
    exit 1
    ;;
esac
