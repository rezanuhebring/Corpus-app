import time
import asyncio
from elasticsearch import AsyncElasticsearch, ConnectionError as ESConnectionError
from app.core.config import settings

# --- THIS IS THE FIX ---
# We build the connection string directly, using the hardcoded port 9200,
# and no longer try to access the non-existent 'ELASTICSEARCH_PORT' setting.
es_client = AsyncElasticsearch(
    f"http://{settings.ELASTICSEARCH_HOST}:9200",
    request_timeout=30
)

async def get_es_client():
    return es_client

async def close_es_client():
    await es_client.close()

async def create_indices():
    max_retries = 15
    retry_delay = 5  # seconds

    for attempt in range(max_retries):
        try:
            if await es_client.ping():
                print("✅ Successfully connected to Elasticsearch.")
                break
            else:
                print(f"Ping to Elasticsearch failed. Retrying... (Attempt {attempt + 1}/{max_retries})")
                await asyncio.sleep(retry_delay)
        except ESConnectionError as e:
            print(f"Waiting for Elasticsearch... (Attempt {attempt + 1}/{max_retries}). Error: {e}")
            if attempt + 1 == max_retries:
                print("❌ Could not connect to Elasticsearch after several attempts. Exiting.")
                raise
            await asyncio.sleep(retry_delay)
    
    document_mapping = {
        "properties": {
            "metadata": {"properties": { "filename_original": {"type": "keyword"}, "filename_corpus": {"type": "keyword"}, "client_project_name": {"type": "keyword"}, "created_date": {"type": "date"}, "modified_date": {"type": "date"}, "source_hostname": {"type": "keyword"}, "creator": {"type": "keyword"}, "modifier": {"type": "keyword"}, "language": {"type": "keyword"}, "doc_type": {"type": "keyword"}, "status": {"type": "keyword"}}},
            "content": {"type": "text", "analyzer": "standard"},
            "tags": {"type": "keyword"}
        }
    }
    if not await es_client.indices.exists(index="documents"):
        print("Creating 'documents' index...")
        await es_client.indices.create(
            index="documents",
            mappings=document_mapping
        )
    else:
        print("Index 'documents' already exists.")