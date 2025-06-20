from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(title="AI Teacher Clone", version="0.1.0")


class HealthResponse(BaseModel):
    status: str
    service: str
    version: str


class WelcomeResponse(BaseModel):
    message: str
    service: str
    version: str


@app.get("/", response_model=WelcomeResponse)
def read_root() -> WelcomeResponse:
    return WelcomeResponse(
        message="Welcome to AI Teacher Clone API",
        service="AI Teacher Clone",
        version="0.1.0",
    )


@app.get("/health", response_model=HealthResponse)
def health_check() -> HealthResponse:
    return HealthResponse(status="healthy", service="AI Teacher Clone", version="0.1.0")
