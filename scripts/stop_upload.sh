#!/bin/bash

RUN_DIR="run"
PID_FILE="$RUN_DIR/upload.pid"

echo "--- Menghentikan Proses Upload ---"

# Cek apakah file PID ada
if [ ! -f "$PID_FILE" ]; then
    echo "Tidak ada proses upload yang bisa dihentikan."
    exit 0
fi

PID=$(cat "$PID_FILE")

# Cek apakah proses dengan PID tersebut benar-benar berjalan
if ! ps -p "$PID" > /dev/null; then
    echo "Proses (PID: $PID) sudah tidak berjalan."
    echo "Membersihkan file status usang..."
    rm -f "$PID_FILE"
    exit 0
fi

echo "Mengirim sinyal berhenti ke proses upload dengan PID: $PID..."

# Kirim sinyal terminasi. Ini akan menghentikan sub-shell dan juga proses curl di dalamnya.
kill "$PID"

# Tunggu sejenak untuk memastikan proses berhenti
sleep 2

if ps -p "$PID" > /dev/null; then
    echo "Proses tidak berhenti dengan normal. Mencoba menghentikan secara paksa (kill -9)..."
    kill -9 "$PID"
    sleep 1
fi

echo "Proses upload telah dihentikan."

# Hapus file PID
rm -f "$PID_FILE"

echo "File status telah dibersihkan."
