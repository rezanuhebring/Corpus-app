import os
import re
from datetime import datetime
from langdetect import detect
from app.core.config import settings

class FileProcessor:
    def __init__(self, metadata, content, original_filename):
        self.metadata = metadata
        self.content = content
        self.original_filename = original_filename
        self.processed_data = {}

    def run_all(self):
        self._detect_language()
        self._classify_document()
        self._generate_new_filename()
        return self.processed_data

    def _detect_language(self):
        try:
            lang = detect(self.content[:500])
            self.processed_data['language'] = lang
        except:
            self.processed_data['language'] = 'unknown'

    def _classify_document(self):
        content_lower = self.content.lower()
        if "agreement" in content_lower or "contract" in content_lower:
            self.processed_data['doc_type'] = "AGMT"
        elif "letter" in content_lower:
            self.processed_data['doc_type'] = "LTR"
        else:
            self.processed_data['doc_type'] = "MISC"
        if "draft" in content_lower or "for review" in content_lower:
            self.processed_data['status'] = "DRAFT"
        elif "executed" in content_lower or "signed" in content_lower:
            self.processed_data['status'] = "EXECUTED"
        else:
            self.processed_data['status'] = "PROCESSED"

    def _generate_new_filename(self):
        date_str = datetime.fromtimestamp(self.metadata['modified_date']).strftime('%Y-%m-%d')
        doc_type = self.processed_data.get('doc_type', 'DOC')
        status = self.processed_data.get('status', 'UNK')
        base, ext = os.path.splitext(self.original_filename)
        desc = re.sub(r'(?i)final|draft|v\d+|\d{4}-\d{2}-\d{2}', '', base)
        desc = re.sub(r'[^a-zA-Z0-9\s]', '', desc).strip()
        desc = re.sub(r'\s+', '_', desc)
        new_filename = f"{date_str}_{doc_type}_{desc}_{status}{ext}"
        self.processed_data['filename_corpus'] = new_filename