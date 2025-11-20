#!/bin/bash
# =================================================================
# Skrip Interaktif untuk Mengunggah File ke Dataverse (v5 - Final)
# =================================================================
# Menghapus semua dependensi pada 'sed' untuk kompatibilitas maksimum.



show_banner() {
    echo "+----------------------------------------------------------------------+"
    echo "|                                                                      |"
    echo "|              Uploader Skrip untuk Dataverse (v5 - Final)             |"
    echo "|                                                                      |"
    echo "+----------------------------------------------------------------------+"
}

show_banner

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

# File Path
read -p "Masukkan path lengkap ke file yang akan diunggah (cth: /path/to/bigfile.iso): " FILE_PATH
while [ ! -f "$FILE_PATH" ]; do
    echo "File tidak ditemukan di '$FILE_PATH'. Silakan coba lagi." >&2
    read -p "Masukkan path lengkap ke file: " FILE_PATH
done

# --- Pengecekan Ukuran File ---
MAX_SIZE_BYTES=75161927680 # 70 GB dalam byte
FILE_SIZE_BYTES=$(stat -c%s "$FILE_PATH")

if [ "$FILE_SIZE_BYTES" -gt "$MAX_SIZE_BYTES" ]; then
    # Konversi byte ke GB untuk pesan error yang lebih mudah dibaca
    FILE_SIZE_GB=$(awk -v size="$FILE_SIZE_BYTES" 'BEGIN { printf "%.2f", size / (1024*1024*1024) }')
    
    echo
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo " KESALAHAN: Ukuran file Anda (${FILE_SIZE_GB} GB) melebihi batas maksimum (70 GB)." >&2
    echo " Unggahan dibatalkan." >&2
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo
    exit 1
fi
# --- Akhir Pengecekan Ukuran File ---

# Deskripsi File
read -p "Masukkan deskripsi singkat untuk file ini (default: Upload file besar): " DESCRIPTION
DESCRIPTION=${DESCRIPTION:-"Upload file besar"}

# Direktori Tujuan
read -p "Masukkan label direktori di dalam dataset (default: data/subdir1): " DIRECTORY_LABEL
DIRECTORY_LABEL=${DIRECTORY_LABEL:-"data/subdir1"}

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


# --- 2. Buat JSON Payload dan URL ---

JSON_CONTENT=$(printf '{"description":"%s","directoryLabel":"%s","categories":[%s],"restrict":%s,"tabIngest":false}' \
    "$DESCRIPTION" \
    "$DIRECTORY_LABEL" \
    "$JSON_CATEGORIES" \
    "$IS_RESTRICTED")

JSON_FORM_DATA="jsonData=$JSON_CONTENT"
API_URL="https://cibinong-data.brin.go.id/api/datasets/:persistentId/add?persistentId=$PERSISTENT_ID"


# --- 3. Tampilkan Ringkasan dan Minta Konfirmasi ---

echo
echo "================================================================"
echo "RINGKASAN PERINTAH"
echo "================================================================"
echo "URL Target       : $API_URL"
echo "File untuk diunggah: $FILE_PATH"
echo "Output disimpan di : $OUTPUT_FILE"
echo "API Key          : ${API_KEY:0:4}****************"
echo "Data Form        : jsonData=$JSON_CONTENT"
echo "----------------------------------------------------------------"
echo "Perintah curl yang akan dieksekusi:"
echo
echo "curl --progress-bar \\"
echo "  -o \"$OUTPUT_FILE\" \\"
echo "  -H \"X-Dataverse-key: $API_KEY\" \\"
echo "  -X POST \\"
echo "  -F \"file=@$FILE_PATH\" \\"
echo "  -F 'jsonData=... (konten disiapkan)' \\"
echo "  \"$API_URL\""
echo "================================================================"
echo 

read -p "Apakah Anda ingin melanjutkan? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Operasi dibatalkan oleh pengguna."
    exit 0
fi

# --- 4. Eksekusi Perintah ---

# Konfigurasi Coba Ulang
MAX_RETRIES=5
RETRY_DELAY_SECONDS=30

echo
echo "Memulai proses unggah dengan maksimal $MAX_RETRIES percobaan jika gagal..."

# Buat file sementara untuk JSON payload
JSON_PAYLOAD_FILE=$(mktemp)
echo "$JSON_CONTENT" > "$JSON_PAYLOAD_FILE"

CURL_EXIT_CODE=1 # Inisialisasi dengan kode kegagalan

for (( i=1; i<=MAX_RETRIES; i++ )); do
    echo
    echo "Mencoba unggah (Percobaan $i dari $MAX_RETRIES)..."
    
    # Lakukan curl dengan payload dari file
    curl --progress-bar --tlsv1.2 \
      -o "$OUTPUT_FILE" \
      -H "X-Dataverse-key: $API_KEY" \
      -X POST \
      -F "file=@$FILE_PATH" \
      -F "jsonData=@$JSON_PAYLOAD_FILE" \
      "$API_URL"

    CURL_EXIT_CODE=$?

    if [ $CURL_EXIT_CODE -eq 0 ]; then
        echo
        echo "✅ Unggahan berhasil pada percobaan ke-$i."
        break # Keluar dari loop jika berhasil
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

# Hapus file sementara
rm "$JSON_PAYLOAD_FILE"

# Cek hasil eksekusi final
if [ $CURL_EXIT_CODE -eq 0 ]; then
    echo
    echo "✅ Proses unggah selesai. Respons dari server disimpan di '$OUTPUT_FILE'."
    echo "Silakan periksa file tersebut untuk detailnya."
else
    echo
    echo "❌ Terjadi kesalahan permanen setelah beberapa kali percobaan. Periksa output di atas." >&2
fi

exit $CURL_EXIT_CODE
