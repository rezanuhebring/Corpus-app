import json
import csv
import io
from datetime import datetime
import uuid
from app.services.file_processor import FileProcessor
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form, Header
from fastapi.responses import StreamingResponse
from typing import List
from app.db.session import get_es_client
from elasticsearch import AsyncElasticsearch
from app.models.document import DocumentSearchRequest, DocumentSearchResult, DocumentInDB
from app.models.user import User
from app.core.auth import get_current_active_user

router = APIRouter()

async def verify_api_key(x_api_key: str = Header(...)):
    if x_api_key != "DEV_API_KEY_12345":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid API Key")

@router.post("/ingest", status_code=status.HTTP_201_CREATED)
async def ingest_document(
    json_payload: str = Form(...),
    original_file: UploadFile = File(...),
    es_client: AsyncElasticsearch = Depends(get_es_client),
    api_key: str = Depends(verify_api_key)
):
    try:
        payload = json.loads(json_payload)
        metadata = payload.get('metadata', {})
        content = payload.get('content', '')

        # Run the file processor
        processor = FileProcessor(metadata, content, original_file.filename)
        processed_data = processor.run_all()

        # Update metadata with processed data and original filename
        metadata.update(processed_data)
        metadata['filename_original'] = original_file.filename

        # Convert timestamps to datetime objects for storage
        if 'created_date' in metadata and metadata['created_date']:
            metadata['created_date'] = datetime.fromtimestamp(metadata['created_date'])
        if 'modified_date' in metadata and metadata['modified_date']:
            metadata['modified_date'] = datetime.fromtimestamp(metadata['modified_date'])

        # Prepare the document for Elasticsearch
        document_body = {
            "metadata": metadata,
            "content": content,
            "ingest_date": datetime.utcnow()
        }

        # Index the document
        response = await es_client.index(
            index="documents",
            id=str(uuid.uuid4()),
            document=document_body
        )

        return {
            "status": "success",
            "document_id": response['_id'],
            "filename_corpus": metadata.get('filename_corpus')
        }
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Invalid JSON payload.")
    except Exception as e:
        print(f"Error during ingestion: {e}")
        raise HTTPException(status_code=500, detail=f"An error occurred during document ingestion: {str(e)}")

@router.post("/search", response_model=DocumentSearchResult)
async def search_documents(
    search_params: DocumentSearchRequest,
    es_client: AsyncElasticsearch = Depends(get_es_client),
    current_user: User = Depends(get_current_active_user)
):
    query_body = {"bool": {"must": [], "filter": []}}
    if search_params.query:
        query_body["bool"]["must"].append({"multi_match": {"query": search_params.query, "fields": ["content", "metadata.filename_original", "metadata.client_project_name"]}})
    if search_params.client_project:
        query_body["bool"]["filter"].append({"term": {"metadata.client_project_name.keyword": search_params.client_project}})
    if search_params.doc_type:
        query_body["bool"]["filter"].append({"term": {"metadata.doc_type.keyword": search_params.doc_type}})
    if search_params.date_from or search_params.date_to:
        date_range = {}
        if search_params.date_from:
            date_range["gte"] = search_params.date_from
        if search_params.date_to:
            date_range["lt"] = search_params.date_to
        query_body["bool"]["filter"].append({"range": {"metadata.modified_date": date_range}})
    try:
        response = await es_client.search(index="documents", query=query_body, size=100)
        hits = [doc for doc in response['hits']['hits']]
        total = response['hits']['total']['value']
        return {"total": total, "hits": hits}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error searching documents: {e}")

@router.get("/{document_id}", response_model=DocumentInDB)
async def get_document_by_id(
    document_id: str,
    es_client: AsyncElasticsearch = Depends(get_es_client),
    current_user: User = Depends(get_current_active_user)
):
    try:
        response = await es_client.get(index="documents", id=document_id)
        return response
    except Exception:
        raise HTTPException(status_code=404, detail=f"Document with id '{document_id}' not found.")

@router.get("/recent/", response_model=List[DocumentInDB])
async def get_recent_documents(
    limit: int = 20,
    es_client: AsyncElasticsearch = Depends(get_es_client),
    current_user: User = Depends(get_current_active_user)
):
    try:
        sort_options = [{"metadata.modified_date": {"order": "desc"}}]
        response = await es_client.search(index="documents", sort=sort_options, size=limit)
        return [doc for doc in response['hits']['hits']]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching recent documents: {e}")

@router.post("/export/csv")
async def export_search_to_csv(
    search_params: DocumentSearchRequest,
    es_client: AsyncElasticsearch = Depends(get_es_client),
    current_user: User = Depends(get_current_active_user)
):
    query_body = {"bool": {"must": [], "filter": []}}
    if search_params.query:
        query_body["bool"]["must"].append({"multi_match": {"query": search_params.query, "fields": ["content", "metadata.filename_original", "metadata.client_project_name"]}})
    try:
        response = await es_client.search(index="documents", query=query_body, size=1000)
        hits = [doc['_source'] for doc in response['hits']['hits']]
        output = io.StringIO()
        writer = csv.writer(output)
        headers = ['Corpus Filename', 'Original Filename', 'Client/Project', 'Doc Type', 'Status', 'Modified Date', 'Language']
        writer.writerow(headers)
        for hit in hits:
            meta = hit.get('metadata', {})
            writer.writerow([
                meta.get('filename_corpus', ''), meta.get('filename_original', ''),
                meta.get('client_project_name', ''), meta.get('doc_type', ''),
                meta.get('status', ''), meta.get('modified_date', ''), meta.get('language', '')
            ])
        output.seek(0)
        return StreamingResponse(
            output, media_type="text/csv",
            headers={"Content-Disposition": f"attachment; filename=corpus_export_{datetime.now().strftime('%Y%m%d')}.csv"}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error exporting to CSV: {e}")