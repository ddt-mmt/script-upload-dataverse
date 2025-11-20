#!/bin/bash

# ==============================================================================
# File Bahasa Indonesia (id.sh)
# Berisi semua pesan yang ditampilkan kepada pengguna dalam Bahasa Indonesia.
# ==============================================================================

# --- upload_dataverse.sh (Main Menu) ---
MSG_SCRIPT_DIR_NOT_FOUND="Direktori 'scripts' tidak ditemukan. Pastikan semua file skrip ada di sana."
MSG_STATUS_UPLOAD_RUNNING="STATUS: Proses upload sedang berjalan (PID: %s)."
MSG_CHOOSE_OPTION="Pilih salah satu opsi:"
MSG_MENU_MONITOR_UPLOAD="1. Pantau Proses Upload"
MSG_MENU_STOP_UPLOAD="2. Hentikan Proses Upload"
MSG_MENU_VIEW_FULL_LOG="3. Lihat Log Keseluruhan"
MSG_MENU_EXIT="4. Keluar"
MSG_STATUS_STALE_PID="STATUS: Ditemukan file proses (PID) usang. Mungkin proses sebelumnya tidak berhenti dengan benar."
MSG_STATUS_CHECK_LOG_BEFORE_NEW="STATUS: Sebaiknya lihat log sebelum memulai unggahan baru."
MSG_MENU_START_NEW_UPLOAD_STALE="s. Mulai Proses Upload Baru"
MSG_MENU_VIEW_LAST_LOG_STALE="l. Lihat Log Terakhir"
MSG_MENU_CLEAN_STALE_STATUS="c. Bersihkan Status Proses Usang"
MSG_MENU_EXIT_STALE="q. Keluar"
MSG_STATUS_NO_ACTIVE_UPLOAD="STATUS: Tidak ada proses upload yang aktif."
MSG_MENU_START_NEW_UPLOAD="1. Mulai Proses Upload Baru"
MSG_MENU_VIEW_LAST_LOG="2. Lihat Log Terakhir"
MSG_MENU_EXIT_NO_PROCESS="3. Keluar"
MSG_PROMPT_ENTER_CHOICE_RUNNING="Masukkan pilihan Anda [1-4]: "
MSG_INVALID_CHOICE="Pilihan tidak valid."
MSG_PROMPT_ENTER_CHOICE_STALE="Masukkan pilihan Anda [s, l, c, q]: "
MSG_STALE_STATUS_CLEANED="Status proses usang telah dibersihkan."
MSG_LOG_FILE_NOT_EXIST="File log belum ada."
MSG_PROMPT_ENTER_CHOICE_NO_PROCESS="Masukkan pilihan Anda [1-3]: "
MSG_PROMPT_PRESS_ENTER_TO_CONTINUE="Tekan [Enter] untuk kembali ke menu..."
MSG_EXITING_APP="Keluar dari aplikasi."
MSG_CHOOSE_LANGUAGE="Pilih Bahasa / Choose Language:"
MSG_LANG_INDONESIAN="1. Bahasa Indonesia"
MSG_LANG_ENGLISH="2. English"
MSG_PROMPT_LANG_CHOICE="Masukkan pilihan Anda [1-2]: "
MSG_SAVING_LANG_PREF="Menyimpan preferensi bahasa..."


# --- scripts/start_upload.sh ---
MSG_STARTING_UPLOAD_BACKGROUND_TITLE="MEMULAI PROSES UNGGAH DI LATAR BELAKANG"
MSG_TIME_START="Waktu Mulai      : "
MSG_FILE_TO_UPLOAD="File untuk diunggah: "
MSG_FILE_SIZE="Ukuran File      : "
MSG_URL_TARGET="URL Target       : "
MSG_TRYING_UPLOAD="Mencoba unggah (Percobaan %s dari %s)..."
MSG_UPLOAD_SUCCESS_ATTEMPT="✅ Unggahan berhasil pada percobaan ke-%s."
MSG_UPLOAD_START_TIME="Waktu Mulai Unggah : "
MSG_UPLOAD_END_TIME="Waktu Selesai Unggah: "
MSG_UPLOAD_DURATION="Durasi Unggah      : "
MSG_AVG_SPEED="Kecepatan Rata-rata: "
MSG_SPEED_NOTE="Catatan: Kecepatan min/max sulit diukur secara akurat dalam skrip shell."
MSG_UPLOAD_FAILED_ATTEMPT="❌ Percobaan ke-%s gagal dengan kode keluar: %s."
MSG_WAITING_RETRY="Menunggu %s detik sebelum mencoba lagi..."
MSG_MAX_RETRIES_REACHED="Batas maksimum percobaan (%s) telah tercapai."
MSG_TRANSFER_COMPLETE_WAITING_SERVER_RESPONSE="Transfer file selesai. Menunggu respons akhir dari server Dataverse..."
MSG_SERVER_RESPONSE_DELAY_NOTE="Ini mungkin memerlukan beberapa saat tergantung ukuran file dan beban server."
MSG_UPLOAD_COMPLETE_SUCCESS="✅ PROSES UNGGAH SELESAI: SUKSES"
MSG_SERVER_RESPONSE_SAVED="Respons dari server disimpan di '%s'."
MSG_UPLOAD_COMPLETE_FAILED="❌ PROSES UNGGAH SELESAI: GAGAL"
MSG_PERMANENT_ERROR_CHECK_LOG="Terjadi kesalahan permanen. Periksa log di atas untuk detail."
MSG_ERROR_ANOTHER_UPLOAD_RUNNING="❌ Error: Proses unggah lain sudah berjalan."
MSG_MONITOR_OR_STOP_FROM_MENU="Silakan pantau atau hentikan proses tersebut dari menu utama."
MSG_START_NEW_UPLOAD_PROMPT_TITLE="--- Memulai Proses Upload Baru ---"
MSG_ENTER_UPLOAD_DETAILS_BACKGROUND="Silakan masukkan detail unggahan. Proses akan berjalan di latar belakang."
MSG_IMPORTANT_SECURITY_NOTE_1="PENTING: Informasi rahasia seperti API Key tidak akan disimpan di disk."
MSG_IMPORTANT_SECURITY_NOTE_2="Ini demi keamanan dan kenyamanan Anda. Setiap sesi memerlukan input."
MSG_PROMPT_API_KEY="Masukkan API Key Anda: "
MSG_API_KEY_EMPTY="API Key tidak boleh kosong."
MSG_PROMPT_PERSISTENT_ID="Masukkan Persistent ID dataset: "
MSG_PERSISTENT_ID_EMPTY="Persistent ID tidak boleh kosong."
MSG_PROMPT_FILE_PATH="Masukkan path lengkap ke file: "
MSG_FILE_NOT_FOUND="File tidak ditemukan di '%s'."
MSG_ERROR_FILE_SIZE_EXCEEDS="KESALAHAN: Ukuran file (%s GB) melebihi batas (70 GB)."
MSG_PROMPT_DESCRIPTION="Deskripsi file [Upload file besar]: "
MSG_DEFAULT_DESCRIPTION="Upload file besar"
MSG_PROMPT_DIRECTORY_LABEL="Label direktori [data/subdir1]: "
MSG_DEFAULT_DIRECTORY_LABEL="data/subdir1"
MSG_PROMPT_CATEGORIES="Kategori (pisahkan koma) [Data]: "
MSG_DEFAULT_CATEGORIES="Data"
MSG_PROMPT_RESTRICT="Batasi file (restrict)? (y/n) [n]: "
MSG_PROMPT_OUTPUT_FILE="Nama file output [result.json]: "
MSG_DEFAULT_OUTPUT_FILE="result.json"
MSG_INFO_RECEIVED_STARTING_BACKGROUND="Informasi diterima. Memulai proses unggah di latar belakang..."
MSG_MONITOR_FROM_MAIN_MENU="Anda dapat memantaunya dari menu utama."
MSG_PROCESS_STARTED_PID="Proses dimulai dengan PID: %s."

# --- scripts/monitor_upload.sh ---
MSG_MONITOR_UPLOAD_TITLE="--- Memantau Proses Upload ---"
MSG_NO_UPLOAD_RUNNING="Tidak ada proses upload yang sedang berjalan."
MSG_PROCESS_NOT_RUNNING="Proses upload (PID: %s) tidak lagi berjalan."
MSG_PROCESS_FINISHED_OR_FAILED="Kemungkinan sudah selesai atau gagal. Periksa log untuk detail."
MSG_PROCESS_RUNNING="Proses upload sedang berjalan (PID: %s)."
MSG_MONITORING_LOG_REALTIME="Menampilkan log secara real-time. Tekan [Ctrl+C] untuk berhenti memantau."

# --- scripts/stop_upload.sh ---
MSG_STOP_UPLOAD_TITLE="--- Menghentikan Proses Upload ---"
MSG_NO_UPLOAD_TO_STOP="Tidak ada proses upload yang bisa dihentikan."
MSG_PROCESS_ALREADY_STOPPED="Proses (PID: %s) sudah tidak berjalan."
MSG_CLEANING_STALE_STATUS="Membersihkan file status usang..."
MSG_SENDING_STOP_SIGNAL="Mengirim sinyal berhenti ke proses upload dengan PID: %s..."
MSG_PROCESS_NOT_STOPPED_NORMALLY="Proses tidak berhenti dengan normal. Mencoba menghentikan secara paksa (kill -9)..."
MSG_UPLOAD_STOPPED="Proses upload telah dihentikan."
MSG_STATUS_FILE_CLEANED="File status telah dibersihkan."

# New messages for language selection
MSG_MENU_CHANGE_LANGUAGE="5. Ganti Bahasa" # For running process menu
MSG_MENU_CHANGE_LANGUAGE_STALE="L. Ganti Bahasa" # For stale PID menu
MSG_MENU_CHANGE_LANGUAGE_NO_PROCESS="4. Ganti Bahasa" # For no process menu

# Updated prompts to reflect new options
MSG_PROMPT_ENTER_CHOICE_RUNNING="Masukkan pilihan Anda [1-5]: " # Updated from [1-4]
MSG_PROMPT_ENTER_CHOICE_STALE="Masukkan pilihan Anda [s, l, c, L, q]: " # Updated from [s, l, c, q]
MSG_PROMPT_ENTER_CHOICE_NO_PROCESS="Masukkan pilihan Anda [1-4]: " # Updated from [1-3]

# New message for progress bar note
MSG_PROGRESS_BAR_NOTE="Catatan: Tampilan progress bar mungkin terlihat mentah/berantakan di log."
