# Corpus PowerShell Agent

The Corpus PowerShell Agent is an extremely lightweight, native Windows script designed to monitor document folders and send new or updated files to the central Corpus server. It uses only tools built into modern Windows (PowerShell, Task Scheduler), making it ideal for environments where installing external software like Python is not desirable.

## Key Features

- **No Installation Required:** Runs using the built-in PowerShell engine on Windows 10/11 and Windows Server 2016+.
- **Native Integration:** Uses Windows Task Scheduler to run reliably in the background and start automatically with the system.
- **Simple Configuration:** All settings are managed in a human-readable `config.json` file.
- **Text-File Native Support:** Can extract content from `.txt`, `.log`, `.csv`, and other plain-text files out of the box.
- **Microsoft Office Integration:** Can extract content from `.docx` files **if Microsoft Word is installed** on the machine.

## ⚠️ Important Prerequisites & Limitations

Unlike the Python-based agent, this script relies on other installed programs to read complex file formats.

- **Microsoft Word:** To process `.docx` files, the machine **must have Microsoft Word installed**. The script uses Word's own engine to read the content.
- **PDF Processing:** This script **cannot** process `.pdf` files by default. To enable PDF processing, a third-party command-line tool like `pdftotext.exe` (from the Xpdf tools) must be installed separately and be available in the system's `PATH`.
- **PowerShell Execution Policy:** You may need administrative rights to run the script for the first time or to set up the scheduled task.

---

## Installation and Setup Guide

Follow these steps on the Windows machine where your documents are located.

### Step 1: Place Agent Files

1.  Create a dedicated folder for the agent (e.g., `C:\Program Files\CorpusAgentPS`).
2.  Copy the two files from this directory into your new folder:
    - `CorpusAgent.ps1`
    - `config.json`

### Step 2: Configure the Agent

Open the `config.json` file with a text editor like Notepad and edit the following values:

```json
{
  "ApiUrl": "http://YOUR_CORPUS_SERVER_IP_OR_DOMAIN:8080/api/v1/documents/ingest",
  "ApiKey": "YOUR_AGENT_API_KEY",
  "MonitorDirectory": "C:\\path\\to\\your\\documents",
  "AllowedExtensions": [".txt", ".log", ".docx"]
}