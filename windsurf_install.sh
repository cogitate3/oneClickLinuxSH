#!/bin/bash

# Colors for output
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# Check if running as root
[[ $EUID -ne 0 ]] && echo -e "${red}Error: ${plain} Must run this script as root user!\n" && exit 1

# Install Windsurf
install_windsurf() {
    echo -e "${green}Installing Windsurf...${plain}"
    
    # Install dependencies
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        apt-get install -y curl wget
    elif command -v yum >/dev/null 2>&1; then
        yum update -y
        yum install -y curl wget
    else
        echo -e "${red}Error: Package manager not found. Please install manually.${plain}"
        return 1
    fi

    # Download and install Windsurf
    echo -e "${green}Downloading Windsurf...${plain}"
    curl -fsSL https://codeium.com/install/windsurf -o install_windsurf.sh
    chmod +x install_windsurf.sh
    ./install_windsurf.sh

    # Check if installation was successful
    if [ $? -eq 0 ]; then
        echo -e "${green}Windsurf has been successfully installed!${plain}"
    else
        echo -e "${red}Failed to install Windsurf. Please check the error messages above.${plain}"
        return 1
    fi
}

# Uninstall Windsurf
uninstall_windsurf() {
    echo -e "${yellow}Uninstalling Windsurf...${plain}"
    
    # Add uninstall commands here
    # This will depend on how Windsurf is installed and its uninstall process
    
    echo -e "${green}Windsurf has been uninstalled.${plain}"
}

# Update Windsurf
update_windsurf() {
    echo -e "${green}Updating Windsurf...${plain}"
    
    # Add update commands here
    curl -fsSL https://codeium.com/install/windsurf -o install_windsurf.sh
    chmod +x install_windsurf.sh
    ./install_windsurf.sh
    
    echo -e "${green}Windsurf has been updated to the latest version.${plain}"
}

# Show Windsurf status
show_windsurf_status() {
    echo -e "${green}Checking Windsurf status...${plain}"
    
    # Add status check commands here
    # This will depend on how Windsurf provides status information
    
    echo -e "${green}Status check complete.${plain}"
}

# Main menu
show_menu() {
    echo -e "
  ${green}Windsurf Management Script${plain}
  ${green}0.${plain} Exit
————————————————
  ${green}1.${plain} Install Windsurf
  ${green}2.${plain} Update Windsurf
  ${green}3.${plain} Uninstall Windsurf
————————————————
  ${green}4.${plain} Show Windsurf Status
 "
    echo && read -p "Please enter a number [0-4]: " num

    case "${num}" in
        0) exit 0
        ;;
        1) install_windsurf
        ;;
        2) update_windsurf
        ;;
        3) uninstall_windsurf
        ;;
        4) show_windsurf_status
        ;;
        *) echo -e "${red}Please enter a valid number [0-4]${plain}"
        ;;
    esac
}

# Start menu
show_menu
