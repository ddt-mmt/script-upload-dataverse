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


# --- 1. Kumpulkan Informasi dari Pengguna ---

echo "Selamat datang! Silakan masukkan detail unggahan file Anda."
echo "Beberapa isian memiliki nilai default jika Anda membiarkannya kosong."
echo 

# API Key
read -p "Masukkan API Key Anda: " API_KEY
if [ -z "$API_KEY" ]; then
    echo "API Key tidak boleh kosong." >&2
    exit 1
fi

# Persistent ID
read -p "Masukkan Persistent ID dataset (cth: hdl:20.500.12690/RIN/XBCFVF): " PERSISTENT_ID
if [ -z "$PERSISTENT_ID" ]; then
    echo "Persistent ID tidak boleh kosong." >&2
    exit 1
fi

# Tipe Unggahan (File atau Folder)
read -p "Pilih tipe unggahan: 1 untuk File, 2 untuk Folder (default: 1): " UPLOAD_TYPE
UPLOAD_TYPE=${UPLOAD_TYPE:-"1"}

# --- Pengecekan Ukuran File ---
MAX_SIZE_BYTES=75161927680 # 70 GB dalam byte

# Inisialisasi array untuk menyimpan path file yang akan diunggah
declare -a FILE_PATHS

if [ "$UPLOAD_TYPE" = "1" ]; then
    # --- Unggahan File Tunggal ---
    read -p "Masukkan path lengkap ke file yang akan diunggah (cth: /path/to/bigfile.iso): " FILE_PATH
    while [ ! -f "$FILE_PATH" ]; do
        echo "File tidak ditemukan di '$FILE_PATH'. Silakan coba lagi." >&2
        read -p "Masukkan path lengkap ke file: " FILE_PATH
    done
    FILE_PATHS+=("$FILE_PATH")

    FILE_SIZE_BYTES=$(stat -c%s "$FILE_PATH")
    if [ "$FILE_SIZE_BYTES" -gt "$MAX_SIZE_BYTES" ]; then
        FILE_SIZE_GB=$(awk -v size="$FILE_SIZE_BYTES" 'BEGIN { printf "%.2f", size / (1024*1024*1024) }')
        echo
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo " KESALAHAN: Ukuran file Anda (${FILE_SIZE_GB} GB) melebihi batas maksimum (70 GB)." >&2
        echo " Unggahan dibatalkan." >&2
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo
        exit 1
    fi
else
    # --- Unggahan Folder ---
    read -p "Masukkan path lengkap ke folder yang akan diunggah: " FOLDER_PATH
    while [ ! -d "$FOLDER_PATH" ]; do
        echo "Folder tidak ditemukan di '$FOLDER_PATH'. Silakan coba lagi." >&2
        read -p "Masukkan path lengkap ke folder: " FOLDER_PATH
    done

    # Temukan semua file dalam folder dan subfolder
    while IFS= read -r -d $'\0' file; do
        FILE_PATHS+=("$file")
    done < <(find "$FOLDER_PATH" -type f -print0)

    if [ ${#FILE_PATHS[@]} -eq 0 ]; then
        echo "Tidak ada file yang ditemukan di dalam folder '$FOLDER_PATH'."
        exit 0
    fi

    # Cek ukuran total folder
    TOTAL_SIZE_BYTES=0
    for file in "${FILE_PATHS[@]}"; do
        FILE_SIZE_BYTES=$(stat -c%s "$file")
        TOTAL_SIZE_BYTES=$((TOTAL_SIZE_BYTES + FILE_SIZE_BYTES))
    done

    if [ "$TOTAL_SIZE_BYTES" -gt "$MAX_SIZE_BYTES" ]; then
        TOTAL_SIZE_GB=$(awk -v size="$TOTAL_SIZE_BYTES" 'BEGIN { printf "%.2f", size / (1024*1024*1024) }')
        echo
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo " KESALAHAN: Ukuran total folder Anda (${TOTAL_SIZE_GB} GB) melebihi batas maksimum (70 GB)." >&2
        echo " Unggahan dibatalkan." >&2
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo
        exit 1
    fi
fi
# --- Akhir Pengecekan Ukuran File ---

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


# Direktori Tujuan (hanya untuk unggahan file tunggal)
DIRECTORY_LABEL="data/subdir1"
if [ "$UPLOAD_TYPE" = "1" ]; then
    read -p "Masukkan label direktori di dalam dataset (default: data/subdir1): " DIR_INPUT
    DIRECTORY_LABEL=${DIR_INPUT:-"data/subdir1"}
fi


# Kategori
read -p "Masukkan kategori (pisahkan dengan koma jika lebih dari satu) (default: Data): " CATEGORIES_INPUT
CATEGORIES_INPUT=${CATEGORIES_INPUT:-"Data"}

# --- Logika bash murni untuk menggantikan 'sed' ---
JSON_CATEGORIES=""
OLD_IFS=$IFS
IFS=','
# Nonaktifkan globbing sementara agar tidak ada karakter seperti '*' yang diekspansi
set -f
for category in $CATEGORIES_INPUT; do
    # Menghapus spasi di awal dan akhir dari setiap kategori
    category_trimmed=$(echo "$category" | xargs)

    # Jika JSON_CATEGORIES sudah ada isinya, tambahkan koma
    if [ -n "$JSON_CATEGORIES" ]; then
        JSON_CATEGORIES="$JSON_CATEGORIES,"
    fi
    # Tambahkan kategori yang sudah bersih dan diapit kutip
    JSON_CATEGORIES="$JSON_CATEGORIES\"$category_trimmed\""
done
# Kembalikan IFS dan globbing ke kondisi semula
IFS=$OLD_IFS
set +f
# --- Akhir Perbaikan ---

# Opsi restrict
read -p "Batasi file ini (restrict)? (y/n) [default: n]: " RESTRICT_CHOICE
IS_RESTRICTED="false"
if [[ "$RESTRICT_CHOICE" == "y" || "$RESTRICT_CHOICE" == "Y" ]]; then
    IS_RESTRICTED="true"
fi

# Nama file output
read -p "Nama file untuk menyimpan hasil (output) (default: result.json): " OUTPUT_FILE
OUTPUT_FILE=${OUTPUT_FILE:-"result.json"}


# --- 2. Buat URL ---

API_URL="https://cibinong-data.brin.go.id/api/datasets/:persistentId/add?persistentId=$PERSISTENT_ID"


# --- 4. Fungsi untuk Mengunggah File ---
upload_file() {
    local file_path="$1"
    local dir_label="$2"
    local output_file="$3"
    
    # Buat JSON payload dinamis untuk setiap file
    local json_content=$(printf '{"description":"%s","directoryLabel":"%s","categories":[%s],"restrict":%s,"tabIngest":false}' \
        "$DESCRIPTION" \
        "$dir_label" \
        "$JSON_CATEGORIES" \
        "$IS_RESTRICTED")
    
    local json_payload_file=$(mktemp)
    echo "$json_content" > "$json_payload_file"

    echo
    echo "================================================================"
    echo "Mengunggah file: $file_path"
    echo "Target direktori  : $dir_label"
    echo "================================================================"

    local max_retries=5
    local retry_delay=30
    local curl_exit_code=1

    for (( i=1; i<=max_retries; i++ )); do
        echo "Mencoba unggah (Percobaan $i dari $max_retries)..."
        
        curl --progress-bar --tlsv1.2 \
          -o "$output_file" \
          -H "X-Dataverse-key: $API_KEY" \
          -X POST \
          -F "file=@$file_path" \
          -F "jsonData=@$json_payload_file" \
          "$API_URL"
        
        curl_exit_code=$?

        if [ $curl_exit_code -eq 0 ]; then
            echo "✅ Unggahan file '$file_path' berhasil."
            break
        else
            echo "❌ Percobaan unggah '$file_path' gagal (kode: $curl_exit_code)."
            if [ $i -lt $max_retries ]; then
                echo "Menunggu $retry_delay detik sebelum mencoba lagi..."
                sleep $retry_delay
            else
                echo "Batas percobaan untuk '$file_path' tercapai."
            fi
        fi
    done

    rm "$json_payload_file"
    return $curl_exit_code
}


# --- 5. Eksekusi Proses Unggah ---

# Konfirmasi sebelum memulai
echo
echo "================================================================"
echo "RINGKASAN PROSES"
echo "================================================================"
if [ "$UPLOAD_TYPE" = "1" ]; then
    echo "Akan mengunggah 1 file."
    echo "File: ${FILE_PATHS[0]}"
else
    echo "Akan mengunggah ${#FILE_PATHS[@]} file dari folder '$FOLDER_PATH'."
fi
echo "API Key          : ${API_KEY:0:4}****************"
echo "Persistent ID    : $PERSISTENT_ID"
echo "Deskripsi        : $DESCRIPTION"
echo "Kategori         : $CATEGORIES_INPUT"
echo "Restrict         : $IS_RESTRICTED"
echo "================================================================"
echo

read -p "Apakah Anda ingin melanjutkan? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Operasi dibatalkan oleh pengguna."
    exit 0
fi

# Proses unggah
if [ "$UPLOAD_TYPE" = "1" ]; then
    # Unggah file tunggal
    upload_file "${FILE_PATHS[0]}" "$DIRECTORY_LABEL" "$OUTPUT_FILE"
    exit $?
else
    # Unggah folder
    base_folder_name=$(basename "$FOLDER_PATH")
    for file in "${FILE_PATHS[@]}"; do
        # Mendapatkan path relatif dari file terhadap folder input
        relative_path=${file#$FOLDER_PATH/}
        # Membuat label direktori baru yang mencerminkan struktur folder
        new_dir_label="$base_folder_name/${relative_path%/*}"
        # Menghapus trailing slash jika ada
        new_dir_label=${new_dir_label%/}

        # Tentukan nama file output unik untuk setiap file
        file_basename=$(basename "$file")
        unique_output_file="result_${file_basename%.*}_$(date +%s).json"
        
        upload_file "$file" "$new_dir_label" "$unique_output_file"
        
        if [ $? -ne 0 ]; then
            echo "❌ Gagal mengunggah file '$file'. Proses akan dihentikan." >&2
            exit 1
        fi
    done
    echo "✅ Semua file dari folder '$FOLDER_PATH' berhasil diunggah."
fi

exit 0


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

