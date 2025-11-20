#!/bin/bash

RUN_DIR="run"
PID_FILE="$RUN_DIR/upload.pid"
LOG_FILE="$RUN_DIR/upload.log"

echo "--- Memantau Proses Upload ---"

# Cek apakah file PID ada
if [ ! -f "$PID_FILE" ]; then
    echo "Tidak ada proses upload yang sedang berjalan."
    exit 0
fi

PID=$(cat "$PID_FILE")

# Cek apakah proses dengan PID tersebut benar-benar berjalan
if ! ps -p "$PID" > /dev/null; then
    echo "Proses upload (PID: $PID) tidak lagi berjalan."
    echo "Kemungkinan sudah selesai atau gagal. Periksa log untuk detail."
    exit 0
fi

echo "Proses upload sedang berjalan (PID: $PID)."
echo "Menampilkan log secara real-time. Tekan [Ctrl+C] untuk berhenti memantau."
echo "----------------------------------------------------------------------"
echo

# Tampilkan log secara real-time
# Opsi --follow=name --retry membuat tail lebih tangguh jika file log dirotasi/dihapus
tail -f --follow=name --retry "$LOG_FILE"
