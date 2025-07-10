import os
import time
import json
import requests
import configparser
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

def extract_text_from_docx(file_path):
    return "This is placeholder text from a Word document."
def extract_text_from_pdf(file_path):
    return "This is placeholder text from a PDF document."
def extract_text_from_xlsx(file_path):
    return "This is placeholder text from an Excel document."
def extract_text_from_txt(file_path):
    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
        return f.read()

EXTRACTORS = {
    '.docx': extract_text_from_docx,
    '.pdf': extract_text_from_pdf,
    '.xlsx': extract_text_from_xlsx,
    '.txt': extract_text_from_txt,
}

class DocumentHandler(FileSystemEventHandler):
    def __init__(self, config):
        self.api_url = config.get('Corpus', 'api_url')
        self.api_key = config.get('Corpus', 'api_key')
        self.monitor_root = config.get('Corpus', 'monitor_directory')
        self.allowed_extensions = [ext.strip() for ext in config.get('Corpus', 'allowed_extensions').split(',')]

    def on_created(self, event):
        if not event.is_directory: self.process_file(event.src_path)
    def on_modified(self, event):
        if not event.is_directory: self.process_file(event.src_path)

    def get_client_project_name(self, file_path):
        relative_path = os.path.relpath(file_path, self.monitor_root)
        parts = relative_path.split(os.sep)
        return parts[0] if parts else "Uncategorized"

    def process_file(self, file_path):
        filename, extension = os.path.splitext(file_path)
        if extension.lower() not in self.allowed_extensions: return

        print(f"Detected change: {file_path}")
        try:
            stat = os.stat(file_path)
            metadata = {
                'filename_full_path': file_path,
                'client_project_name': self.get_client_project_name(file_path),
                'created_date': stat.st_ctime,
                'modified_date': stat.st_mtime,
                'source_hostname': os.uname().nodename,
                'creator': 'N/A', 'modifier': 'N/A',
            }
            extractor_func = EXTRACTORS.get(extension.lower())
            if not extractor_func: return
            content = extractor_func(file_path)
            payload = {'metadata': metadata, 'content': content}
            files = {'original_file': (os.path.basename(file_path), open(file_path, 'rb'))}
            headers = {'X-API-Key': self.api_key}
            response = requests.post(self.api_url, headers=headers, data={'json_payload': json.dumps(payload)}, files=files)
            if response.status_code == 201: print(f"Successfully sent {file_path} to Corpus server.")
            else: print(f"Error sending file: {response.status_code} - {response.text}")
        except Exception as e: print(f"An error occurred while processing {file_path}: {e}")

if __name__ == "__main__":
    print("Starting Corpus Agent...")
    config = configparser.ConfigParser()
    config.read('config.ini')
    path_to_watch = config.get('Corpus', 'monitor_directory')
    if not os.path.isdir(path_to_watch):
        print(f"Error: Monitoring directory '{path_to_watch}' not found.")
        exit(1)
    event_handler = DocumentHandler(config)
    observer = Observer()
    observer.schedule(event_handler, path_to_watch, recursive=True)
    observer.start()
    print(f"Watching for file changes in: {path_to_watch}")
    try:
        while True: time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()