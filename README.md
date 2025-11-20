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

*   **Dukungan Multi-Bahasa**: Pilih antara Bahasa Indonesia dan English saat memulai aplikasi, atau ubah kapan saja dari menu utama.
*   **Unggah di Latar Belakang**: Jalankan proses unggah tanpa mengunci terminal Anda.
*   **Pemantauan Real-time**: Pantau log unggahan secara langsung untuk melihat progres.
*   **Informasi Detail Unggah**: Dapatkan durasi, waktu mulai/selesai (dengan format yang jelas), dan kecepatan rata-rata unggah setelah proses selesai.
*   **Feedback Proses Unggah**: Pesan informatif muncul setelah 100% transfer file untuk memberitahu bahwa proses masih menunggu respons server, mencegah kekhawatiran proses macet.
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

### Pemilihan Bahasa

Saat pertama kali menjalankan aplikasi, Anda akan diminta untuk memilih bahasa (Bahasa Indonesia atau English). Pilihan Anda akan disimpan untuk penggunaan selanjutnya. Anda juga dapat mengubah bahasa kapan saja dari menu utama.

### Menu Utama

Aplikasi akan menyajikan menu interaktif. Tampilan menu akan bervariasi tergantung pada apakah ada proses unggah yang sedang berjalan atau tidak.

**Contoh Tampilan Menu (Tidak ada proses aktif):**

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
  4. Ganti Bahasa
-------------------------------------------------
```

### Opsi Menu

*   **Mulai Proses Upload Baru (1 atau 's')**:
    *   Akan meminta Anda untuk memasukkan detail unggahan seperti API Key, Persistent ID, path file, deskripsi, dll.
    *   Proses unggah akan dimulai di latar belakang.
    *   **PENTING**: Informasi rahasia seperti API Key tidak akan disimpan di disk.

*   **Pantau Proses Upload (1)**:
    *   (Muncul jika ada proses berjalan) Menampilkan log unggahan secara *real-time*. Tekan `Ctrl+C` untuk kembali ke menu utama.

*   **Hentikan Proses Upload (2)**:
    *   (Muncul jika ada proses berjalan) Mengirim sinyal untuk menghentikan proses unggah yang sedang berjalan di latar belakang.

*   **Lihat Log Terakhir (2 atau 'l')**:
    *   Menampilkan seluruh isi file log `run/upload.log` menggunakan `less`.

*   **Bersihkan Status Proses Usang ('c')**:
    *   (Muncul jika ada file PID usang) Menghapus file status proses yang mungkin tertinggal dari proses sebelumnya yang tidak berhenti dengan benar.

*   **Ganti Bahasa (4 atau 'L')**:
    *   Memungkinkan Anda untuk mengubah bahasa antarmuka aplikasi.

*   **Lihat Log Keseluruhan (3)**:
    *   (Muncul jika ada proses berjalan) Menampilkan seluruh isi file log `run/upload.log` menggunakan `less`.

*   **Keluar (3, 4, atau 'q')**:
    *   Keluar dari aplikasi.

## Struktur Proyek

```
.
├── .gitignore
├── README.md
├── upload_dataverse.sh         # Skrip menu utama, penanganan bahasa, dan loop menu
├── scripts/
│   ├── start_upload.sh         # Logika inti untuk memulai unggahan, input pengguna, dan feedback progres
│   ├── monitor_upload.sh       # Skrip untuk memantau log unggahan secara real-time
│   └── stop_upload.sh          # Skrip untuk menghentikan unggahan yang sedang berjalan
├── lang/                       # Direktori berisi file bahasa
│   ├── id.sh                   # Pesan dalam Bahasa Indonesia
│   └── en.sh                   # Pesan dalam Bahasa Inggris
└── run/                        # Direktori untuk file log dan PID (diabaikan oleh Git)
    ├── upload.log              # Log dari proses unggah
    ├── upload.pid              # File yang berisi PID proses unggah
    └── config.sh               # Menyimpan preferensi bahasa pengguna
```

## Kontribusi

Jika Anda ingin berkontribusi pada proyek ini, silakan fork repositori, buat branch baru, lakukan perubahan Anda, dan kirimkan pull request.

## Lisensi

Proyek ini dilisensikan di bawah [MIT License](LICENSE).