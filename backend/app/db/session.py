import asyncio
from elasticsearch import AsyncElasticsearch, ConnectionError as ESConnectionError
from app.core.config import settings

# --- Corrected Elasticsearch Client Initialization ---
# The client is configured to use the host and port from the settings file,
# which are loaded from your .env file. This makes the connection
# configurable and correctly points to the 'elasticsearch' service name.
es_client = AsyncElasticsearch(
    hosts=[
        {
            "host": settings.ELASTICSEARCH_HOST,
            "port": settings.ELASTICSEARCH_PORT,
            "scheme": "http"
        }
    ],
    request_timeout=30
)

async def get_es_client():
    """
    Returns the shared asynchronous Elasticsearch client instance.
    """
    return es_client

async def close_es_client():
    """
    Closes the shared asynchronous Elasticsearch client instance.
    """
    await es_client.close()

async def create_indices():
    """
    Connects to Elasticsearch with retries and creates the 'documents' index
    if it does not already exist.
    """
    max_retries = 15
    retry_delay = 5  # seconds

    for attempt in range(max_retries):
        try:
            # The ping() method confirms that a connection can be established.
            if await es_client.ping():
                print("✅ Successfully connected to Elasticsearch.")
                break
            else:
                # This case is unlikely but handled for completeness.
                print(f"Ping to Elasticsearch failed. Retrying... (Attempt {attempt + 1}/{max_retries})")
                await asyncio.sleep(retry_delay)
        except ESConnectionError:
            # This is the expected exception if the service is not ready.
            print(f"Waiting for Elasticsearch... (Attempt {attempt + 1}/{max_retries}).")
            if attempt + 1 == max_retries:
                print("❌ Could not connect to Elasticsearch after several attempts. Exiting.")
                # Re-raising the exception will cause the application to fail startup,
                # which is the correct behavior if the database is unavailable.
                raise
            await asyncio.sleep(retry_delay)
    
    # Define the structure (mapping) for the 'documents' index.
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

    # Check if the index already exists before trying to create it.
    if not await es_client.indices.exists(index="documents"):
        print("Creating 'documents' index...")
        await es_client.indices.create(
            index="documents",
            mappings=document_mapping
        )
        print("Index 'documents' created successfully.")
    else:
        print("Index 'documents' already exists.")