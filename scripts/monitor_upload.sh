#!/bin/bash

# --- Inisialisasi Berbasis Job ---
if [ -z "$1" ]; then
    echo "FATAL: Job ID tidak diberikan." >&2
    exit 1
fi
JOB_ID="$1"
JOB_DIR="run/jobs/$JOB_ID"
LOG_FILE="$JOB_DIR/upload.log"
PID_FILE="$JOB_DIR/upload.pid"

# --- Muat Bahasa (opsional, untuk pesan yang konsisten) ---
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

# --- Logika Utama Monitor ---
clear
echo "$MSG_MONITOR_UPLOAD_TITLE"
echo "========================================"
printf "Job ID: %s\n" "$JOB_ID"
echo "========================================"
echo

# Cek apakah file log ada
if [ ! -f "$LOG_FILE" ]; then
    echo "File log untuk job ini belum dibuat."
    sleep 2
    exit 1
fi

# Cek apakah proses masih berjalan
pid=
if [ -f "$PID_FILE" ]; then
    pid=$(cat "$PID_FILE")
fi

if [ -z "$pid" ] || ! ps -p "$pid" > /dev/null; then
    printf "$MSG_PROCESS_NOT_RUNNING\n" "$pid"
    echo "$MSG_PROCESS_FINISHED_OR_FAILED"
    echo "----------------------------------------"
    # Tampilkan 20 baris terakhir dari log jika proses sudah tidak ada
    tail -n 20 "$LOG_FILE"
else
    printf "$MSG_PROCESS_RUNNING\n" "$pid"
    echo "$MSG_MONITORING_LOG_REALTIME"
    echo "----------------------------------------"
    # Tampilkan log secara real-time
    tail -f "$LOG_FILE"
fi