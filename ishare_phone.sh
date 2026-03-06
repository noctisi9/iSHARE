#!/bin/bash

# ==============================
# STORAGE CONFIG
# ==============================
INTERNAL="/sdcard"
EXTERNAL=""
EXT_ID=""

banner() {
    clear
    echo -e "\e[1;31m"
    echo "  _ ____  _   _    _    ____  _____"
    echo " (_) ___|| | | |  / \  |  _ \| ____|"
    echo " | \___ \| |_| | / _ \ | |_) |  _|"
    echo " | |___) |  _  |/ ___ \|  _ <| |___"
    echo " |_|____/|_| |_/_/   \_\_| \_\_____|"
    echo " CREATED BY noctis nobunga"
    echo -e "\e[0m"
}

get_ip() {
    # [inference] prioritizing Android property system then falling back to standard ip routing.
    local ip=$(getprop dhcp.wlan0.ipaddress 2>/dev/null)
    [ -z "$ip" ] && ip=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}')
    [ -z "$ip" ] && ip=$(ip addr show wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 | head -n 1)
    echo "$ip"
}

send_mode() {
    while true; do
        banner
        echo -e "1. INTERNAL STORAGE\n2. EXTERNAL STORAGE\n0. BACK\n"
        read -p "[*] Option: " cat_choice
        case $cat_choice in
            1) 
               START_DIR="$INTERNAL"
               MODE="BROWSE" 
               ;;
            2) 
               read -p "[*] Enter SD Card UUID (Example: DA47-D4F0): " EXT_ID
               if [ -d "/storage/$EXT_ID" ] && [ -r "/storage/$EXT_ID" ]; then
                   EXTERNAL="/storage/$EXT_ID"
                   START_DIR="$EXTERNAL"
                   MODE="BROWSE"
               else
                   echo -e "\e[1;31m[!] Invalid UUID or SD Card not accessible\e[0m"
                   sleep 2
                   continue
               fi
               ;;
            0) return ;;
            *) continue ;;
        esac

        CURRENT_DIR="$START_DIR"
        selected_paths=()

        while true; do
            cd "$CURRENT_DIR" || { echo "Access Denied"; sleep 1; break; }
            # [inference] using -F to clearly mark directories with / for the split-action logic.
            mapfile -t items < <(ls -1F --group-directories-first 2>/dev/null)

            while true; do
                banner
                echo -e "LOCATION: $CURRENT_DIR"
                echo -e "------------------------------------"
                echo -e "COMMANDS: [Num] Enter Dir/File | [sNum] Select/Toggle Dir | [0] Back\n"
                
                for ((i=0; i<${#items[@]}; i++)); do
                    idx=$((i+1))
                    item="${items[$i]}"
                    full_p="${CURRENT_DIR%/}/${item%/}"
                    
                    is_selected=0
                    for p in "${selected_paths[@]}"; do [[ "$p" == "$full_p" ]] && is_selected=1 && break; done
                    
                    if [ $is_selected -eq 1 ]; then
                        echo -e "[\e[1;32m✔\e[0m] $idx. $item"
                    else
                        echo -e "[ ] $idx. $item"
                    fi
                done
                
                echo -e "------------------------------------"
                echo -e "D. DONE | 0. BACK"
                read -p "[*] Input: " sel

                if [[ "$sel" =~ ^[Dd]$ ]]; then
                    [ ${#selected_paths[@]} -gt 0 ] && break 3 || { echo "Nothing selected"; sleep 1; break; }
                elif [ "$sel" == "0" ]; then
                    if [ "$CURRENT_DIR" == "$START_DIR" ]; then break 2; else CURRENT_DIR=$(dirname "$CURRENT_DIR"); break; fi
                
                # --- NEW SPLIT ACTION LOGIC ---
                # [inference] Type 's' before number to toggle a directory without entering it.
                elif [[ "$sel" =~ ^s[0-9]+$ ]]; then
                    val=${sel#s}
                    target_idx=$((val-1))
                    [ $target_idx -lt 0 ] || [ $target_idx -ge ${#items[@]} ] && continue
                    
                    target_item="${items[$target_idx]}"
                    full_p="${CURRENT_DIR%/}/${target_item%/}"
                    
                    found_idx=-1
                    for i in "${!selected_paths[@]}"; do
                        if [[ "${selected_paths[i]}" == "$full_p" ]]; then found_idx=$i; break; fi
                    done
                    
                    if [ $found_idx -ge 0 ]; then
                        unset 'selected_paths[found_idx]'
                        selected_paths=("${selected_paths[@]}") # Re-index
                    else
                        selected_paths+=("$full_p")
                    fi

                # [inference] Standard number input enters directory but toggles individual files.
                elif [[ "$sel" =~ ^[0-9]+$ ]]; then
                    target_idx=$((sel-1))
                    [ $target_idx -lt 0 ] || [ $target_idx -ge ${#items[@]} ] && continue
                    
                    target_item="${items[$target_idx]}"
                    full_p="${CURRENT_DIR%/}/${target_item%/}"

                    if [[ "$target_item" == */ ]]; then
                        CURRENT_DIR="$full_p"
                        break
                    else
                        found_idx=-1
                        for i in "${!selected_paths[@]}"; do
                            if [[ "${selected_paths[i]}" == "$full_p" ]]; then found_idx=$i; break; fi
                        done
                        
                        if [ $found_idx -ge 0 ]; then
                            unset 'selected_paths[found_idx]'
                            selected_paths=("${selected_paths[@]}")
                        else
                            selected_paths+=("$full_p")
                        fi
                    fi
                fi
            done
        done
    done

    read -p "[*] Receiver IP: " TARGET
    [ -z "$TARGET" ] && return
    echo -e "\e[1;33m[!] Initializing Transfer...\e[0m"
    
    # [inference] using -N to ensure netcat terminates properly after data is sent.
    tar -cf - "${selected_paths[@]}" | pv -pterb -N "SENDING" | nc -N -w 3 "$TARGET" 9999
    
    echo -e "\n\e[1;32m[✔] TRANSFER COMPLETE\e[0m"
    read -n 1 -s -p "Press any key to return..."
}

receive_mode() {
    while true; do
        banner
        echo -e "1. INTERNAL STORAGE\n2. EXTERNAL STORAGE\n0. BACK\n"
        read -p "[*] Choose: " loc

        case $loc in
            1) 
               BASE_DIR="$INTERNAL" 
               break 
               ;;
            2)
               if [ "$EXTERNAL" == "/dev/null/no_sd_card" ] || [ -z "$EXTERNAL" ]; then
                   read -p "[*] Enter SD Card UUID (Example: DA47-D4F0): " EXT_ID
                   if [ -d "/storage/$EXT_ID" ]; then
                       EXTERNAL="/storage/$EXT_ID"
                   else
                       echo -e "\e[1;31m[!] No External SD Card Detected\e[0m"
                       sleep 1
                       continue
                   fi
               fi
               BASE_DIR="$EXTERNAL"
               break 
               ;;
            0) return ;;
            *) continue ;;
        esac
    done

    SAVE_DIR="$BASE_DIR/iSHARE"
    mkdir -p "$SAVE_DIR"
    cd "$SAVE_DIR" || return

    MY_IP=$(get_ip)
    banner
    echo -e "\e[1;31m[!] STATUS: LISTENING\e[0m"
    echo -e "IP ADDR: $MY_IP"
    echo -e "SAVE TO: $SAVE_DIR"

    nc -l -p 9999 | pv -pterb -N "RECEIVING" | tar xf -

    echo -e "\n\e[1;32m[✔] TRANSFER COMPLETE\e[0m"
    read -n 1 -s -p "Press any key to return..."
}

while true; do
    banner
    echo -e "1. SEND FILES\n2. RECEIVE FILES\n0. EXIT\n"
    read -p "[*] Option: " CMD
    case $CMD in 1) send_mode ;; 2) receive_mode ;; 0) exit 0 ;; esac
done
