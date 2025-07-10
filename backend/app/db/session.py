import time
import asyncio
from elasticsearch import AsyncElasticsearch, ConnectionError as ESConnectionError
from app.core.config import settings

es_client = AsyncElasticsearch(
    f"http://{settings.ELASTICSEARCH_HOST}:{settings.ELASTICSEARCH_PORT}"
)

async def get_es_client():
    return es_client

async def close_es_client():
    await es_client.close()

async def create_indices():
    """
    Creates the necessary Elasticsearch indices on startup.
    Includes a retry mechanism to wait for Elasticsearch to be fully ready.
    """
    max_retries = 10
    retry_delay = 5  # seconds

    for attempt in range(max_retries):
        try:
            # The first real command to check if ES is ready
            if await es_client.ping():
                print("✅ Successfully connected to Elasticsearch.")
                break
            else:
                raise ESConnectionError("Ping to Elasticsearch failed.")
        except ESConnectionError as e:
            print(f"Waiting for Elasticsearch... (Attempt {attempt + 1}/{max_retries}). Error: {e}")
            if attempt + 1 == max_retries:
                print("❌ Could not connect to Elasticsearch after several attempts. Exiting.")
                raise
            await asyncio.sleep(retry_delay)
    
    # Once connected, proceed with creating the index
    document_mapping = {
        "properties": {
            "metadata": {
                "properties": {
                    "filename_original": {"type": "keyword"},
                    "filename_corpus": {"type": "keyword"},
                    "client_project_name": {"type": "keyword"},
                    "created_date": {"type": "date"},
                    "modified_date": {"type": "date"},
                    "source_hostname": {"type": "keyword"},
                    "creator": {"type": "keyword"},
                    "modifier": {"type": "keyword"},
                    "language": {"type": "keyword"},
                    "doc_type": {"type": "keyword"},
                    "status": {"type": "keyword"}
                }
            },
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