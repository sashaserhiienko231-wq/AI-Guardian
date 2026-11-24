from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field


class UrlScanRequest(BaseModel):
    url: str = Field(min_length=1, max_length=2048)


class EmailScanRequest(BaseModel):
    subject: str = Field(default="", max_length=1000)
    body: str = Field(default="", max_length=100000)
    sender: str = Field(default="", max_length=500)
    headers: dict[str, str] = Field(default_factory=dict)


class QRScanRequest(BaseModel):
    content: str = Field(min_length=1, max_length=10000)


class PasswordScanRequest(BaseModel):
    password: str = Field(min_length=1, max_length=1024)


class ScanResult(BaseModel):
    id: str
    type: str
    risk_score: int = Field(ge=0, le=100)
    risk_category: str
    indicators: list[dict[str, str]]
    explanations: list[str]
    recommended_actions: list[str]
    timestamp: datetime
    model_config = ConfigDict(from_attributes=True)


class HistoryItem(BaseModel):
    id: str
    scan_type: str
    risk_score: int
    risk_category: str
    indicators: list[Any]
    summary: str
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)


class AssistantRequest(BaseModel):
    message: str = Field(min_length=1, max_length=5000)


class LearningProgress(BaseModel):
    completed_lessons: list[str] = Field(default_factory=list)
    quiz_results: list[dict[str, Any]] = Field(default_factory=list)
