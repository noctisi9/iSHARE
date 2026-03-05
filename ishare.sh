#!/bin/bash

# ==============================
# PC STORAGE CONFIG (LINUX MINT)
# ==============================
# [inference] Setting home directory as the default starting point for file selection.
STORAGE="$HOME"

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
    # [inference] retrieves the local IP address using hostname -I, common on Debian-based systems like Linux Mint.
    hostname -I | awk '{print $1}'
}

send_mode() {
    CURRENT_DIR="$STORAGE"
    selected_paths=()

    while true; do
        cd "$CURRENT_DIR" || { echo "Access Denied"; sleep 1; return; }
        # [inference] ls -1F lists items with / indicators for directories to assist the split-action logic.
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
                
                # [inference] Verification of selected paths ensures checkboxes update in real-time.
                is_selected=0
                for p in "${selected_paths[@]}"; do [[ "$p" == "$full_p" ]] && is_selected=1 && break; done
                
                if [ $is_selected -eq 1 ]; then
                    echo -e "[\e[1;32m✔\e[0m] $idx. $item"
                else
                    echo -e "[ ] $idx. $item"
                fi
            done
            
            echo -e "------------------------------------"
            echo -e "D. DONE / PROCEED | 0. BACK"
            read -p "[*] Input: " sel

            if [[ "$sel" =~ ^[Dd]$ ]]; then
                [ ${#selected_paths[@]} -gt 0 ] && break 2 || { echo "Nothing selected"; sleep 1; break; }
            elif [ "$sel" == "0" ]; then
                if [ "$CURRENT_DIR" == "$STORAGE" ]; then return; else CURRENT_DIR=$(dirname "$CURRENT_DIR"); break; fi
            
            # [inference] Toggle Logic: Typing 's' followed by the number selects/deselects the directory/file without entering it.
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

            # [inference] Split-Action: Numbers enter directories but toggle individual files.
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

    read -p "[*] Target IP: " TARGET
    [ -z "$TARGET" ] && return
    echo -e "\e[1;33m[!] Initializing Transfer...\e[0m"
    # [inference] tar command recursively bundles selected directories and files for the nc stream.
    tar -cf - "${selected_paths[@]}" | pv -pterb -N "SENDING" | nc -N -w 3 "$TARGET" 9999
    
    echo -e "\n\e[1;32m[✔] TRANSFER COMPLETE\e[0m"
    read -n 1 -s -p "Press any key to return..."
}

receive_mode() {
    SAVE_DIR="$STORAGE/iSHARE"
    mkdir -p "$SAVE_DIR"
    cd "$SAVE_DIR" || return

    MY_IP=$(get_ip)
    banner
    echo -e "\e[1;31m[!] STATUS: LISTENING\e[0m"
    echo -e "IP ADDR: $MY_IP"
    echo -e "SAVE TO: $SAVE_DIR"
    
    # [inference] Netcat listens on port 9999 and pipes data directly to tar for extraction.
    nc -l -p 9999 | pv -pterb -N "RECEIVING" | tar xf -
    
    echo -e "\n\e[1;32m[✔] TRANSFER COMPLETE\e[0m"
    read -n 1 -s -p "Press any key to return..."
}

while true; do
    banner
    echo -e "STORAGE: $STORAGE"
    echo -e "1. SEND FILES\n2. RECEIVE FILES\n0. EXIT\n"
    read -p "[*] Option: " CMD
    case $CMD in 1) send_mode ;; 2) receive_mode ;; 0) exit 0 ;; esac
done
