#!/bin/bash

# File status dan log
RUN_DIR="run"
PID_FILE="$RUN_DIR/upload.pid"
LOG_FILE="$RUN_DIR/upload.log"

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

    echo "================================================================"
    echo "MEMULAI PROSES UNGGAH DI LATAR BELAKANG"
    echo "================================================================"
    echo "Waktu Mulai      : $(date)"
    echo "File untuk diunggah: $file_path"
    echo "Ukuran File      : $(awk -v size="$file_size_bytes" 'BEGIN { if (size >= 1073741824) { printf "%.2f GB", size / 1073741824 } else if (size >= 1048576) { printf "%.2f MB", size / 1048576 } else if (size >= 1024) { printf "%.2f KB", size / 1024 } else { printf "%d B", size } }') "
    echo "URL Target       : $api_url"
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
        echo "Mencoba unggah (Percobaan $i dari $MAX_RETRIES)..."
        
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
            echo "✅ Unggahan berhasil pada percobaan ke-$i."
            
            local END_TIME=$(date +%s)
            local DURATION=$((END_TIME - START_TIME))

            echo "----------------------------------------------------------------"
            echo "Waktu Mulai Unggah : $(awk 'BEGIN { print strftime("%Y-%m-%d %H:%M:%S", '$START_TIME') }')"
            echo "Waktu Selesai Unggah: $(awk 'BEGIN { print strftime("%Y-%m-%d %H:%M:%S", '$END_TIME') }')"
            echo "Durasi Unggah      : $(($DURATION / 60)) menit $(($DURATION % 60)) detik"

            if [ "$DURATION" -gt 0 ] && [ "$file_size_bytes" -gt 0 ]; then
                local AVG_SPEED_BPS=$((file_size_bytes / DURATION))
                local AVG_SPEED_KBPS=$(awk -v speed="$AVG_SPEED_BPS" 'BEGIN { printf "%.2f", speed / 1024 }')
                local AVG_SPEED_MBPS=$(awk -v speed="$AVG_SPEED_BPS" 'BEGIN { printf "%.2f", speed / 1048576 }')

                if (( $(echo "$AVG_SPEED_MBPS > 1" | bc -l) )); then
                    echo "Kecepatan Rata-rata: ${AVG_SPEED_MBPS} MB/s"
                elif (( $(echo "$AVG_SPEED_KBPS > 1" | bc -l) )); then
                    echo "Kecepatan Rata-rata: ${AVG_SPEED_KBPS} KB/s"
                else
                    echo "Kecepatan Rata-rata: ${AVG_SPEED_BPS} B/s"
                fi
                echo "Catatan: Kecepatan min/max sulit diukur secara akurat dalam skrip shell."
            fi
            echo "----------------------------------------------------------------"
            break
        else
            echo
            echo "❌ Percobaan ke-$i gagal dengan kode keluar: $CURL_EXIT_CODE."
            if [ $i -lt $MAX_RETRIES ]; then
                echo "Menunggu $RETRY_DELAY_SECONDS detik sebelum mencoba lagi..."
                sleep $RETRY_DELAY_SECONDS
            else
                echo "Batas maksimum percobaan ($MAX_RETRIES) telah tercapai."
            fi
        fi
    done

    # Pesan "tunggu beberapa saat" setelah 100% upload
    if [ $CURL_EXIT_CODE -eq 0 ]; then
        sleep 2 # Tambahkan jeda singkat agar tidak tumpang tindih dengan output curl terakhir
        echo "================================================================================"
        echo " Transfer file selesai. Menunggu respons akhir dari server Dataverse..."
        echo " Ini mungkin memerlukan beberapa saat tergantung ukuran file dan beban server."
        echo "================================================================================"
    fi

    rm "$JSON_PAYLOAD_FILE"

    echo "================================================================"
    if [ $CURL_EXIT_CODE -eq 0 ]; then
        echo "✅ PROSES UNGGAH SELESAI: SUKSES"
        echo "Respons dari server disimpan di '$output_file'."
    else
        echo "❌ PROSES UNGGAH SELESAI: GAGAL"
        echo "Terjadi kesalahan permanen. Periksa log di atas untuk detail."
    fi
    echo "================================================================"

    # Hapus file PID setelah selesai
    rm -f "$PID_FILE"
}


# --- Logika Utama Skrip ---

# 1. Cek apakah proses lain sedang berjalan
if [ -f "$PID_FILE" ]; then
    echo "❌ Error: Proses unggah lain sudah berjalan."
    echo "Silakan pantau atau hentikan proses tersebut dari menu utama."
    exit 1
fi

# 2. Hapus log lama dan siapkan file PID
rm -f "$LOG_FILE"
touch "$PID_FILE" # Buat file PID kosong sementara untuk mencegah race condition

# 3. Kumpulkan informasi dari pengguna (sama seperti skrip asli)
clear
echo "--- Memulai Proses Upload Baru ---"
echo "Silakan masukkan detail unggahan. Proses akan berjalan di latar belakang."
echo
echo "================================================================================"
echo " PENTING: Informasi rahasia seperti API Key tidak akan disimpan di disk."
echo "          Ini demi keamanan dan kenyamanan Anda. Setiap sesi memerlukan input."
echo "================================================================================"
echo

read -p "Masukkan API Key Anda: " API_KEY
[ -z "$API_KEY" ] && { echo "API Key tidak boleh kosong." >&2; rm "$PID_FILE"; exit 1; }

read -p "Masukkan Persistent ID dataset: " PERSISTENT_ID
[ -z "$PERSISTENT_ID" ] && { echo "Persistent ID tidak boleh kosong." >&2; rm "$PID_FILE"; exit 1; }

read -p "Masukkan path lengkap ke file: " FILE_PATH
while [ ! -f "$FILE_PATH" ]; do
    echo "File tidak ditemukan di '$FILE_PATH'." >&2
    read -p "Masukkan path lengkap ke file: " FILE_PATH
done

MAX_SIZE_BYTES=75161927680 # 70 GB
FILE_SIZE_BYTES=$(stat -c%s "$FILE_PATH")
if [ "$FILE_SIZE_BYTES" -gt "$MAX_SIZE_BYTES" ]; then
    FILE_SIZE_GB=$(awk -v size="$FILE_SIZE_BYTES" 'BEGIN { printf "%.2f", size / (1024*1024*1024) }')
    echo "KESALAHAN: Ukuran file (${FILE_SIZE_GB} GB) melebihi batas (70 GB)." >&2
    rm "$PID_FILE"; exit 1;
fi

read -p "Deskripsi file [Upload file besar]: " DESCRIPTION
DESCRIPTION=${DESCRIPTION:-"Upload file besar"}

read -p "Label direktori [data/subdir1]: " DIRECTORY_LABEL
DIRECTORY_LABEL=${DIRECTORY_LABEL:-"data/subdir1"}

read -p "Kategori (pisahkan koma) [Data]: " CATEGORIES_INPUT
CATEGORIES_INPUT=${CATEGORIES_INPUT:-"Data"}

JSON_CATEGORIES=""
OLD_IFS=$IFS; IFS=','
set -f
for category in $CATEGORIES_INPUT; do
    category_trimmed=$(echo "$category" | xargs)
    [ -n "$JSON_CATEGORIES" ] && JSON_CATEGORIES="$JSON_CATEGORIES,"
    JSON_CATEGORIES="$JSON_CATEGORIES\"$category_trimmed\""
done
IFS=$OLD_IFS; set +f

read -p "Batasi file (restrict)? (y/n) [n]: " RESTRICT_CHOICE
IS_RESTRICTED="false"
if [[ "$RESTRICT_CHOICE" == "y" || "$RESTRICT_CHOICE" == "Y" ]]; then
    IS_RESTRICTED="true"
fi

read -p "Nama file output [result.json]: " OUTPUT_FILE
OUTPUT_FILE=${OUTPUT_FILE:-"result.json"}

# 4. Jalankan fungsi upload di background
echo
echo "Informasi diterima. Memulai proses unggah di latar belakang..."
echo "Anda dapat memantaunya dari menu utama."

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
echo "Proses dimulai dengan PID: $BG_PID."
