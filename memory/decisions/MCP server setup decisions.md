---
title: MCP server setup decisions
type: note
permalink: main/decisions/mcp-server-setup-decisions
tags:
- mcp
- environment
---

# MCP server setup decisions (2026-10-22, PR #14)

- [decision] Removed brave-search from .mcp.json: Brave Search API dropped its free tier in early 2026 (card required, $5/month credit then billed). Use built-in WebSearch instead.
- [decision] Added project-level chrome-devtools MCP pointing at /opt/pw-browsers/chromium with --headless --isolated --no-sandbox, because the ecc plugin's version looks for Google Chrome (absent) and Chrome won't run as root in the cloud container.
- [fact] Cloud environment network policy blocks context7.com, api.search.brave.com, duckduckgo.com, bing.com, google.com (proxy 403). Free scraping-based search MCPs (e.g. lennney/agent-search-mcp) need those domains allowlisted first.
- [todo] User-side: allow context7.com in environment Allowed domains; set YOUTUBE_API_KEY env var. gitlab plugin needs auth.
- [fact] basic-memory semantic search fails (embedding model can't download); use search_type="text".

- [fact] 2026-10-22: user allowed context7.com in the environment (desktop app: right panel 환경 → 기본 → gear icon). Network change applied to the running session immediately.
- [decision] context7-mcp 4.4.4 fails TLS behind the session proxy because it passes the NODE_EXTRA_CA_CERTS bundle as one CA string. Fix in .mcp.json (PR #15): env NODE_EXTRA_CA_CERTS="" and NODE_USE_SYSTEM_CA=1 for context7 only.
- [fact] Anonymous context7 quota is exhausted on the shared egress IP; needs a free key, best stored as a network secret for context7.com (Authorization: Bearer <key>).
- [fact] YouTube key must be an environment variable, not a network secret: zubeid-youtube-mcp-server passes it to googleapis as the key= query param, which a header secret can't supply.
- [fact] basic-memory 0.24.0 crash detail: ImportError get_flat_dependant (removed in FastAPI 0.143.0+; 0.140.0 still works). Running a newer basic-memory once migrates .basic-memory/memory.db (alembic 0042), after which 0.22.1 fails with "Can't locate revision '0042'"; moving the config dir aside fixes it.
- [fact] 2026-10-23: all repo MCP servers verified working in cloud sessions (context7, youtube, basic-memory, chrome-devtools, filesystem, sequential-thinking). GitLab plugin auth comes from claude.ai settings, not this repo.
- [decision] PR #25: the memory Stop hook three-way merges each note against main (git merge-file --union, base recorded in .git/memory-synced) so concurrent edits from two sessions keep both sides.
- [fact] 2026-10-23: unpinned `uvx basic-memory` resolved 0.24.0 with FastAPI 0.161.1. The server exits on startup with ImportError get_flat_dependant (FastAPI 0.143.0+ removed it; 0.140.0 still works). main pins basic-memory==0.22.1 (PR #21) instead.
- [fact] Running a newer basic-memory once migrates the local index .basic-memory/memory.db (alembic revision 0042), after which 0.22.1 fails with "Can't locate revision '0042'". Fix: move .basic-memory/ aside (gitignored, rebuilt from memory/*.md).
- [fact] 2026-10-23: YouTube MCP works with YOUTUBE_API_KEY as an environment variable (zubeid-youtube-mcp-server passes it to googleapis as the key= query param, so a header network secret would not work). Env var changes reach a session only after its VM restarts or in a new session.
- [decision] basic-memory pinned to 0.22.1 (PR #21, from the Basic Memory session): 0.24.0 crashes on start with an ImportError against fastapi 0.161.1. Semantic search off (PR #17) because huggingface.co is blocked.
- [fact] As of 2026-10-23 all repo MCP servers verified working in cloud sessions: context7, youtube, basic-memory, chrome-devtools, filesystem, sequential-thinking. GitLab plugin needs auth from claude.ai settings (not installed from this repo).
