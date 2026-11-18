"""Starts the read-only mcp-atlassian server for Jira / Confluence Data Center.

Invoked by the repo-root .mcp.json; no need to run it by hand. Cross-platform replacement for qa-harness
scripts/run-mcp-atlassian.sh: tokens come from the repo-root .env (gitignored) instead of the macOS Keychain.

Only read tools are enabled and READ_ONLY_MODE=true. There is deliberately no write mode in this repo.
Warnings go to stderr so they never corrupt the MCP protocol on stdout.
"""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from common.atlassian import load_config  # noqa: E402

READ_TOOLS = [
    # Jira
    "jira_get_issue", "jira_search", "jira_get_issue_images", "jira_download_attachments",
    "jira_batch_get_changelogs", "jira_search_fields", "jira_get_link_types", "jira_get_project_issue_types",
    # Confluence
    "confluence_get_page", "confluence_search", "confluence_get_page_children", "confluence_get_space_page_tree",
    "confluence_get_page_images", "confluence_get_attachments", "confluence_download_attachment",
    "confluence_download_content_attachments", "confluence_get_page_history", "confluence_get_page_diff",
    "confluence_get_comments", "confluence_get_inline_comments", "confluence_get_labels",
]

PASS_THROUGH = [
    "JIRA_URL", "CONFLUENCE_URL", "JIRA_PROJECTS_FILTER", "CONFLUENCE_SPACES_FILTER",
    "JIRA_SSL_VERIFY", "CONFLUENCE_SSL_VERIFY", "JIRA_PERSONAL_TOKEN", "CONFLUENCE_PERSONAL_TOKEN",
]


def warn(message: str) -> None:
    print(f"[run_mcp_atlassian] {message}", file=sys.stderr)


def main() -> int:
    if len(sys.argv) > 1 and sys.argv[1] != "read":
        warn(f"unsupported mode {sys.argv[1]!r}: this repo only runs the read-only server")
        return 2

    config = load_config()
    env = dict(os.environ)
    for key in PASS_THROUGH:
        if config.get(key):
            env[key] = config[key]
        else:
            env.pop(key, None)

    if not config.get("JIRA_PERSONAL_TOKEN"):
        warn("JIRA_PERSONAL_TOKEN missing in .env: Jira tools disabled")
        env.pop("JIRA_URL", None)
        env.pop("JIRA_PROJECTS_FILTER", None)
    if not config.get("CONFLUENCE_PERSONAL_TOKEN"):
        warn("CONFLUENCE_PERSONAL_TOKEN missing in .env: Confluence tools disabled")
        env.pop("CONFLUENCE_URL", None)

    env["READ_ONLY_MODE"] = "true"
    env["TOOLSETS"] = "all"
    env["ENABLED_TOOLS"] = ",".join(READ_TOOLS)

    uvx = shutil.which("uvx") or str(Path.home() / ".local" / "bin" / ("uvx.exe" if os.name == "nt" else "uvx"))
    version = config.get("MCP_ATLASSIAN_VERSION", "0.23.1")
    # subprocess instead of exec: os.exec* on Windows detaches stdio from the MCP client.
    return subprocess.call([uvx, f"mcp-atlassian@{version}"], env=env)


if __name__ == "__main__":
    sys.exit(main())
