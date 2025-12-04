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

# Deskripsi File
read -p "Masukkan deskripsi singkat untuk file ini (default: Upload file besar): " DESCRIPTION
DESCRIPTION=${DESCRIPTION:-"Upload file besar"}

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

