# NETLOAD: Dataverse Upload & Monitoring Tool

```
#################################################
#                     NETLOAD                   #
#################################################
      Dataverse Upload & Monitoring Tool
-------------------------------------------------
```

This CLI-based application is designed to facilitate the process of uploading files to Dataverse with monitoring and background execution features. NETLOAD helps you manage large file uploads more efficiently, providing status, duration, and upload speed information.

## Key Features

*   **Multi-Language Support**: Choose between Indonesian and English when starting the application, or change it anytime from the main menu.
*   **Background Uploads**: Run upload processes without locking your terminal.
*   **Real-time Monitoring**: Monitor upload logs directly to see progress.
*   **Detailed Upload Information**: Get duration, start/end times (with clear formatting), and average upload speed after the process is complete.
*   **Comprehensive Folder Upload Summary**: After completing a folder upload, a detailed summary is provided, including the total number of files uploaded, total size, overall duration, and average upload speed.
*   **Upload Process Feedback**: Informative messages appear after 100% file transfer to indicate that the process is still awaiting server response, preventing concerns about a stuck process.
*   **Improved API Key Security**: The API Key is never stored on disk and is now passed securely to the background process via a temporary, self-deleting configuration file, preventing its exposure in process listings. It remains visible during direct input for typo prevention but is hidden in summaries.
*   **Robust User Input**: Enhanced User Input: Input prompts are now displayed on a separate line from user entry, guaranteeing full backspace and line editing functionality even in problematic terminal environments.
*   **Process Handling**: Option to stop a running upload process.
*   **Original Files Retained**: The original data files you upload (e.g., PDFs, images, etc.) will remain in their original location after the upload process is complete.
*   **Temporary JSON Files Deleted Automatically**: JSON files generated as request payloads and JSON response files from the Dataverse server will be automatically deleted after a successful upload (response files will be retained in case of failure for debugging).

## Installation

1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/your-username/your-repo-name.git
    cd your-repo-name
    ```
    *(Replace `your-username/your-repo-name.git` with your repository details)*

2.  **Grant Execute Permissions**:
    Ensure the scripts have execute permissions:
    ```bash
    chmod +x upload_dataverse.sh scripts/*.sh
    ```

## How to Use

Run the main script from your terminal:

```bash
./upload_dataverse.sh
```

### Language Selection

When first running the application, you will be prompted to choose a language (Indonesian or English). Your choice will be saved for future use. You can also change the language at any time from the main menu.

### Main Menu

The application will present an interactive menu. The menu display will vary depending on whether an upload process is currently running or not.

**Example Menu Display (No active process):**

```
#################################################
#                     NETLOAD                   #
#################################################
      Dataverse Upload & Monitoring Tool
-------------------------------------------------
STATUS: No active upload process.

Choose an option:
  1. Start New Upload Process
  2. View Last Log
  3. Exit
  4. Change Language
-------------------------------------------------
```

### Menu Options

*   **Start New Upload Process (1 or 's')**:
    *   Will prompt you to enter upload details such as API Key, Persistent ID, file path, description, etc.
    *   The upload process will start in the background.
    *   **IMPORTANT**: When entering the API Key, characters will be visible on screen to help you prevent typos. The API Key will not be stored on disk.

*   **Monitor Upload Process (1)**:
    *   (Appears if a process is running) Displays upload logs in *real-time*. Press `Ctrl+C` to return to the main menu.

*   **Stop Upload Process (2)**:
    *   (Appears if a process is running) Sends a signal to stop the running background upload process.

*   **View Last Log (2 or 'l')**:
    *   Displays the entire content of the `run/upload.log` file using `less`.

*   **Clean Stale Process Status ('c')**:
    *   (Appears if a stale PID file is found) Deletes the process status file that might be left over from a previous process that did not stop correctly.

*   **Change Language (4 or 'L')**:
    *   Allows you to change the application's interface language.

*   **View Full Log (3)**:
    *   (Appears if a process is running) Displays the entire content of the `run/upload.log` file using `less`.

*   **Exit (3, 4, or 'q')**:
    *   Exits the application.

## Project Structure

```
.
├── .gitignore
├── README.md
├── upload_dataverse.sh         # Main menu script, language handling, and menu loop
├── scripts/
│   ├── start_upload.sh         # Core logic for starting uploads, user input, and progress feedback
│   ├── monitor_upload.sh       # Script for real-time monitoring of upload logs
│   └── stop_upload.sh          # Script for stopping a running upload
├── lang/                       # Directory containing language files
│   ├── id.sh                   # Messages in Indonesian
│   └── en.sh                   # Messages in English
└── run/                        # Directory for log and PID files (ignored by Git)
    ├── upload.log              # Log of the upload process
    ├── upload.pid              # File containing the PID of the upload process
    └── config.sh               # Stores user language preferences
```

## Contributing

If you wish to contribute to this project, please fork the repository, create a new branch, make your changes, and submit a pull request.

## License

This project is licensed under the [MIT License](LICENSE).
