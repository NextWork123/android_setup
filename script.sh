#!/bin/bash

GRY='\033[1;30m'
RED='\033[0;31m'
BLU='\033[0;34m'
GRN='\033[0;32m'
PUL='\033[0;35m'
RST='\033[0m'


loadMemory () {
    MEMORY_RAM=$(cat /proc/meminfo | grep MemTotal: | tr '\n' ' ' | sed -e 's/[^0-9]/ /g' -e 's/^ *//g' -e 's/ *$//g' | tr -s ' ' | sed 's/ /\n/g')
    # Convert to MB
    MEMORY_RAM=$((${MEMORY_RAM} / 1024))
    # Convert to GB
    MEMORY_RAM=$((${MEMORY_RAM} / 1024))
    # Get SWAP size.
    MEMORY_SWAP=$(cat /proc/meminfo | grep SwapTotal: | tr '\n' ' ' | sed -e 's/[^0-9]/ /g' -e 's/^ *//g' -e 's/ *$//g' | tr -s ' ' | sed 's/ /\n/g')
    # Convert to MB
    MEMORY_SWAP=$((${MEMORY_SWAP} / 1024))
    # Convert to GB
    MEMORY_SWAP=$((${MEMORY_SWAP} / 1024))
}

#
# Get RAM size.
# If RAM < 16 GB optimize swap usage.
# Check also for already swap partition.
#
MEMORY_RAM=0
MEMORY_SWAP=0
loadMemory

SwapOnPartition () {
    #
    # print partition in use as root
    # /boot (for efi usage) and print / (system)
    #
    DontUse=( $(df -h | grep ^/dev | grep '/boot\|/$' | tr ' ' '\n' | grep /dev) )
    printf "${RED}Don't use this partition:\n"
    echo "${DontUse[*]}"
    printf "${RST}"
    # print disk
    DISK=$(sudo fdisk -l | grep Disk | tr ' ' '\n' | tr ':' ' ' | grep /dev)
    printf "${GRY}Available disk:\n"
    echo "$DISK"
    printf "${RST}"
    # save partition
    PARTITION=$(sudo fdisk -l | awk '!/Disk/' | tr ' ' '\n' | tr ':' ' ' | grep /dev)
    printf "${GRN}Available partition:\n"
    COUNTER=0
    for part in ${PARTITION[*]}; do
        #
        # Filter for not print DontUse disk.
        #
        if [[ ! "${DontUse[*]}" =~ "${part}" ]]; then
            COUNTER=$(expr $COUNTER + 1)
            echo " $COUNTER - $part"
        fi
    done
    printf "${RST}"
    read -p "Select your partition number: " part_num
    COUNTER=0
    for part in ${PARTITION[*]}; do
        #
        # Filter partition for check DontUse disk.
        #
        if [[ ! "${DontUse[*]}" =~ "${part}" ]]; then
            COUNTER=$(expr $COUNTER + 1)
            #
            # Check chose number with number of partition
            # N.B. : if the number not exist in list of partition nothing happen.
            #
            if [[ "$COUNTER" == "$part_num" ]]; then
                echo "You select $part"
                read -p "You are sure to continue and format this partition? [y/N]: " part_num
                if [ "$part_num" == "y" ] || [ "$part_num" == "Y" ]; then
                    #
                    # I need to save UUID to put it into fstab
                    #
                    UUID=$(sudo mkswap $part | tr ' ' '\n' | grep 'UUID' | tr -d 'UUID=')
                    echo "Enable swap partition"
                    sudo swapon $part
                    read -p "You want put this in fstab? [y/N]: " write_fstab
                    if [ "$write_fstab" == "y" ] || [ "$write_fstab" == "Y" ]; then
                        printf "${RED}If you want remove or resize this partition\nyou need to remove this from fstab with manual way.\n${RST}"
                        sudo su -c "printf '\n# swap created with script' >> /etc/fstab"
                        sudo su -c "printf '\nUUID=$UUID\tnone\tswap\tdefaults\t0\t0\n' >> /etc/fstab"
                    fi
                    loadMemory
                    printf "${BLU}New swap size: $MEMORY_SWAP GB${RST}\n"
                fi
                break
            fi
        fi
    done
}

#
# Read doc:
# https://wiki.archlinux.org/title/Swap#Swap_file
#
SwapOnFile () {
    SWAP_FILE=/swapfile
    read -p "Write size of swap (integer and in GB): " size_file
    #
    # if user write for example: 3 GB
    # this keep only number
    #
    size_file=$(echo $size_file | tr -dc '0-9')
    if [[ "$size_file" -lt "1" ]]; then
        echo "Less than 1 GB. Abort."
    fi
    #
    # convert GB to MiB
    # WARNING: the right size for convert is 953,674
    # but bash can only multiply integers
    #
    size_file=$((size_file * 954))
    
    #
    # If this file already exit maybe this script
    # isn't started for first time here
    #
    if [[ -f $SWAP_FILE ]]; then
        echo "Resize..."
        # If is enabled as swap, disable it
        if [[ $(swapon -s | tr ' ' '\n' | grep $SWAP_FILE) ]]; then
            echo "Disable swap for resize..."
            sudo swapoff $SWAP_FILE
        fi
        # Remove for remake again
        sudo rm -rf $SWAP_FILE
    fi

    # make swapfile
    sudo dd if=/dev/zero of=$SWAP_FILE bs=1M count=$size_file status=progress
    if [[ -f $SWAP_FILE ]]; then
        sudo chmod 0600 $SWAP_FILE
        sudo mkswap -U clear $SWAP_FILE
        sudo swapon $SWAP_FILE
    fi

    if [[ $(cat /etc/fstab | tr '\t' '\n' | grep /swapfile | tr -d '/') ]]; then
        echo "Already in fstab!"
    else
        read -p "You want put this in fstab? [y/N]: " write_fstab
        if [ "$write_fstab" == "y" ] || [ "$write_fstab" == "Y" ]; then
            sudo su -c "printf '\n# swap created with script' >> /etc/fstab"
            sudo su -c "printf '\n$SWAP_FILE\tnone\tswap\tdefaults\t0\t0\n' >> /etc/fstab"
        fi
    fi

    loadMemory
    printf "${BLU}New swap size: $MEMORY_SWAP GB${RST}\n"
}

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
if [[ ! -f ~/scripts/setup/android_build_env.sh ]]; then
  git clone https://github.com/akhilnarang/scripts --depth=1 $SCRIPT_DIR
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

  # Set the ccache directory
  export CCACHE_DIR=~/.ccache
  # Set the path to ccache executable
  export CCACHE_EXEC=$(which ccache)
  # Enable ccache
  export USE_CCACHE=1
  # Set cache size to 50 GB
  ccache -M 50G > /dev/null
  # Enable compression
  ccache -o compression=true > /dev/null
  # Zero statistics
  ccache -z > /dev/null

  # Append ccache config to .bashrc
  cat << EOF >> "$HOME/.bashrc"

# Generated ccache config
export USE_CCACHE=1
export CCACHE_EXEC=$CCACHE_EXEC
export CCACHE_DIR=$CCACHE_DIR
EOF
fi

#
# True only if RAM is less than 16 GB and SWAP is less than 30 GB
#
if [ $MEMORY_RAM -lt 16 ] && [ $MEMORY_SWAP -lt 30 ]; then
    echo "Your ram is less than 16 GB ($MEMORY_RAM GB) and your current swap is $MEMORY_SWAP GB"
    read -p "Do you want to add a swap partition? [y/N]: " enable_swap
    if [ "$enable_swap" == "y" ] || [ "$enable_swap" == "Y" ]; then
        echo "1) Swap on disk partition"
        echo "2) Swap on file"
        echo "0 (or other) exit"
        read -p "Chose [1-2]: " enable_swap
        if [[ "$enable_swap" == "1" ]]; then
            printf "${RED}WARNING: This script will FORMAT all the partition selected as SWAP."
            printf "\nIf you are not sure what do selection default N${RST}\n"
            read -p "Do you want continue? [y/N]" ImSure
            if [ "$ImSure" == "y" ] || [ "$ImSure" == "Y" ]; then
                SwapOnPartition
            else
                echo "Abort."
            fi
        fi

        if [[ "$enable_swap" == "2" ]]; then
            SwapOnFile
        fi
    fi
fi
