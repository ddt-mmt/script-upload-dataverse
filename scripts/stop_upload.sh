#!/bin/bash

# --- Inisialisasi Berbasis Job ---
if [ -z "$1" ]; then
    echo "FATAL: Job ID tidak diberikan." >&2
    exit 1
fi
JOB_ID="$1"
JOB_DIR="run/jobs/$JOB_ID"
PID_FILE="$JOB_DIR/upload.pid"
STATUS_FILE="$JOB_DIR/status"

# --- Muat Bahasa ---
LANG_DIR="lang"
GLOBAL_CONFIG_FILE="run/config.sh"
if [ -f "$GLOBAL_CONFIG_FILE" ]; then
    source "$GLOBAL_CONFIG_FILE"
fi
if [ -f "$LANG_DIR/${LANG_CODE:-id}.sh" ]; then
    source "$LANG_DIR/${LANG_CODE:-id}.sh"
else
    source "$LANG_DIR/id.sh"
fi

# --- Logika Utama Stop ---
clear
echo "$MSG_STOP_UPLOAD_TITLE"
echo "========================================"
printf "Job ID: %s\n" "$JOB_ID"
echo "========================================"
echo

if [ ! -f "$PID_FILE" ]; then
    echo "$MSG_NO_UPLOAD_TO_STOP"
    rm -f "$PID_FILE" # Bersihkan jika ada file kosong
    exit 0
fi

pid=$(cat "$PID_FILE")

if [ -z "$pid" ] || ! ps -p "$pid" > /dev/null; then
    printf "$MSG_PROCESS_ALREADY_STOPPED\n" "$pid"
    echo "$MSG_CLEANING_STALE_STATUS"
    rm -f "$PID_FILE"
    exit 0
fi

# Kirim sinyal berhenti
printf "$MSG_SENDING_STOP_SIGNAL\n" "$pid"
kill -15 "$pid"
sleep 3

# Cek apakah proses masih ada, jika ya, paksa berhenti
if ps -p "$pid" > /dev/null; then
    echo "$MSG_PROCESS_NOT_STOPPED_NORMALLY"
    kill -9 "$pid"
    sleep 1
fi

echo "$MSG_UPLOAD_STOPPED"
rm -f "$PID_FILE"
echo "STOPPED" > "$STATUS_FILE" # Tandai status job sebagai dihentikan
echo "$MSG_STATUS_FILE_CLEANED"
