#!/bin/bash

# ==============================================================================
# English Language File (en.sh)
# Contains all user-facing messages in English.
# ==============================================================================

# --- upload_dataverse.sh (Main Menu) ---
MSG_SCRIPT_DIR_NOT_FOUND="The 'scripts' directory was not found. Please ensure all script files are there."
MSG_STATUS_UPLOAD_RUNNING="STATUS: Upload process is running (PID: %s)."
MSG_CHOOSE_OPTION="Choose an option:"
MSG_MENU_MONITOR_UPLOAD="1. Monitor Upload Process"
MSG_MENU_STOP_UPLOAD="2. Stop Upload Process"
MSG_MENU_VIEW_FULL_LOG="3. View Full Log"
MSG_MENU_EXIT="5. Exit"
MSG_STATUS_STALE_PID="STATUS: Stale process file (PID) found. The previous process might not have stopped correctly."
MSG_STATUS_CHECK_LOG_BEFORE_NEW="STATUS: It is recommended to check the log before starting a new upload."
MSG_MENU_START_NEW_UPLOAD_STALE="s. Start New Upload Process"
MSG_MENU_VIEW_LAST_LOG_STALE="l. View Last Log"
MSG_MENU_CLEAN_STALE_STATUS="c. Clean Stale Process Status"
MSG_MENU_EXIT_STALE="q. Exit"
MSG_STATUS_NO_ACTIVE_UPLOAD="STATUS: No active upload process."
MSG_MENU_START_NEW_UPLOAD="1. Start New Upload Process"
MSG_MENU_VIEW_LAST_LOG="2. View Last Log"
MSG_MENU_EXIT_NO_PROCESS="3. Exit"
MSG_PROMPT_ENTER_CHOICE_RUNNING="Enter your choice [1-4]: "
MSG_INVALID_CHOICE="Invalid choice."
MSG_PROMPT_ENTER_CHOICE_STALE="Enter your choice [s, l, c, q]: "
MSG_STALE_STATUS_CLEANED="Stale process status has been cleaned."
MSG_LOG_FILE_NOT_EXIST="Log file does not exist."
MSG_PROMPT_ENTER_CHOICE_NO_PROCESS="Enter your choice [1-3]: "
MSG_PROMPT_PRESS_ENTER_TO_CONTINUE="Press [Enter] to return to menu..."
MSG_EXITING_APP="Exiting application."
MSG_CHOOSE_LANGUAGE="Pilih Bahasa / Choose Language:"
MSG_LANG_INDONESIAN="1. Bahasa Indonesia"
MSG_LANG_ENGLISH="2. English"
MSG_PROMPT_LANG_CHOICE="Enter your choice [1-2]: "
MSG_SAVING_LANG_PREF="Saving language preference..."

# --- scripts/start_upload.sh ---
MSG_STARTING_UPLOAD_BACKGROUND_TITLE="STARTING UPLOAD PROCESS IN BACKGROUND"
MSG_TIME_START="Start Time      : "
MSG_FILE_TO_UPLOAD="File to upload  : "
MSG_FILE_SIZE="File Size       : "
MSG_URL_TARGET="Target URL      : "
MSG_TRYING_UPLOAD="Attempting upload (Attempt %s of %s)..."
MSG_UPLOAD_SUCCESS_ATTEMPT="✅ Upload successful on attempt #%s."
MSG_UPLOAD_START_TIME="Upload Start Time : "
MSG_UPLOAD_END_TIME="Upload End Time   : "
MSG_UPLOAD_DURATION="Upload Duration   : "
MSG_AVG_SPEED="Average Speed     : "
MSG_SPEED_NOTE="Note: Min/max speed is difficult to measure accurately in a shell script."
MSG_UPLOAD_FAILED_ATTEMPT="❌ Attempt #%s failed with exit code: %s."
MSG_WAITING_RETRY="Waiting %s seconds before retrying..."
MSG_MAX_RETRIES_REACHED="Maximum number of attempts (%s) reached."
MSG_TRANSFER_COMPLETE_WAITING_SERVER_RESPONSE="File transfer complete. Waiting for final response from Dataverse server..."
MSG_SERVER_RESPONSE_DELAY_NOTE="This may take some time depending on file size and server load."
MSG_UPLOAD_COMPLETE_SUCCESS="✅ UPLOAD PROCESS COMPLETE: SUCCESS"
MSG_SERVER_RESPONSE_SAVED="Server response saved to '%s'."
MSG_UPLOAD_COMPLETE_FAILED="❌ UPLOAD PROCESS COMPLETE: FAILED"
MSG_PERMANENT_ERROR_CHECK_LOG="A permanent error occurred. Check the log above for details."
MSG_ERROR_ANOTHER_UPLOAD_RUNNING="❌ Error: Another upload process is already running."
MSG_MONITOR_OR_STOP_FROM_MENU="Please monitor or stop that process from the main menu."
MSG_START_NEW_UPLOAD_PROMPT_TITLE="--- Starting New Upload Process ---"
MSG_ENTER_UPLOAD_DETAILS_BACKGROUND="Please enter upload details. The process will run in the background."
MSG_IMPORTANT_SECURITY_NOTE_1="IMPORTANT: Sensitive information like API Keys will not be stored on disk."
MSG_IMPORTANT_SECURITY_NOTE_2="This is for your security and convenience. Each session requires input."
MSG_PROMPT_API_KEY="Enter your API Key:"
MSG_API_KEY_EMPTY="API Key cannot be empty."
MSG_PROMPT_PERSISTENT_ID="Enter dataset Persistent ID:"
MSG_PERSISTENT_ID_EMPTY="Persistent ID cannot be empty."

# Messages for Upload Type (File/Folder)
MSG_PROMPT_UPLOAD_TYPE="Select upload type (1=File, 2=Folder):"
MSG_PROMPT_FOLDER_PATH="Enter the full path to the folder:"
MSG_FOLDER_NOT_FOUND="Folder not found at '%s'."
MSG_NO_FILES_IN_FOLDER="No files found in the folder '%s'."
MSG_ERROR_TOTAL_FOLDER_SIZE_EXCEEDS="ERROR: Your total folder size (%s GB) exceeds the maximum limit (70 GB)."
MSG_UPLOAD_SUMMARY_TITLE="UPLOAD PROCESS SUMMARY"
MSG_UPLOAD_SUMMARY_TYPE_FILE="Type: Single File Upload"
MSG_UPLOAD_SUMMARY_TYPE_FOLDER="Type: Folder Upload"
MSG_UPLOAD_SUMMARY_TOTAL_FILES="Total Files: %s"
MSG_UPLOAD_SUMMARY_TOTAL_SIZE="Total Size: %s"
MSG_UPLOAD_SUMMARY_SOURCE_PATH="Source Path: %s"
MSG_UPLOAD_SUMMARY_PERSISTENT_ID="Persistent ID: %s"
MSG_UPLOAD_SUMMARY_API_KEY="API Key: Hidden"
MSG_UPLOAD_CONFIRM_PROMPT="Do you want to continue? (y/n)"
MSG_UPLOAD_ABORTED="Operation cancelled by user."
MSG_ALL_FILES_UPLOADED_SUCCESS="✅ All files from folder '%s' were uploaded successfully."
MSG_FOLDER_UPLOAD_FAILED="❌ Failed to upload file '%s'. The process will be aborted."

MSG_PROMPT_FILE_PATH="Enter full path to file:"
MSG_FILE_NOT_FOUND="File not found at '%s'."
MSG_ERROR_FILE_SIZE_EXCEEDS="ERROR: Your file size (%s GB) exceeds the maximum limit (70 GB)."
MSG_PROMPT_DESCRIPTION="File description [Large file upload]: "
MSG_DEFAULT_DESCRIPTION="Large file upload"
MSG_PROMPT_DIRECTORY_LABEL="Directory label [data/subdir1]: "
MSG_PROMPT_BASE_DIRECTORY_LABEL="Enter Base Directory Label (optional, leave blank to use local folder name):"
MSG_DEFAULT_DIRECTORY_LABEL="data/subdir1"
MSG_PROMPT_CATEGORIES="Categories (comma-separated) [Data]: "
MSG_DEFAULT_CATEGORIES="Data"
MSG_PROMPT_RESTRICT="Restrict file (y/n) [n]: "
MSG_PROMPT_OUTPUT_FILE="Output file name [result.json]: "
MSG_DEFAULT_OUTPUT_FILE="result.json"
MSG_INFO_RECEIVED_STARTING_BACKGROUND="Information received. Starting upload process in the background..."
MSG_MONITOR_FROM_MAIN_MENU="You can monitor it from the main menu."
MSG_PROCESS_STARTED_PID="Process started with PID: %s."

# --- scripts/monitor_upload.sh ---
MSG_MONITOR_UPLOAD_TITLE="--- Monitoring Upload Process ---"
MSG_NO_UPLOAD_RUNNING="No upload process is currently running."
MSG_PROCESS_NOT_RUNNING="Upload process (PID: %s) is no longer running."
MSG_PROCESS_FINISHED_OR_FAILED="It may have finished or failed. Check the log for details."
MSG_PROCESS_RUNNING="Upload process is running (PID: %s)."
MSG_MONITORING_LOG_REALTIME="Displaying log in real-time. Press [Ctrl+C] to stop monitoring."

# --- scripts/stop_upload.sh ---
MSG_STOP_UPLOAD_TITLE="--- Stopping Upload Process ---"
MSG_NO_UPLOAD_TO_STOP="No upload process to stop."
MSG_PROCESS_ALREADY_STOPPED="Process (PID: %s) is no longer running."
MSG_CLEANING_STALE_STATUS="Cleaning stale process status..."
MSG_SENDING_STOP_SIGNAL="Sending stop signal to upload process with PID: %s..."
MSG_PROCESS_NOT_STOPPED_NORMALLY="Process did not stop normally. Attempting to force stop (kill -9)..."
MSG_UPLOAD_STOPPED="Upload process has been stopped."
MSG_STATUS_FILE_CLEANED="Status file has been cleaned."

# New messages for language selection
MSG_MENU_CHANGE_LANGUAGE="4. Change Language" # For running process menu
MSG_MENU_CHANGE_LANGUAGE_STALE="L. Change Language" # For stale PID menu
MSG_MENU_CHANGE_LANGUAGE_NO_PROCESS="3. Change Language" # For no process menu
MSG_MENU_EXIT_NO_PROCESS="4. Exit"

# Updated prompts to reflect new options
MSG_PROMPT_ENTER_CHOICE_RUNNING="Enter your choice [1-5]: " # Updated from [1-4]
MSG_PROMPT_ENTER_CHOICE_STALE="Enter your choice [s, l, c, L, q]: " # Updated from [s, l, c, q]
MSG_PROMPT_ENTER_CHOICE_NO_PROCESS="Enter your choice [1-4]: " # Updated from [1-3]

# New message for progress bar note
MSG_PROGRESS_BAR_NOTE="Note: The progress bar display might appear raw/messy in the log."
MSG_RESULT_FILE_DELETED="Temporary server response file has been deleted."
MSG_ERROR_RESULT_FILE_RETAINED="Server response file (containing potential errors) retained at '%s' for debugging."

# --- Messages for Folder Upload Summary ---
MSG_FOLDER_SUMMARY_TITLE="--- FOLDER UPLOAD SUMMARY ---"
MSG_FOLDER_SUMMARY_TOTAL_SUCCESS="Files successfully uploaded: %s of %s"
MSG_FOLDER_SUMMARY_TOTAL_SIZE="Total uploaded size      : %s"
MSG_FOLDER_SUMMARY_TOTAL_DURATION="Total duration           : %s minutes %s seconds"
MSG_FOLDER_SUMMARY_AVG_SPEED="Average speed          : %s/s"
