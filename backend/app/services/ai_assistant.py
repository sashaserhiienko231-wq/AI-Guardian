import os

import httpx


class AssistantProvider:
    def chat(self, message: str) -> dict:
        raise NotImplementedError


class LocalAssistant(AssistantProvider):
    def chat(self, message: str) -> dict:
        text = message.lower()
        if any(word in text for word in ("phish", "фіш", "шахрай")):
            answer = "Phishing tries to create urgency or imitate a trusted organization. Verify the sender through an official channel."
        elif any(word in text for word in ("url", "посил", "link")):
            answer = "Inspect the hostname and scheme. HTTPS proves encryption, not legitimacy."
        elif any(word in text for word in ("password", "парол")):
            answer = "Use a unique passphrase of at least 16 characters and a reputable password manager."
        else:
            answer = "I can explain phishing, suspicious links, password safety, QR codes, and security reports."
        return {"answer": answer, "provider": "local", "ai_generated": True, "verified": False}


class OllamaAssistant(AssistantProvider):
    def __init__(self) -> None:
        self.base_url = os.getenv("OLLAMA_BASE_URL", "http://127.0.0.1:11434")
        self.model = os.getenv("OLLAMA_MODEL", "llama3.2")

    def status(self) -> dict:
        try:
            response = httpx.get(f"{self.base_url.rstrip('/')}/api/tags",
                                 timeout=float(os.getenv("AI_TIMEOUT_SECONDS", "10")))
            response.raise_for_status()
            models = [item["name"] for item in response.json().get("models", [])]
            return {"provider": "ollama", "available": True, "models": models, "selected_model": self.model}
        except (httpx.HTTPError, httpx.TimeoutException, ValueError):
            return {"provider": "ollama", "available": False, "models": [], "selected_model": self.model}

    def chat(self, message: str) -> dict:
        try:
            response = httpx.post(
                f"{self.base_url.rstrip('/')}/api/generate",
                json={"model": self.model, "prompt": message, "stream": False},
                timeout=float(os.getenv("AI_TIMEOUT_SECONDS", "10")),
            )
            response.raise_for_status()
            return {"answer": response.json().get("response", ""), "provider": "ollama", "ai_generated": True, "verified": False}
        except (httpx.HTTPError, httpx.TimeoutException, ValueError) as exc:
            raise RuntimeError("AI provider is unavailable") from exc


class OpenAIAssistant(AssistantProvider):
    def __init__(self) -> None:
        self.api_key = os.getenv("OPENAI_API_KEY")
        self.model = os.getenv("OPENAI_MODEL", "gpt-4o-mini")

    def chat(self, message: str) -> dict:
        if not self.api_key:
            raise RuntimeError("OpenAI API key is not configured")
        try:
            response = httpx.post(
                "https://api.openai.com/v1/chat/completions",
                headers={"Authorization": f"Bearer {self.api_key}", "Content-Type": "application/json"},
                json={"model": self.model, "messages": [{"role": "user", "content": message}], "temperature": 0.2},
                timeout=float(os.getenv("AI_TIMEOUT_SECONDS", "10")),
            )
            response.raise_for_status()
            answer = response.json()["choices"][0]["message"]["content"]
            return {"answer": answer, "provider": "openai", "ai_generated": True, "verified": False}
        except (httpx.HTTPError, httpx.TimeoutException, KeyError, ValueError) as exc:
            raise RuntimeError("AI provider is unavailable") from exc


def get_assistant_provider() -> AssistantProvider:
    provider = os.getenv("AI_PROVIDER", "local").lower()
    if provider == "ollama":
        return OllamaAssistant()
    if provider == "openai":
        return OpenAIAssistant()
    return LocalAssistant()
