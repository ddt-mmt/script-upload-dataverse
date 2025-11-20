# NETLOAD: Dataverse Upload & Monitoring Tool

```
#################################################
#                     NETLOAD                   #
#################################################
      Dataverse Upload & Monitoring Tool
-------------------------------------------------
```

Aplikasi berbasis CLI ini dirancang untuk memfasilitasi proses unggah file ke Dataverse dengan fitur pemantauan dan eksekusi di latar belakang. NETLOAD membantu Anda mengelola unggahan file besar dengan lebih efisien, memberikan informasi status, durasi, dan kecepatan unggah.

## Fitur Utama

*   **Unggah di Latar Belakang**: Jalankan proses unggah tanpa mengunci terminal Anda.
*   **Pemantauan Real-time**: Pantau log unggahan secara langsung untuk melihat progres.
*   **Informasi Detail Unggah**: Dapatkan durasi, waktu mulai/selesai, dan kecepatan rata-rata unggah setelah proses selesai.
*   **Penanganan Proses**: Opsi untuk menghentikan proses unggah yang sedang berjalan.
*   **Keamanan**: Informasi sensitif seperti API Key tidak disimpan di disk.

## Instalasi

1.  **Clone Repositori**:
    ```bash
    git clone https://github.com/your-username/your-repo-name.git
    cd your-repo-name
    ```
    *(Ganti `your-username/your-repo-name.git` dengan detail repositori Anda)*

2.  **Berikan Izin Eksekusi**:
    Pastikan skrip memiliki izin untuk dieksekusi:
    ```bash
    chmod +x upload_dataverse.sh scripts/*.sh
    ```

## Cara Menggunakan

Jalankan skrip utama dari terminal:

```bash
./upload_dataverse.sh
```

Anda akan disajikan dengan menu interaktif:

```
#################################################
#                     NETLOAD                   #
#################################################
      Dataverse Upload & Monitoring Tool
-------------------------------------------------
STATUS: Tidak ada proses upload yang aktif.

Pilih salah satu opsi:
  1. Mulai Proses Upload Baru
  2. Lihat Log Terakhir
  3. Keluar
-------------------------------------------------
```

### Opsi Menu

*   **1. Mulai Proses Upload Baru**:
    *   Akan meminta Anda untuk memasukkan detail unggahan seperti API Key, Persistent ID, path file, deskripsi, dll.
    *   Proses unggah akan dimulai di latar belakang.
    *   **PENTING**: Informasi rahasia seperti API Key tidak akan disimpan di disk.

*   **2. Pantau Proses Upload (muncul jika ada proses berjalan)**:
    *   Menampilkan log unggahan secara *real-time*. Tekan `Ctrl+C` untuk kembali ke menu utama.

*   **3. Hentikan Proses Upload (muncul jika ada proses berjalan)**:
    *   Mengirim sinyal untuk menghentikan proses unggah yang sedang berjalan di latar belakang.

*   **4. Lihat Log Keseluruhan**:
    *   Menampilkan seluruh isi file log `run/upload.log` menggunakan `less`.

*   **5. Keluar**:
    *   Keluar dari aplikasi.

## Struktur Proyek

```
.
├── .gitignore
├── README.md
├── upload_dataverse.sh         # Skrip menu utama
├── scripts/
│   ├── start_upload.sh         # Logika inti untuk memulai unggahan
│   ├── monitor_upload.sh       # Skrip untuk memantau log unggahan
│   └── stop_upload.sh          # Skrip untuk menghentikan unggahan
└── run/                        # Direktori untuk file log dan PID (diabaikan oleh Git)
    ├── upload.log              # Log dari proses unggah
    └── upload.pid              # File yang berisi PID proses unggah
```

## Kontribusi

Jika Anda ingin berkontribusi pada proyek ini, silakan fork repositori, buat branch baru, lakukan perubahan Anda, dan kirimkan pull request.

## Lisensi

Proyek ini dilisensikan di bawah [MIT License](LICENSE).
