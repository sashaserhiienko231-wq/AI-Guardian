from fastapi import FastAPI
from fastapi import Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import os
import time
from collections import defaultdict, deque

from app.api.v1.routes import router
from app.core.database import Base, engine
from app.models import models

Base.metadata.create_all(bind=engine)

app = FastAPI(title="AI Guardian API", version="2.0.0")
allowed_origins = [
    origin.strip()
    for origin in os.getenv(
        "CORS_ORIGINS",
        "http://localhost,http://localhost:3000,http://localhost:8080",
    ).split(",")
    if origin.strip()
]
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=False,
    allow_methods=["GET", "POST", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)
app.include_router(router)


@app.get("/health")
def root_health():
    return {"status": "ok", "service": "AI Guardian", "version": "2.0.0"}


@app.get("/ready")
def root_ready():
    components: dict[str, str] = {"process": "ready"}
    try:
        with engine.connect() as connection:
            connection.exec_driver_sql("SELECT 1")
        components["database"] = "ready"
    except Exception:
        components["database"] = "not_ready"
    return {
        "status": "ready" if components["database"] == "ready" else "not_ready",
        "components": components,
    }

_api_requests: dict[str, deque[float]] = defaultdict(deque)


@app.middleware("http")
async def security_middleware(request: Request, call_next):
    content_length = request.headers.get("content-length")
    if content_length and int(content_length) > 1_048_576:
        return JSONResponse(status_code=413, content={"detail": "Request body too large"})

    limit = int(os.getenv("API_RATE_LIMIT_PER_MINUTE", "120"))
    key = request.client.host if request.client else "unknown"
    now = time.monotonic()
    window = _api_requests[key]
    while window and now - window[0] > 60:
        window.popleft()
    if len(window) >= limit:
        return JSONResponse(status_code=429, content={"detail": "API rate limit exceeded"})
    window.append(now)

    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Referrer-Policy"] = "no-referrer"
    response.headers["Content-Security-Policy"] = "default-src 'none'; frame-ancestors 'none'"
    response.headers["Permissions-Policy"] = "camera=(self), geolocation=(), microphone=()"
    return response


@app.exception_handler(ValueError)
async def value_error_handler(request: Request, exc: ValueError):
    return JSONResponse(status_code=422, content={"detail": str(exc)})


@app.exception_handler(Exception)
async def internal_error_handler(request: Request, exc: Exception):
    return JSONResponse(status_code=500, content={"detail": "Internal server error"})
