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
    echo "$MSG_URL_TARGET$api_url"
    echo "----------------------------------------------------------------"
    
    # Konfigurasi Coba Ulang
    MAX_RETRIES=5
    RETRY_DELAY_SECONDS=30
    
    # Buat file sementara untuk JSON payload dan config curl
    JSON_PAYLOAD_FILE=$(mktemp)
    echo "$json_content" > "$JSON_PAYLOAD_FILE"
    
    CURL_CONFIG_FILE=$(mktemp)
    echo "header = \"X-Dataverse-key: $api_key\"" > "$CURL_CONFIG_FILE"

    CURL_EXIT_CODE=1
    for (( i=1; i<=MAX_RETRIES; i++ )); do
        echo
        printf "$MSG_TRYING_UPLOAD\n" "$i" "$MAX_RETRIES"
        
        curl --progress-bar --tlsv1.2 \
          -o "$output_file" \
          --config "$CURL_CONFIG_FILE" \
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

    # Setelah sukses, tidak melakukan apa-apa pada file asli (tetap ada)
    if [ $CURL_EXIT_CODE -eq 0 ]; then
        # The original file is explicitly not deleted as per user's request.
        : # No operation
    fi

    # Hapus semua file sementara dengan aman
    rm -f "$JSON_PAYLOAD_FILE" "$CURL_CONFIG_FILE"

    echo "================================================================="
    if [ $CURL_EXIT_CODE -eq 0 ]; then
        echo "$MSG_UPLOAD_COMPLETE_SUCCESS"
        printf "$MSG_SERVER_RESPONSE_SAVED\n" "$output_file"
        rm "$output_file" # Delete the temporary result file
        echo "$MSG_RESULT_FILE_DELETED" # New message for confirmation
    else
        echo "$MSG_UPLOAD_COMPLETE_FAILED"
        echo "$MSG_PERMANENT_ERROR_CHECK_LOG"
        printf "$MSG_ERROR_RESULT_FILE_RETAINED\n" "$output_file" # New message for retaining error file
    fi
    echo "================================================================="

    # Kembalikan exit code dari curl untuk penanganan error di loop folder
    return $CURL_EXIT_CODE
}


# --- Logika Utama Skrip ---

# 1. Cek apakah proses lain sedang berjalan
if [ -f "$PID_FILE" ]; then
    echo "$MSG_ERROR_ANOTHER_UPLOAD_RUNNING"
    echo "$MSG_MONITOR_OR_STOP_FROM_MENU"
    exit 1
fi

# 2. Hapus log lama dan siapkan file PID
# Lakukan ini setelah mendapat konfirmasi dari pengguna
# rm -f "$LOG_FILE"

# 3. Kumpulkan informasi dari pengguna
clear
echo "$MSG_START_NEW_UPLOAD_PROMPT_TITLE"
echo "$MSG_ENTER_UPLOAD_DETAILS_BACKGROUND"
echo
echo "================================================================================"
echo " $MSG_IMPORTANT_SECURITY_NOTE_1"
echo " $MSG_IMPORTANT_SECURITY_NOTE_2"
echo "================================================================================"
echo

# --- Kredensial & Target ---
echo "$MSG_PROMPT_API_KEY"
read -e API_KEY # Tampilkan input agar tidak salah ketik
echo
[ -z "$API_KEY" ] && { echo "$MSG_API_KEY_EMPTY" >&2; exit 1; }

echo "$MSG_PROMPT_PERSISTENT_ID"
read -e PERSISTENT_ID
[ -z "$PERSISTENT_ID" ] && { echo "$MSG_PERSISTENT_ID_EMPTY" >&2; exit 1; }


# --- Tipe Unggahan (File atau Folder) ---
echo "$MSG_PROMPT_UPLOAD_TYPE"
read -e UPLOAD_TYPE
UPLOAD_TYPE=${UPLOAD_TYPE:-"1"}

declare -a FILE_PATHS
SOURCE_PATH=""

if [ "$UPLOAD_TYPE" = "1" ]; then
    # --- Unggahan File Tunggal ---
    echo "$MSG_PROMPT_FILE_PATH"
    read -e FILE_PATH
    while [ ! -f "$FILE_PATH" ]; do
        printf "$MSG_FILE_NOT_FOUND\n" "$FILE_PATH" >&2
        echo "$MSG_PROMPT_FILE_PATH"
        read -e FILE_PATH
    done
    FILE_PATHS+=("$FILE_PATH")
    SOURCE_PATH="$FILE_PATH"

else
    # --- Unggahan Folder ---
    echo "$MSG_PROMPT_FOLDER_PATH"
    read -e FOLDER_PATH
    while [ ! -d "$FOLDER_PATH" ]; do
        printf "$MSG_FOLDER_NOT_FOUND\n" "$FOLDER_PATH" >&2
        echo "$MSG_PROMPT_FOLDER_PATH"
        read -e FOLDER_PATH
    done
    SOURCE_PATH="$FOLDER_PATH"

    # Temukan semua file dalam folder dan subfolder
    while IFS= read -r -d $'\0' file; do
        FILE_PATHS+=("$file")
    done < <(find "$FOLDER_PATH" -type f -print0)

    if [ ${#FILE_PATHS[@]} -eq 0 ]; then
        printf "$MSG_NO_FILES_IN_FOLDER\n" "$FOLDER_PATH"
        exit 0
    fi
fi


# --- Metadata Umum ---
echo "${MSG_PROMPT_DESCRIPTION}[${MSG_DEFAULT_DESCRIPTION}]:"
read -e DESCRIPTION
DESCRIPTION=${DESCRIPTION:-"$MSG_DEFAULT_DESCRIPTION"}

DIRECTORY_LABEL_PROMPT_MSG="$MSG_PROMPT_DIRECTORY_LABEL"
DEFAULT_DIRECTORY_LABEL_MSG="$MSG_DEFAULT_DIRECTORY_LABEL"
# Hanya minta label direktori untuk unggahan file tunggal
if [ "$UPLOAD_TYPE" = "1" ]; then
    echo "${DIRECTORY_LABEL_PROMPT_MSG}[${DEFAULT_DIRECTORY_LABEL_MSG}]:"
    read -e DIRECTORY_LABEL
    DIRECTORY_LABEL=${DIRECTORY_LABEL:-"$DEFAULT_DIRECTORY_LABEL_MSG"}
fi

echo "${MSG_PROMPT_CATEGORIES}[${MSG_DEFAULT_CATEGORIES}]:"
read -e CATEGORIES_INPUT
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

echo "${MSG_PROMPT_RESTRICT}"
read -e RESTRICT_CHOICE
IS_RESTRICTED="false"
if [[ "$RESTRICT_CHOICE" == "y" || "$RESTRICT_CHOICE" == "Y" ]]; then
    IS_RESTRICTED="true"
fi


# --- Konfirmasi Akhir ---
echo
echo "================================================================="
echo "$MSG_UPLOAD_SUMMARY_TITLE"
echo "================================================================="
if [ "$UPLOAD_TYPE" = "1" ]; then
    echo "$MSG_UPLOAD_SUMMARY_TYPE_FILE"
else
    echo "$MSG_UPLOAD_SUMMARY_TYPE_FOLDER"
fi
printf "$MSG_UPLOAD_SUMMARY_TOTAL_FILES\n" "${#FILE_PATHS[@]}"
printf "$MSG_UPLOAD_SUMMARY_SOURCE_PATH\n" "$SOURCE_PATH"
printf "$MSG_UPLOAD_SUMMARY_PERSISTENT_ID\n" "$PERSISTENT_ID"
echo "$MSG_UPLOAD_SUMMARY_API_KEY"
echo "================================================================="
echo
echo "$MSG_UPLOAD_CONFIRM_PROMPT"
read -e CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "$MSG_UPLOAD_ABORTED"
    exit 0
fi


# --- Fungsi Master Background ---
# Fungsi ini yang akan dijalankan di background, membungkus semua logika upload
start_background_process() {
    # Argumen pertama adalah path ke file config sementara
    local input_config_file=$1
    if [ -f "$input_config_file" ]; then
        # Muat semua variabel dari file config
        source "$input_config_file"
        # Hapus file config segera setelah dimuat untuk keamanan
        rm "$input_config_file"
    else
        echo "FATAL: File konfigurasi input tidak ditemukan." >&2
        rm -f "$PID_FILE" # Hapus PID file jika ada
        exit 1
    fi

    # Helper function to convert bytes to a human-readable format
    human_readable_size() {
        local bytes=$1
        # Membutuhkan 'bc' untuk kalkulasi floating point.
        if ! command -v bc &> /dev/null; then
            echo "${bytes} B"
            return
        fi

        if [ "$bytes" -lt 1024 ]; then
            echo "${bytes} B"
        elif [ "$bytes" -lt 1048576 ]; then
            printf "%.2f KB\n" "$(bc -l <<< "$bytes / 1024")"
        elif [ "$bytes" -lt 1073741824 ]; then
            printf "%.2f MB\n" "$(bc -l <<< "$bytes / 1048576")"
        else
            printf "%.2f GB\n" "$(bc -l <<< "$bytes / 1073741824")"
        fi
    }

    if [ "$UPLOAD_TYPE" = "1" ]; then
        # --- Unggah File Tunggal ---
        local file_path="${FILE_PATHS[0]}"
        local output_file="result_$(basename "$file_path" | sed 's/\.[^.]*$//')_$(date +%s).json"
        
        run_upload \
            "$API_KEY" \
            "$PERSISTENT_ID" \
            "$file_path" \
            "$DESCRIPTION" \
            "$DIRECTORY_LABEL" \
            "$JSON_CATEGORIES" \
            "$IS_RESTRICTED" \
            "$output_file"
    else
        # --- Unggah Folder ---
        local MASTER_START_TIME=$(date +%s)
        local TOTAL_FILES_COUNT=${#FILE_PATHS[@]}
        local SUCCESSFUL_UPLOADS=0
        local TOTAL_UPLOAD_SIZE=0

        # Hitung total ukuran di awal
        for file in "${FILE_PATHS[@]}"; do
            if [ -r "$file" ]; then
                TOTAL_UPLOAD_SIZE=$((TOTAL_UPLOAD_SIZE + $(stat -c%s "$file")))
            fi
        done
        
        local base_folder_path="$SOURCE_PATH"
        # Pastikan path folder diakhiri slash untuk 'sed'
        [[ "$base_folder_path" != */ ]] && base_folder_path="$base_folder_path/"

        for file in "${FILE_PATHS[@]}"; do
            local relative_path=${file#$base_folder_path}
            local new_dir_label=$(dirname "$relative_path")
            [ "$new_dir_label" = "." ] && new_dir_label=""

            local file_basename=$(basename "$file")
            local unique_output_file="result_${file_basename%.*}_$(date +%s).json"

            run_upload \
                "$API_KEY" \
                "$PERSISTENT_ID" \
                "$file" \
                "$DESCRIPTION" \
                "$new_dir_label" \
                "$JSON_CATEGORIES" \
                "$IS_RESTRICTED" \
                "$unique_output_file"
            
            local upload_exit_code=$?
            if [ $upload_exit_code -ne 0 ]; then
                printf "$MSG_FOLDER_UPLOAD_FAILED\n" "$file" >&2
                rm -f "$PID_FILE"
                exit 1 # Hentikan seluruh proses
            else
                SUCCESSFUL_UPLOADS=$((SUCCESSFUL_UPLOADS + 1))
            fi
        done

        # --- Cetak Ringkasan Unggahan Folder ---
        if [ $SUCCESSFUL_UPLOADS -gt 0 ]; then
            printf "$MSG_ALL_FILES_UPLOADED_SUCCESS\n" "$SOURCE_PATH"
            
            local MASTER_END_TIME=$(date +%s)
            local MASTER_DURATION=$((MASTER_END_TIME - MASTER_START_TIME))
            
            local AVG_SPEED_BPS=0
            if [ $MASTER_DURATION -gt 0 ]; then
                AVG_SPEED_BPS=$((TOTAL_UPLOAD_SIZE / MASTER_DURATION))
            fi
            
            local AVG_SPEED_HR=$(human_readable_size $AVG_SPEED_BPS)
            local TOTAL_SIZE_HR=$(human_readable_size $TOTAL_UPLOAD_SIZE)
            
            echo
            echo "================================================================="
            echo "$MSG_FOLDER_SUMMARY_TITLE"
            echo "================================================================="
            printf "$MSG_FOLDER_SUMMARY_TOTAL_SUCCESS\n" "$SUCCESSFUL_UPLOADS" "$TOTAL_FILES_COUNT"
            printf "$MSG_FOLDER_SUMMARY_TOTAL_SIZE\n" "$TOTAL_SIZE_HR"
            printf "$MSG_FOLDER_SUMMARY_TOTAL_DURATION\n" "$(($MASTER_DURATION / 60))" "$(($MASTER_DURATION % 60))"
            printf "$MSG_FOLDER_SUMMARY_AVG_SPEED\n" "$AVG_SPEED_HR"
            echo "================================================================="
        fi
    fi

    # Hapus file PID setelah SEMUA pekerjaan selesai
    rm -f "$PID_FILE"
}


# 4. Buat file config sementara dan jalankan fungsi master di background
INPUT_CONFIG_FILE=$(mktemp)

# Simpan semua variabel yang dibutuhkan ke file config
# Gunakan declare -p untuk menyimpan array dan variabel lain secara aman
declare -p FILE_PATHS UPLOAD_TYPE SOURCE_PATH >> "$INPUT_CONFIG_FILE"
declare -p API_KEY PERSISTENT_ID DESCRIPTION DIRECTORY_LABEL JSON_CATEGORIES IS_RESTRICTED >> "$INPUT_CONFIG_FILE"

echo
echo "$MSG_INFO_RECEIVED_STARTING_BACKGROUND"
echo "$MSG_MONITOR_FROM_MAIN_MENU"

# Hapus log lama SEBELUM memulai proses baru
rm -f "$LOG_FILE"
touch "$PID_FILE" # Buat file PID kosong untuk mencegah race condition

# Jalankan proses background, berikan path file config sebagai argumen
(
    start_background_process "$INPUT_CONFIG_FILE"
) > "$LOG_FILE" 2>&1 &

# 5. Simpan PID dari proses background
BG_PID=$!
echo $BG_PID > "$PID_FILE"

sleep 1
printf "$MSG_PROCESS_STARTED_PID\n" "$BG_PID"
