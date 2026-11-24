from datetime import datetime, timedelta, timezone
import csv
import io
import os
import time
from collections import defaultdict, deque
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, Query, Request, Header
from fastapi.responses import StreamingResponse
from sqlalchemy import desc, func
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.models import ScanHistory
from app.schemas.schemas import (
    AssistantRequest, EmailScanRequest, LearningProgress, QRScanRequest,
    PasswordScanRequest, UrlScanRequest,
)
from app.services.security import analyze_email, analyze_qr, analyze_url
from app.services.ai_assistant import get_assistant_provider
from app.ml.inference import load_configured_classifier

router = APIRouter(prefix="/api/v1")
_assistant_requests: dict[str, deque[float]] = defaultdict(deque)


def require_history_authorization(
    authorization: str | None = Header(default=None),
) -> None:
    token = os.getenv("API_AUTH_TOKEN")
    production = os.getenv("API_PRODUCTION", "false").lower() in {"1", "true", "yes"}
    if production and not token:
        raise HTTPException(
            status_code=503,
            detail="Production API token is not configured",
        )
    if not token:
        return
    if authorization != f"Bearer {token}":
        raise HTTPException(status_code=401, detail="Authorization required")


def save_scan(db: Session, scan_type: str, result: dict) -> dict:
    scan_id = str(uuid4())
    row = ScanHistory(
        id=scan_id,
        scan_type=scan_type,
        risk_score=result["risk_score"],
        risk_category=result["risk_category"],
        indicators=result["indicators"],
        summary="; ".join(result["explanations"])[:500],
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return {
        "id": scan_id, "type": scan_type, "risk_score": result["risk_score"],
        "risk_category": result["risk_category"], "indicators": result["indicators"],
        "explanations": result["explanations"],
        "recommended_actions": result["recommended_actions"],
        "timestamp": row.created_at,
    }


@router.get("/health")
def health():
    return {"status": "ok", "service": "AI Guardian", "version": "2.0.0"}


@router.get("/ready")
def readiness(db: Session = Depends(get_db)):
    components: dict[str, str] = {}
    try:
        db.execute(func.text("SELECT 1"))
        components["database"] = "ready"
    except Exception:
        components["database"] = "not_ready"
    classifier = load_configured_classifier()
    components["ml_model"] = "ready" if classifier else "not_configured"
    components["ai_local"] = "ready"
    components["ai_provider"] = os.getenv("AI_PROVIDER", "local").lower()
    ready = components["database"] == "ready"
    return {"status": "ready" if ready else "not_ready", "components": components}


@router.post("/scanner/url")
def scan_url(payload: UrlScanRequest, db: Session = Depends(get_db)):
    try:
        result = analyze_url(payload.url)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    response = save_scan(db, "url", result)
    classifier = load_configured_classifier()
    if classifier:
        response["ml_prediction"] = classifier.predict(payload.url)
        response["ml_disclosure"] = "Probabilistic model output, not a confirmed threat."
    else:
        response["ml_prediction"] = None
        response["ml_disclosure"] = "No trained ML model is currently loaded."
    return response


@router.post("/scanner/url/ml")
def scan_url_ml(payload: UrlScanRequest):
    classifier = load_configured_classifier()
    if not classifier:
        raise HTTPException(status_code=503, detail="No trained ML model is currently loaded")
    try:
        prediction = classifier.predict(payload.url)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    return {
        "url": payload.url,
        "ml_prediction": prediction,
        "disclosure": "Probabilistic model output, not a confirmed threat.",
    }


@router.post("/scanner/email")
def scan_email(payload: EmailScanRequest, db: Session = Depends(get_db)):
    result = analyze_email(payload.subject, payload.body, payload.sender, payload.headers)
    return save_scan(db, "email", result)


@router.post("/scanner/qr")
def scan_qr(payload: QRScanRequest, db: Session = Depends(get_db)):
    try:
        result = analyze_qr(payload.content)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    return save_scan(db, "qr", result)




@router.get("/history", dependencies=[Depends(require_history_authorization)])
def history(page: int = Query(1, ge=1), limit: int = Query(20, ge=1, le=100),
            scan_type: str | None = None, q: str | None = None,
            sort: str = Query("newest", pattern="^(newest|oldest|risk_high|risk_low)$"),
            db: Session = Depends(get_db)):
    query = db.query(ScanHistory)
    if scan_type:
        query = query.filter(ScanHistory.scan_type == scan_type)
    if q:
        query = query.filter(ScanHistory.summary.contains(q))
    if sort == "oldest":
        query = query.order_by(ScanHistory.created_at.asc())
    elif sort == "risk_high":
        query = query.order_by(desc(ScanHistory.risk_score))
    elif sort == "risk_low":
        query = query.order_by(ScanHistory.risk_score.asc())
    else:
        query = query.order_by(desc(ScanHistory.created_at))
    total = query.count()
    items = query.offset((page - 1) * limit).limit(limit).all()
    return {"items": items, "page": page, "limit": limit, "total": total}


@router.get("/history/export", dependencies=[Depends(require_history_authorization)])
def export_history(format: str = Query("json", pattern="^(json|csv)$"), db: Session = Depends(get_db)):
    items = db.query(ScanHistory).order_by(desc(ScanHistory.created_at)).all()
    rows = [
        {
            "id": item.id,
            "scan_type": item.scan_type,
            "risk_score": item.risk_score,
            "risk_category": item.risk_category,
            "indicators": item.indicators,
            "summary": item.summary,
            "created_at": item.created_at.isoformat(),
        }
        for item in items
    ]
    if format == "csv":
        output = io.StringIO()
        writer = csv.DictWriter(output, fieldnames=["id", "scan_type", "risk_score", "risk_category", "summary", "created_at"])
        writer.writeheader()
        for row in rows:
            writer.writerow({key: row[key] for key in writer.fieldnames})
        return StreamingResponse(io.BytesIO(output.getvalue().encode("utf-8")), media_type="text/csv",
                                 headers={"Content-Disposition": "attachment; filename=ai_guardian_history.csv"})
    from fastapi.responses import JSONResponse
    return JSONResponse(rows, headers={"Content-Disposition": "attachment; filename=ai_guardian_history.json"})


@router.get("/history/{scan_id}", dependencies=[Depends(require_history_authorization)])
def history_detail(scan_id: str, db: Session = Depends(get_db)):
    item = db.get(ScanHistory, scan_id)
    if not item:
        raise HTTPException(status_code=404, detail="Scan not found")
    return item


@router.delete("/history/{scan_id}", status_code=204, dependencies=[Depends(require_history_authorization)])
def delete_history(scan_id: str, db: Session = Depends(get_db)):
    item = db.get(ScanHistory, scan_id)
    if not item:
        raise HTTPException(status_code=404, detail="Scan not found")
    db.delete(item)
    db.commit()
    return None


@router.get("/dashboard/statistics", dependencies=[Depends(require_history_authorization)])
def dashboard(period: str = Query("all", pattern="^(all|day|week|month)$"),
              db: Session = Depends(get_db)):
    base_query = db.query(ScanHistory)
    if period != "all":
        days = {"day": 1, "week": 7, "month": 30}[period]
        base_query = base_query.filter(ScanHistory.created_at >= datetime.now(timezone.utc) - timedelta(days=days))
    total = base_query.count()
    threats = base_query.filter(ScanHistory.risk_score >= 40).count()
    safe = base_query.filter(ScanHistory.risk_score < 20).count()
    suspicious = base_query.filter(ScanHistory.risk_score >= 20).count()
    last = base_query.order_by(desc(ScanHistory.created_at)).first()
    categories = base_query.with_entities(ScanHistory.risk_category, func.count(ScanHistory.id)).group_by(
        ScanHistory.risk_category).all()
    score = 100 - round(threats * 100 / max(total, 1))
    return {
        "period": period, "security_score": max(0, score), "total_scans": total, "threats_detected": threats,
        "safe_scans": safe, "suspicious_scans": suspicious,
        "security_score_formula": "100 - rounded percentage of scans with risk_score >= 40",
        "threat_distribution": [{"category": category, "count": count} for category, count in categories],
        "recommendations": ["Review high-risk findings.", "Keep software updated.", "Use unique passwords."],
        "last_scan_timestamp": last.created_at if last else None,
    }


@router.post("/assistant/chat")
def assistant_chat(payload: AssistantRequest, request: Request):
    limit = int(os.getenv("AI_RATE_LIMIT_PER_MINUTE", "20"))
    key = request.client.host if request.client else "unknown"
    now = time.monotonic()
    window = _assistant_requests[key]
    while window and now - window[0] > 60:
        window.popleft()
    if len(window) >= limit:
        raise HTTPException(status_code=429, detail="AI assistant rate limit exceeded")
    window.append(now)
    try:
        return get_assistant_provider().chat(payload.message)
    except RuntimeError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc


@router.get("/assistant/providers")
def assistant_providers():
    provider = os.getenv("AI_PROVIDER", "local").lower()
    providers = [
        {"name": "local", "available": True, "configured": provider == "local"},
        {"name": "ollama", "available": False, "configured": provider == "ollama"},
        {"name": "openai", "available": bool(os.getenv("OPENAI_API_KEY")), "configured": provider == "openai"},
    ]
    from app.services.ai_assistant import OllamaAssistant
    if provider == "ollama":
        providers[1] = OllamaAssistant().status()
        providers[1]["name"] = "ollama"
        providers[1]["configured"] = True
    return {"active_provider": provider, "providers": providers}


@router.get("/assistant/models/ollama")
def ollama_models():
    from app.services.ai_assistant import OllamaAssistant
    return OllamaAssistant().status()


_progress = LearningProgress()


@router.get("/learning/lessons")
def learning_lessons():
    return [
        {"id": "phishing", "title": "Phishing awareness", "localized_title": {"uk": "Усвідомлення фішингу", "en": "Phishing awareness"}, "level": "beginner"},
        {"id": "passwords", "title": "Password security", "localized_title": {"uk": "Безпека паролів", "en": "Password security"}, "level": "beginner"},
        {"id": "safe-browsing", "title": "Safe browsing", "localized_title": {"uk": "Безпечний перегляд", "en": "Safe browsing"}, "level": "intermediate"},
        {"id": "qr-safety", "title": "QR code safety", "localized_title": {"uk": "Безпека QR-кодів", "en": "QR code safety"}, "level": "beginner"},
    ]


@router.get("/learning/progress")
def get_progress():
    return _progress


@router.post("/learning/progress")
def update_progress(progress: LearningProgress):
    global _progress
    _progress = progress
    return _progress


@router.get("/settings")
def settings():
    return {"language": "uk", "theme": "dark", "retention_days": 365}
