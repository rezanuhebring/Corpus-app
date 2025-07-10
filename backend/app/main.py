from fastapi import FastAPI
from app.api.v1.endpoints import documents, auth
from app.db.session import create_indices, close_es_client

app = FastAPI(
    title="Corpus API",
    description="Backend services for the Corpus Document Management System.",
    version="1.0.0"
)

@app.on_event("startup")
async def startup_event():
    await create_indices()

@app.on_event("shutdown")
async def shutdown_event():
    await close_es_client()

app.include_router(auth.router, prefix="/api/v1/auth", tags=["Authentication"])
app.include_router(documents.router, prefix="/api/v1/documents", tags=["Documents"])

@app.get("/health", tags=["System"])
async def health_check():
    return {"status": "ok"}