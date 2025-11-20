#!/bin/bash

# Direktori kerja dan file status
RUN_DIR="run"
PID_FILE="$RUN_DIR/upload.pid"
LOG_FILE="$RUN_DIR/upload.log"
CONFIG_FILE="$RUN_DIR/config.sh"
LANG_DIR="lang"

# Pastikan direktori skrip ada
SCRIPT_DIR="scripts"
if [ ! -d "$SCRIPT_DIR" ]; then
    echo "Error: Direktori 'scripts' tidak ditemukan. Pastikan semua file skrip ada di sana." >&2
    exit 1
fi

# --- Fungsi untuk memuat pesan bahasa ---
load_language_messages() {
    local lang_code=$1
    if [ -f "$LANG_DIR/$lang_code.sh" ]; then
        source "$LANG_DIR/$lang_code.sh"
    else
        # Fallback ke Bahasa Indonesia jika file bahasa tidak ditemukan
        source "$LANG_DIR/id.sh"
        echo "Peringatan: File bahasa '$lang_code.sh' tidak ditemukan. Menggunakan Bahasa Indonesia." >&2
    fi
}

# --- Fungsi untuk menyimpan preferensi bahasa ---
save_language_preference() {
    local lang_code=$1
    mkdir -p "$RUN_DIR"
    echo "LANG_CODE=\"$lang_code\"" > "$CONFIG_FILE"
}

# --- Fungsi untuk memilih bahasa ---
choose_language() {
    clear
    echo "#################################################"
    echo "#                     NETLOAD                   #"
    echo "#################################################"
    echo "      Dataverse Upload & Monitoring Tool         "
    echo "-------------------------------------------------"
    echo
    # These messages must be hardcoded or loaded from a default before selection
    echo "Pilih Bahasa / Choose Language:"
    echo "1. Bahasa Indonesia"
    echo "2. English"
    echo "-------------------------------------------------"
    read -p "Masukkan pilihan Anda [1-2]: " lang_choice

    case $lang_choice in
        1) LANG_CODE="id" ;;
        2) LANG_CODE="en" ;;
        *)
            echo "Pilihan tidak valid."
            sleep 1
            choose_language # Ulangi pemilihan bahasa
            return
            ;;
    esac
    save_language_preference "$LANG_CODE"
    echo "Menyimpan preferensi bahasa..."
    sleep 1
    # Muat ulang pesan setelah bahasa dipilih
    load_language_messages "$LANG_CODE"
}

# --- Muat preferensi bahasa atau minta pengguna memilih ---
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    if [ -z "$LANG_CODE" ]; then
        choose_language
    fi
else
    choose_language
fi

# Muat pesan bahasa berdasarkan LANG_CODE yang sudah ditentukan
load_language_messages "$LANG_CODE"


# Fungsi untuk menampilkan menu utama
show_main_menu() {
    clear
    echo "#################################################"
    echo "#                     NETLOAD                   #"
    echo "#################################################"
    echo "      Dataverse Upload & Monitoring Tool         "
    echo "-------------------------------------------------"
    echo
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        # Periksa apakah PID tidak kosong dan hanya berisi angka sebelum memanggil ps
        if [ -n "$PID" ] && [[ "$PID" =~ ^[0-9]+$ ]] && ps -p "$PID" > /dev/null; then
            printf "$MSG_STATUS_UPLOAD_RUNNING\n" "$PID"
            echo
            echo "$MSG_CHOOSE_OPTION"
            echo "$MSG_MENU_MONITOR_UPLOAD"
            echo "$MSG_MENU_STOP_UPLOAD"
            echo "$MSG_MENU_VIEW_FULL_LOG"
            echo "$MSG_MENU_CHANGE_LANGUAGE" # New line
            echo "$MSG_MENU_EXIT"
        else
            echo "$MSG_STATUS_STALE_PID"
            echo "$MSG_STATUS_CHECK_LOG_BEFORE_NEW"
            echo
            echo "$MSG_CHOOSE_OPTION"
            echo "$MSG_MENU_START_NEW_UPLOAD_STALE"
            echo "$MSG_MENU_VIEW_LAST_LOG_STALE"
            echo "$MSG_MENU_CLEAN_STALE_STATUS"
            echo "$MSG_MENU_CHANGE_LANGUAGE_STALE" # New line
            echo "$MSG_MENU_EXIT_STALE"
        fi
    else
        echo "$MSG_STATUS_NO_ACTIVE_UPLOAD"
        echo
        echo "$MSG_CHOOSE_OPTION"
        echo "$MSG_MENU_START_NEW_UPLOAD"
        echo "$MSG_MENU_VIEW_LAST_LOG"
        echo "$MSG_MENU_CHANGE_LANGUAGE_NO_PROCESS" # New line
        echo "$MSG_MENU_EXIT_NO_PROCESS"
    fi
    echo "-------------------------------------------------"
}

# Loop menu utama
while true; do
    show_main_menu
    
    if [ -f "$PID_FILE" ] && [ -n "$(cat "$PID_FILE")" ] && [[ "$(cat "$PID_FILE")" =~ ^[0-9]+$ ]] && ps -p "$(cat "$PID_FILE")" > /dev/null; then
        # Menu saat proses berjalan
        read -p "$MSG_PROMPT_ENTER_CHOICE_RUNNING" choice
        case $choice in
            1) bash "$SCRIPT_DIR/monitor_upload.sh" ;;
            2) bash "$SCRIPT_DIR/stop_upload.sh" ;;
            3) less "$LOG_FILE" ;;
            5) choose_language ;; # New option for change language
            4) echo "$MSG_EXITING_APP"; exit 0 ;; 
            *) echo "$MSG_INVALID_CHOICE" ;; 
        esac
    elif [ -f "$PID_FILE" ]; then
        # Menu saat ada PID file usang
        read -p "$MSG_PROMPT_ENTER_CHOICE_STALE" choice
        case $choice in
            s|S) bash "$SCRIPT_DIR/start_upload.sh" ;; 
            l|L) less "$LOG_FILE" ;; 
            c|C) 
                rm -f "$PID_FILE"
                echo "$MSG_STALE_STATUS_CLEANED"
                sleep 1
                ;; 
            L|l) choose_language ;; # New option for change language
            q|Q) echo "$MSG_EXITING_APP"; exit 0 ;; 
            *) echo "$MSG_INVALID_CHOICE" ;; 
        esac
    else
        # Menu saat tidak ada proses
        read -p "$MSG_PROMPT_ENTER_CHOICE_NO_PROCESS" choice
        case $choice in
            1) bash "$SCRIPT_DIR/start_upload.sh" ;; 
            2) 
                if [ -f "$LOG_FILE" ]; then
                    less "$LOG_FILE"
                else
                    echo "$MSG_LOG_FILE_NOT_EXIST"
                    sleep 1
                fi
                ;; 
            4) choose_language ;; # New option for change language
            3) echo "$MSG_EXITING_APP"; exit 0 ;; 
            *) echo "$MSG_INVALID_CHOICE" ;; 
        esac
    fi
    echo
    read -p "$MSG_PROMPT_PRESS_ENTER_TO_CONTINUE"
done