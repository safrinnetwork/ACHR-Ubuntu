#!/usr/bin/env bash

# Function to display loading animation
show_loading() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    echo -n " "
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    echo " "
}

# Function to check for root access
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "\e[31mThis script must be run as root\e[0m" # Red color
        exit 1
    fi
}

# Function to display system details
show_system_details() {
    echo -e "\e[34mGathering system details...\e[0m" # Blue color
    IP=$(curl -s http://checkip.amazonaws.com)
    RAM=$(free -m | awk '/Mem:/ { print $2 }')
    CPU=$(lscpu | grep 'Model name' | cut -d: -f2 | xargs)
    STORAGE=$(df -h | awk '$NF=="/"{printf "%s", $2}')
    echo -e "\e[32mSystem Details:\nIP: $IP\nRAM: ${RAM}MB\nCPU: $CPU\nStorage: $STORAGE\e[0m" # Green color
}

# ASCII Banner
echo -e "\e[33m   _____   _    _   _____                         _           \e[0m"
echo -e "\e[33m  / ____| | |  | | |  __ \        /\             | |          \e[0m"
echo -e "\e[33m | |      | |__| | | |__) |      /  \     _   _  | |_    ___  \e[0m"
echo -e "\e[33m | |      |  __  | |  _  /      / /\ \   | | | | | __|  / _ \ \e[0m"
echo -e "\e[33m | |____  | |  | | | | \ \     / ____ \  | |_| | | |_  | (_) |\e[0m"
echo -e "\e[33m  \_____| |_|  |_| |_|  \_\   /_/    \_\  \__,_|  \__|  \___/ \e[0m"
echo -e "\e[33m                                                              \e[0m"
echo -e "\e[33m                            === By Mostech ===                 \e[0m"


# Check if the user is root
check_root

# Show system details
show_system_details

echo -e "\e[34mPreparation ...\e[0m" # Blue color
{
    apt install unzip -y > /dev/null 2>&1
} & show_loading

# Latest Stable
CHR_VERSION=6.49.7

# Environment
DISK=$(lsblk | grep "disk" | head -n 1 | cut -d' ' -f1)
INTERFACE=$(ip -o -4 route show to default | awk '{print $5}')
INTERFACE_IP=$(ip addr show $INTERFACE | grep global | cut -d' ' -f 6 | head -n 1)
INTERFACE_GATEWAY=$(ip route show | grep default | awk '{print $3}')

{
    wget -qO routeros.zip https://download.mikrotik.com/routeros/$CHR_VERSION/chr-$CHR_VERSION.img.zip && \
    unzip routeros.zip > /dev/null 2>&1 && \
    rm -rf routeros.zip
} & show_loading

{
    mount -o loop,offset=512 chr-$CHR_VERSION.img /mnt > /dev/null 2>&1
} & show_loading

echo "/ip address add address=${INTERFACE_IP} interface=[/interface ethernet find where name=ether1]
/ip route add gateway=${INTERFACE_GATEWAY}
" > /mnt/rw/autorun.scr

{
    umount /mnt > /dev/null 2>&1
    echo u > /proc/sysrq-trigger
    dd if=chr-$CHR_VERSION.img of=/dev/${DISK} bs=1M > /dev/null 2>&1
} & show_loading

echo -e "\e[32mInstallation complete. Reboot your server now, Please log in and configure your password using Winbox.\e[0m" # Green color
