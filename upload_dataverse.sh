#!/bin/bash

# Direktori kerja dan file status
RUN_DIR="run"
PID_FILE="$RUN_DIR/upload.pid"
LOG_FILE="$RUN_DIR/upload.log"

# Pastikan direktori skrip ada
SCRIPT_DIR="scripts"
if [ ! -d "$SCRIPT_DIR" ]; then
    echo "Direktori 'scripts' tidak ditemukan. Pastikan semua file skrip ada di sana."
    exit 1
fi

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
            echo "STATUS: Proses upload sedang berjalan (PID: $PID)."
            echo
            echo "Pilih salah satu opsi:"
            echo "  1. Pantau Proses Upload"
            echo "  2. Hentikan Proses Upload"
            echo "  3. Lihat Log Keseluruhan"
            echo "  4. Keluar"
        else
            echo "STATUS: Ditemukan file proses (PID) usang. Mungkin proses sebelumnya tidak berhenti dengan benar."
            echo "STATUS: Sebaiknya lihat log sebelum memulai unggahan baru."
            echo
            echo "Pilih salah satu opsi:"
            echo "  s. Mulai Proses Upload Baru"
            echo "  l. Lihat Log Terakhir"
            echo "  c. Bersihkan Status Proses Usang"
            echo "  q. Keluar"
        fi
    else
        echo "STATUS: Tidak ada proses upload yang aktif."
        echo
        echo "Pilih salah satu opsi:"
        echo "  1. Mulai Proses Upload Baru"
        echo "  2. Lihat Log Terakhir"
        echo "  3. Keluar"
    fi
    echo "-------------------------------------------------"
}

# Loop menu utama
while true; do
    show_main_menu
    
    if [ -f "$PID_FILE" ] && ps -p "$(cat "$PID_FILE")" > /dev/null; then
        # Menu saat proses berjalan
        read -p "Masukkan pilihan Anda [1-4]: " choice
        case $choice in
            1) bash "$SCRIPT_DIR/monitor_upload.sh" ;;
            2) bash "$SCRIPT_DIR/stop_upload.sh" ;;
            3) less "$LOG_FILE" ;;
            4) echo "Keluar dari aplikasi."; exit 0 ;;
            *) echo "Pilihan tidak valid." ;;
        esac
    elif [ -f "$PID_FILE" ]; then
        # Menu saat ada PID file usang
        read -p "Masukkan pilihan Anda [s, l, c, q]: " choice
        case $choice in
            s) bash "$SCRIPT_DIR/start_upload.sh" ;;
            l) less "$LOG_FILE" ;;
            c) 
                rm -f "$PID_FILE"
                echo "Status proses usang telah dibersihkan."
                sleep 1
                ;;
            q) echo "Keluar dari aplikasi."; exit 0 ;;
            *) echo "Pilihan tidak valid." ;;
        esac
    else
        # Menu saat tidak ada proses
        read -p "Masukkan pilihan Anda [1-3]: " choice
        case $choice in
            1) bash "$SCRIPT_DIR/start_upload.sh" ;;
            2) 
                if [ -f "$LOG_FILE" ]; then
                    less "$LOG_FILE"
                else
                    echo "File log belum ada."
                    sleep 1
                fi
                ;;
            3) echo "Keluar dari aplikasi."; exit 0 ;;
            *) echo "Pilihan tidak valid." ;;
        esac
    fi
    echo
    read -p "Tekan [Enter] untuk kembali ke menu..."
done