"""Shared utilities to read Jira / Confluence Data Center (read-only).

Configuration, lowest to highest precedence:
  1. qa-design/config/atlassian.env   non-secret URLs, filters, versions (tracked)
  2. <repo root>/.env                 local only, gitignored: JIRA_PERSONAL_TOKEN, CONFLUENCE_PERSONAL_TOKEN
  3. process environment variables

Adapted from qa-harness tools/common/atlassian.py: the macOS Keychain lookup is replaced by the local .env file.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

QA_ROOT = Path(__file__).resolve().parents[2]  # qa-design/
REPO_ROOT = QA_ROOT.parent
CONFIG_FILE = QA_ROOT / "config" / "atlassian.env"
DOTENV_FILE = REPO_ROOT / ".env"

TOKEN_VARS = {"jira": "JIRA_PERSONAL_TOKEN", "confluence": "CONFLUENCE_PERSONAL_TOKEN"}


def _parse_env_file(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    if not path.is_file():
        return values
    for line in path.read_text(encoding="utf-8-sig").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip().removeprefix("export ").strip()
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        values[key] = value
    return values


def load_config() -> dict[str, str]:
    config = _parse_env_file(CONFIG_FILE)
    for key, value in _parse_env_file(DOTENV_FILE).items():
        if value:
            config[key] = value
    for key in set(config) | set(TOKEN_VARS.values()):
        if os.environ.get(key):
            config[key] = os.environ[key]
    return config


def get_pat(product: str, config: dict[str, str] | None = None) -> str:
    """product: 'jira' or 'confluence'."""
    config = load_config() if config is None else config
    return config.get(TOKEN_VARS[product], "")


def exit_with_error(message: str, code: int = 2) -> None:
    print(f"error: {message}", file=sys.stderr)
    sys.exit(code)


def client(product: str):
    import httpx  # only needed by tools that call the REST API

    config = load_config()
    url_key = "JIRA_URL" if product == "jira" else "CONFLUENCE_URL"
    url = config.get(url_key, "").rstrip("/")
    if not url:
        exit_with_error(f"{url_key} is empty in qa-design/config/atlassian.env")
    pat = get_pat(product, config)
    if not pat:
        exit_with_error(f"{TOKEN_VARS[product]} is not set: add it to the repo-root .env (see .env.example)")
    verify_ssl = config.get(f"{url_key.split('_')[0]}_SSL_VERIFY", "true").lower() != "false"
    return httpx.Client(
        base_url=url,
        headers={"Authorization": f"Bearer {pat}", "Accept": "application/json"},
        verify=verify_ssl,
        timeout=30.0,
        follow_redirects=True,
    )
