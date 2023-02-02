# Android Setup Script
A script for setting up your Linux environment for Android development. This script will clone the [akhilnarang/scripts](https://github.com/akhilnarang/scripts) repository and run the necessary setup script based on your Linux distribution.

# Usage

Without downloading the repository you can directly download the script and run it.

#### via curl
```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/NextWork123/android_setup/main/script.sh)"
```
#### via wget
```shell
bash -c "$(wget https://raw.githubusercontent.com/NextWork123/android_setup/main/script.sh -O -)"
```

Instead if you want to download the repository you have to run the script with ```bash script.sh```.

The script will clone the akhilnarang/scripts repository and run the appropriate setup script for your Linux distribution.

# Support
This script supports the following Linux distributions:

- Ubuntu/Debian
- Manjaro/Arch/cachyos
- Solus
- Fedora

If your distribution is not supported, the script will exit with a message saying "Distribution Not Supported". But you can free to open a pull request or an issue and i will see if i can implement.

# Acknowledgments
Thank you to [akhilnarang](https://github.com/akhilnarang) for creating the scripts used in this project.
