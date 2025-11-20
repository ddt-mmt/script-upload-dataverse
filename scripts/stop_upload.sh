#!/bin/bash

# Mengambil variabel global dari skrip utama
RUN_DIR="run"
PID_FILE="$RUN_DIR/upload.pid"
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


echo "$MSG_STOP_UPLOAD_TITLE"

# Cek apakah file PID ada
if [ ! -f "$PID_FILE" ]; then
    echo "$MSG_NO_UPLOAD_TO_STOP"
    exit 0
fi

PID=$(cat "$PID_FILE")

# Cek apakah proses dengan PID tersebut benar-benar berjalan
if ! ps -p "$PID" > /dev/null; then
    printf "$MSG_PROCESS_ALREADY_STOPPED\n" "$PID"
    echo "$MSG_CLEANING_STALE_STATUS"
    rm -f "$PID_FILE"
    exit 0
fi

printf "$MSG_SENDING_STOP_SIGNAL\n" "$PID"

# Kirim sinyal terminasi. Ini akan menghentikan sub-shell dan juga proses curl di dalamnya.
kill "$PID"

# Tunggu sejenak untuk memastikan proses berhenti
sleep 2

if ps -p "$PID" > /dev/null; then
    echo "$MSG_PROCESS_NOT_STOPPED_NORMALLY"
    kill -9 "$PID"
    sleep 1
fi

echo "$MSG_UPLOAD_STOPPED"

# Hapus file PID
rm -f "$PID_FILE"

echo "$MSG_STATUS_FILE_CLEANED"