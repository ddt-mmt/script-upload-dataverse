#!/bin/bash

# Direktori kerja dan file status
RUN_DIR="run"
JOBS_DIR="$RUN_DIR/jobs" # Direktori baru untuk mengelola semua job
CONFIG_FILE="$RUN_DIR/config.sh"
LANG_DIR="lang"
SCRIPT_DIR="scripts"

# --- Inisialisasi ---
# Buat direktori yang diperlukan jika belum ada
mkdir -p "$JOBS_DIR"
# Pastikan direktori skrip ada
if [ ! -d "$SCRIPT_DIR" ]; then
    echo "Error: Direktori 'scripts' tidak ditemukan." >&2
    exit 1
fi

# --- Fungsi untuk memuat pesan bahasa ---
load_language_messages() {
    local lang_code=$1
    if [ -f "$LANG_DIR/$lang_code.sh" ]; then
        source "$LANG_DIR/$lang_code.sh"
    else
        source "$LANG_DIR/id.sh" # Fallback
    fi
}

# --- Fungsi untuk menyimpan preferensi bahasa ---
save_language_preference() {
    mkdir -p "$RUN_DIR"
    echo "LANG_CODE=\"$1\"" > "$CONFIG_FILE"
}

# --- Fungsi untuk memilih bahasa ---
choose_language() {
    clear
    echo "Pilih Bahasa / Choose Language:"
    echo "1. Bahasa Indonesia"
    echo "2. English"
    read -e lang_choice
    case $lang_choice in
        1) LANG_CODE="id" ;; 
        2) LANG_CODE="en" ;; 
        *) echo "Pilihan tidak valid."; sleep 1; return ;; 
esac
    save_language_preference "$LANG_CODE"
    load_language_messages "$LANG_CODE"
}

# --- Muat atau pilih bahasa saat start ---
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    if [ -z "$LANG_CODE" ]; then
        choose_language
    fi
else
    choose_language
fi
load_language_messages "$LANG_CODE"


# --- Fungsi untuk memulai Job Unggahan Baru ---
start_new_job() {
    # Format baru: job_HHMMSS_XXXX (e.g., job_213731_0a1b)
    # Menggabungkan waktu (HHMMSS) dan 4 karakter heksadesimal acak
    local JOB_ID="job_$(date +%H%M%S)_$(printf "%04x" $RANDOM)"
    local JOB_DIR="$JOBS_DIR/$JOB_ID"

    if mkdir -p "$JOB_DIR"; then
        echo "$MSG_JOB_STARTED" "$JOB_ID"
        # Panggil skrip start, berikan ID job. Skrip ini akan interaktif.
        bash "$SCRIPT_DIR/start_upload.sh" "$JOB_ID"
        
        # Beri jeda agar pengguna bisa membaca output dari skrip start
        echo
        echo "$MSG_PROMPT_PRESS_ENTER_TO_CONTINUE"
        read -e
    else
        printf "$MSG_FAILED_TO_CREATE_JOB_DIR\n" "$JOB_ID" >&2
        sleep 2
    fi
}

# --- Fungsi untuk Melihat dan Mengelola Job Aktif ---
manage_active_jobs() {
    while true; do
        clear
        echo "$MSG_MANAGE_ACTIVE_JOBS_TITLE"
        echo "-------------------------------------------------"

        declare -a active_jobs
        
        # Header tabel
        printf "%-20s %-10s %s\n" "$MSG_JOB_LIST_HEADER_ID" "$MSG_JOB_LIST_HEADER_PID" "$MSG_JOB_LIST_HEADER_SOURCE"
        echo "-------------------------------------------------"

        # Cek apakah direktori jobs ada dan tidak kosong
        if [ ! -d "$JOBS_DIR" ] || [ -z "$(ls -A $JOBS_DIR)" ]; then
            echo "$MSG_NO_ACTIVE_JOBS"
        else
            for job_dir in "$JOBS_DIR"/*/; do
                local job_id
                job_id=$(basename "$job_dir")
                local pid_file="$job_dir/upload.pid"
                local info_file="$job_dir/job_info.txt"

                if [ -f "$pid_file" ]; then
                    local pid
                    pid=$(cat "$pid_file")
                    if [ -n "$pid" ] && ps -p "$pid" > /dev/null; then
                        active_jobs+=("$job_id")
                        local source_path="N/A"
                        if [ -f "$info_file" ]; then
                            source "$info_file" # This loads SOURCE_PATH
                        fi
                        printf "%-20s %-10s %s\n" "$job_id" "$pid" "$SOURCE_PATH"
                    fi
                fi
            done
        fi

        if [ ${#active_jobs[@]} -eq 0 ]; then
            echo "$MSG_NO_ACTIVE_JOBS"
        fi
        echo "-------------------------------------------------"
        echo
        echo "$MSG_SELECT_JOB_PROMPT"
        read -e selected_job_id

        if [[ "$selected_job_id" == "q" || "$selected_job_id" == "Q" ]]; then
            return
        fi

        # Validasi apakah job yang dipilih ada di daftar aktif
        local is_valid_job=false
        for job in "${active_jobs[@]}"; do
            if [ "$job" == "$selected_job_id" ]; then
                is_valid_job=true
                break
            fi
        done

        if $is_valid_job; then
            # Tampilkan sub-menu aksi
            printf "$MSG_JOB_ACTION_PROMPT\n" "$selected_job_id"
            read -e action_choice
            case $action_choice in
                1) bash "$SCRIPT_DIR/monitor_upload.sh" "$selected_job_id" ;;
                2) bash "$SCRIPT_DIR/stop_upload.sh" "$selected_job_id" ;;
                q|Q) continue ;;
                *) echo "$MSG_INVALID_CHOICE" ;;
            esac
            echo "$MSG_PROMPT_PRESS_ENTER_TO_CONTINUE"
            read -e
        else
            printf "$MSG_JOB_ID_NOT_FOUND\n" "$selected_job_id"
            sleep 1
        fi
    done
}

# --- Fungsi untuk Melihat Riwayat Job ---
view_job_history() {
    while true; do
        clear
        echo "$MSG_JOB_HISTORY_TITLE"
        echo "-------------------------------------------------"

        declare -a completed_jobs
        
        # Header tabel
        printf "%-20s %-12s %s\n" "$MSG_JOB_LIST_HEADER_ID" "$MSG_JOB_HISTORY_HEADER_STATUS" "$MSG_JOB_LIST_HEADER_SOURCE"
        echo "-------------------------------------------------"

        if [ ! -d "$JOBS_DIR" ] || [ -z "$(ls -A $JOBS_DIR)" ]; then
            echo "$MSG_NO_COMPLETED_JOBS"
        else
            for job_dir in "$JOBS_DIR"/*/; do
                local job_id=$(basename "$job_dir")
                local pid_file="$job_dir/upload.pid"
                local info_file="$job_dir/job_info.txt"
                local status_file="$job_dir/status"

                local is_active=false
                if [ -f "$pid_file" ]; then
                    local pid=$(cat "$pid_file")
                    if [ -n "$pid" ] && ps -p "$pid" > /dev/null; then
                        is_active=true
                    fi
                fi

                if ! $is_active; then
                    completed_jobs+=("$job_id")
                    local source_path="N/A"
                    local status="N/A"

                    if [ -f "$info_file" ]; then
                        source "$info_file"
                    fi
                    if [ -f "$status_file" ]; then
                        status=$(cat "$status_file")
                    fi
                    
                    # Terjemahkan status jika perlu
                    local display_status=$status
                    case $status in
                        "COMPLETED") display_status=$MSG_JOB_HISTORY_STATUS_COMPLETED ;;
                        "FAILED") display_status=$MSG_JOB_HISTORY_STATUS_FAILED ;;
                        "STOPPED") display_status=$MSG_JOB_HISTORY_STATUS_STOPPED ;;
                    esac

                    printf "%-20s %-12s %s\n" "$job_id" "$display_status" "$SOURCE_PATH"
                fi
            done
        fi

        if [ ${#completed_jobs[@]} -eq 0 ]; then
            echo "$MSG_NO_COMPLETED_JOBS"
        fi
        echo "-------------------------------------------------"
        echo
        echo "$MSG_SELECT_JOB_LOG_PROMPT"
        read -e selected_job_id

        if [[ "$selected_job_id" == "q" || "$selected_job_id" == "Q" ]]; then
            return
        fi

        # Validasi
        local is_valid_job=false
        for job in "${completed_jobs[@]}"; do
            if [ "$job" == "$selected_job_id" ]; then
                is_valid_job=true
                break
            fi
        done

        if $is_valid_job; then
            local log_file="$JOBS_DIR/$selected_job_id/upload.log"
            if [ -f "$log_file" ]; then
                less "$log_file"
            else
                echo "$MSG_LOG_FILE_NOT_EXIST"
                sleep 1
            fi
        else
            printf "$MSG_JOB_ID_NOT_FOUND\n" "$selected_job_id"
            sleep 1
        fi
    done
}


# --- Fungsi untuk menampilkan menu utama ---
show_main_menu() {
    clear
    echo "#################################################"
    echo "#            NETLOAD (Multi-Job)                #"
    echo "#################################################"
    echo "      Dataverse Upload & Monitoring Tool         "
    echo "-------------------------------------------------"
    echo
    echo "$MSG_CHOOSE_OPTION"
    echo "$MSG_MENU_START_NEW_JOB"
    echo "$MSG_MENU_MANAGE_ACTIVE_JOBS"
    echo "$MSG_MENU_VIEW_JOB_HISTORY"
    echo "$MSG_MENU_CHANGE_LANGUAGE"
    echo "$MSG_MENU_EXIT"
    echo "-------------------------------------------------"
    echo "$MSG_PROMPT_ENTER_CHOICE_RUNNING"
}

# --- Loop Menu Utama ---
while true; do
    show_main_menu
    read -e choice
    case $choice in
        1) start_new_job ;;
        2) manage_active_jobs ;;
        3) view_job_history ;;
        4) choose_language ;;
        5) echo "$MSG_EXITING_APP"; exit 0 ;;
        *) echo "$MSG_INVALID_CHOICE"; sleep 1 ;; 
esac
done