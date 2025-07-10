from elasticsearch import AsyncElasticsearch
from app.core.config import settings

es_client = AsyncElasticsearch(
    f"http://{settings.ELASTICSEARCH_HOST}:{settings.ELASTICSEARCH_PORT}"
)

async def get_es_client():
    return es_client

async def close_es_client():
    await es_client.close()

async def create_indices():
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