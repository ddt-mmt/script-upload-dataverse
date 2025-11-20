#!/bin/bash

# File status dan log
# Mengambil variabel global dari skrip utama
RUN_DIR="run"
PID_FILE="$RUN_DIR/upload.pid"
LOG_FILE="$RUN_DIR/upload.log"
CONFIG_FILE="$RUN_DIR/config.sh"
LANG_DIR="lang"

# Pastikan direktori lang ada
if [ ! -d "$LANG_DIR" ]; then
    echo "Error: Direktori bahasa '$LANG_DIR' tidak ditemukan. Pastikan file bahasa ada." >&2
    exit 1
fi

# Muat preferensi bahasa
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    # Jika tidak ada config, default ke id
    LANG_CODE="id"
fi

# Fungsi untuk memuat pesan bahasa (duplikasi dari upload_dataverse.sh untuk kemandirian)
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
load_language_messages "$LANG_CODE"


# --- Fungsi Inti Upload ---
# Fungsi ini akan dijalankan di sub-shell background
run_upload() {
    # Argumen yang diterima:
    local api_key=$1
    local persistent_id=$2
    local file_path=$3
    local description=$4
    local directory_label=$5
    local json_categories=$6
    local is_restricted=$7
    local output_file=$8
    local file_size_bytes=$9 # New argument

    local START_TIME=$(date +%s)

    # Buat JSON payload dan URL
    local json_content
    json_content=$(printf '{"description":"%s","directoryLabel":"%s","categories":[%s],"restrict":%s,"tabIngest":false}' \
        "$description" \
        "$directory_label" \
        "$json_categories" \
        "$is_restricted")
    
    local api_url="https://cibinong-data.brin.go.id/api/datasets/:persistentId/add?persistentId=$persistent_id"

    echo "================================================================="
    echo "$MSG_STARTING_UPLOAD_BACKGROUND_TITLE"
    echo "================================================================="
    echo "$MSG_TIME_START$(date)"
    echo "$MSG_FILE_TO_UPLOAD$file_path"
    echo "$MSG_FILE_SIZE$(awk -v size="$file_size_bytes" 'BEGIN { if (size >= 1073741824) { printf "%.2f GB", size / 1073741824 } else if (size >= 1048576) { printf "%.2f MB", size / 1048576 } else if (size >= 1024) { printf "%.2f KB", size / 1024 } else { printf "%d B", size } }') "
    echo "$MSG_URL_TARGET$api_url"
    echo "----------------------------------------------------------------"
    
    # Konfigurasi Coba Ulang
    MAX_RETRIES=5
    RETRY_DELAY_SECONDS=30
    
    # Buat file sementara untuk JSON payload
    JSON_PAYLOAD_FILE=$(mktemp)
    echo "$json_content" > "$JSON_PAYLOAD_FILE"

    CURL_EXIT_CODE=1
    for (( i=1; i<=MAX_RETRIES; i++ )); do
        echo
        printf "$MSG_TRYING_UPLOAD\n" "$i" "$MAX_RETRIES"
        
        curl --progress-bar --tlsv1.2 \
          -o "$output_file" \
          -H "X-Dataverse-key: $api_key" \
          -X POST \
          -F "file=@$file_path" \
          -F "jsonData=@$JSON_PAYLOAD_FILE" \
          "$api_url"

        CURL_EXIT_CODE=$?

        if [ $CURL_EXIT_CODE -eq 0 ]; then
            echo
            printf "$MSG_UPLOAD_SUCCESS_ATTEMPT\n" "$i"
            
            local END_TIME=$(date +%s)
            local DURATION=$((END_TIME - START_TIME))

            echo "----------------------------------------------------------------"
            echo "$MSG_UPLOAD_START_TIME$(awk 'BEGIN { print strftime("%Y-%m-%d %H:%M:%S", '$START_TIME') }')"
            echo "$MSG_UPLOAD_END_TIME$(awk 'BEGIN { print strftime("%Y-%m-%d %H:%M:%S", '$END_TIME') }')"
            printf "$MSG_UPLOAD_DURATION%s menit %s detik\n" "$(($DURATION / 60))" "$(($DURATION % 60))"
            
            if [ "$DURATION" -gt 0 ] && [ "$file_size_bytes" -gt 0 ]; then
                local AVG_SPEED_BPS=$((file_size_bytes / DURATION))
                local AVG_SPEED_KBPS=$(awk -v speed="$AVG_SPEED_BPS" 'BEGIN { printf "%.2f", speed / 1024 }')
                local AVG_SPEED_MBPS=$(awk -v speed="$AVG_SPEED_BPS" 'BEGIN { printf "%.2f", speed / 1048576 }')

                echo -n "$MSG_AVG_SPEED"
                if (( $(echo "$AVG_SPEED_MBPS > 1" | bc -l) )); then
                    echo "${AVG_SPEED_MBPS} MB/s"
                elif (( $(echo "$AVG_SPEED_KBPS > 1" | bc -l) )); then
                    echo "${AVG_SPEED_KBPS} KB/s"
                else
                    echo "${AVG_SPEED_BPS} B/s"
                fi
                echo "$MSG_SPEED_NOTE"
            fi
            echo "----------------------------------------------------------------"
            break
        else
            echo
            printf "$MSG_UPLOAD_FAILED_ATTEMPT\n" "$i" "$CURL_EXIT_CODE"
            if [ $i -lt $MAX_RETRIES ]; then
                printf "$MSG_WAITING_RETRY\n" "$RETRY_DELAY_SECONDS"
                sleep $RETRY_DELAY_SECONDS
            else
                printf "$MSG_MAX_RETRIES_REACHED\n" "$MAX_RETRIES"
            fi
        fi
    done

    # Pesan "tunggu beberapa saat" setelah 100% upload
    if [ $CURL_EXIT_CODE -eq 0 ]; then
        sleep 2 # Tambahkan jeda singkat agar tidak tumpang tindih dengan output curl terakhir
        echo "================================================================================"
        echo " $MSG_TRANSFER_COMPLETE_WAITING_SERVER_RESPONSE"
        echo " $MSG_SERVER_RESPONSE_DELAY_NOTE"
        echo "================================================================================"
    fi

    rm "$JSON_PAYLOAD_FILE"

    echo "================================================================="
    if [ $CURL_EXIT_CODE -eq 0 ]; then
        echo "$MSG_UPLOAD_COMPLETE_SUCCESS"
        printf "$MSG_SERVER_RESPONSE_SAVED\n" "$output_file"
    else
        echo "$MSG_UPLOAD_COMPLETE_FAILED"
        echo "$MSG_PERMANENT_ERROR_CHECK_LOG"
    fi
    echo "================================================================="

    # Hapus file PID setelah selesai
    rm -f "$PID_FILE"
}


# --- Logika Utama Skrip ---

# 1. Cek apakah proses lain sedang berjalan
if [ -f "$PID_FILE" ]; then
    echo "$MSG_ERROR_ANOTHER_UPLOAD_RUNNING"
    echo "$MSG_MONITOR_OR_STOP_FROM_MENU"
    exit 1
fi

# 2. Hapus log lama dan siapkan file PID
rm -f "$LOG_FILE"
touch "$PID_FILE" # Buat file PID kosong sementara untuk mencegah race condition

# 3. Kumpulkan informasi dari pengguna (sama seperti skrip asli)
clear
echo "$MSG_START_NEW_UPLOAD_PROMPT_TITLE"
echo "$MSG_ENTER_UPLOAD_DETAILS_BACKGROUND"
echo
echo "================================================================================"
echo " $MSG_IMPORTANT_SECURITY_NOTE_1"
echo " $MSG_IMPORTANT_SECURITY_NOTE_2"
echo "================================================================================"
echo

read -p "$MSG_PROMPT_API_KEY" API_KEY
[ -z "$API_KEY" ] && { echo "$MSG_API_KEY_EMPTY" >&2; rm "$PID_FILE"; exit 1; }

read -p "$MSG_PROMPT_PERSISTENT_ID" PERSISTENT_ID
[ -z "$PERSISTENT_ID" ] && { echo "$MSG_PERSISTENT_ID_EMPTY" >&2; rm "$PID_FILE"; exit 1; }

read -p "$MSG_PROMPT_FILE_PATH" FILE_PATH
while [ ! -f "$FILE_PATH" ]; do
    printf "$MSG_FILE_NOT_FOUND\n" "$FILE_PATH" >&2
    read -p "$MSG_PROMPT_FILE_PATH" FILE_PATH
done

MAX_SIZE_BYTES=75161927680 # 70 GB
FILE_SIZE_BYTES=$(stat -c%s "$FILE_PATH")
if [ "$FILE_SIZE_BYTES" -gt "$MAX_SIZE_BYTES" ]; then
    FILE_SIZE_GB=$(awk -v size="$FILE_SIZE_BYTES" 'BEGIN { printf "%.2f", size / (1024*1024*1024) }')
    printf "$MSG_ERROR_FILE_SIZE_EXCEEDS\n" "${FILE_SIZE_GB}" >&2
    rm "$PID_FILE"; exit 1;
fis

read -p "${MSG_PROMPT_DESCRIPTION}[${MSG_DEFAULT_DESCRIPTION}]: " DESCRIPTION
DESCRIPTION=${DESCRIPTION:-"$MSG_DEFAULT_DESCRIPTION"}

read -p "${MSG_PROMPT_DIRECTORY_LABEL}[${MSG_DEFAULT_DIRECTORY_LABEL}]: " DIRECTORY_LABEL
DIRECTORY_LABEL=${DIRECTORY_LABEL:-"$MSG_DEFAULT_DIRECTORY_LABEL"}

read -p "${MSG_PROMPT_CATEGORIES}[${MSG_DEFAULT_CATEGORIES}]: " CATEGORIES_INPUT
CATEGORIES_INPUT=${CATEGORIES_INPUT:-"$MSG_DEFAULT_CATEGORIES"}

JSON_CATEGORIES=""
OLD_IFS=$IFS; IFS=','
set -f
for category in $CATEGORIES_INPUT; do
    category_trimmed=$(echo "$category" | xargs)
    [ -n "$JSON_CATEGORIES" ] && JSON_CATEGORIES="$JSON_CATEGORIES,"
    JSON_CATEGORIES="$JSON_CATEGORIES\"$category_trimmed\""
done
IFS=$OLD_IFS; set +f

read -p "${MSG_PROMPT_RESTRICT}" RESTRICT_CHOICE
IS_RESTRICTED="false"
if [[ "$RESTRICT_CHOICE" == "y" || "$RESTRICT_CHOICE" == "Y" ]]; then
    IS_RESTRICTED="true"
fi

read -p "${MSG_PROMPT_OUTPUT_FILE}[${MSG_DEFAULT_OUTPUT_FILE}]: " OUTPUT_FILE
OUTPUT_FILE=${OUTPUT_FILE:-"$MSG_DEFAULT_OUTPUT_FILE"}

# 4. Jalankan fungsi upload di background
echo
echo "$MSG_INFO_RECEIVED_STARTING_BACKGROUND"
echo "$MSG_MONITOR_FROM_MAIN_MENU"

# Menjalankan fungsi dalam sub-shell di background
# Semua output (stdout & stderr) dari sub-shell ini akan masuk ke LOG_FILE
(
    run_upload \
        "$API_KEY" \
        "$PERSISTENT_ID" \
        "$FILE_PATH" \
        "$DESCRIPTION" \
        "$DIRECTORY_LABEL" \
        "$JSON_CATEGORIES" \
        "$IS_RESTRICTED" \
        "$OUTPUT_FILE" \
        "$FILE_SIZE_BYTES"
) > "$LOG_FILE" 2>&1 &

# 5. Simpan PID dari proses background yang baru saja dijalankan
BG_PID=$!
echo $BG_PID > "$PID_FILE"

sleep 1
printf "$MSG_PROCESS_STARTED_PID\n" "$BG_PID"