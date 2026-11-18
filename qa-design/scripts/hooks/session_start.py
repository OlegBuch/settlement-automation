"""SessionStart hook: injects the qa-design memory index into the session context.

Port of qa-harness scripts/hooks/session-start.sh to Python (runs the same on Windows and macOS/Linux).
Never fails the session: any error prints nothing and exits 0.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

QA_ROOT = Path(__file__).resolve().parents[2]
INDEX = QA_ROOT / "knowledge" / "index.md"
LIMIT = 150


def build() -> str:
    lines = ["## qa-design memory (qa-design/knowledge/index.md)"]
    cards = []
    if INDEX.is_file():
        cards = [l for l in INDEX.read_text(encoding="utf-8").splitlines() if re.match(r"^- \[", l)]
    if cards:
        lines += cards[:LIMIT]
        if len(cards) > LIMIT:
            lines.append(f"(... {len(cards) - LIMIT} more cards: grep qa-design/knowledge/)")
    else:
        lines.append("No cards yet.")
    lines += ["", "Before designing or reviewing tests for a ticket: grep qa-design/knowledge/ for the key, "
              "components and endpoints; when a design is finished, run the close-session skill."]
    return "\n".join(lines)


def main() -> None:
    try:
        text = build()
    except Exception:  # noqa: BLE001
        return
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": text}}))


if __name__ == "__main__":
    main()
    sys.exit(0)
