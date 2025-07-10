from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class DocumentMetadata(BaseModel):
    filename_original: str
    filename_corpus: Optional[str] = None
    client_project_name: str
    created_date: datetime
    modified_date: datetime
    source_hostname: str
    creator: Optional[str] = None
    modifier: Optional[str] = None
    language: Optional[str] = None
    doc_type: Optional[str] = Field(None, description="e.g., AGMT, LTR, MEMO")
    status: Optional[str] = Field(None, description="e.g., DRAFT, EXECUTED, FILED")

class DocumentInDB(BaseModel):
    id: str = Field(..., alias="_id")
    source: dict = Field(..., alias="_source")

class DocumentSearchRequest(BaseModel):
    query: Optional[str] = None
    client_project: Optional[str] = None
    doc_type: Optional[str] = None
    date_from: Optional[datetime] = None
    date_to: Optional[datetime] = None
    
class DocumentSearchResult(BaseModel):
    total: int
    hits: List[DocumentInDB]