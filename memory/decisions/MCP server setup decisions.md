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
- [todo] User-side: gitlab plugin needs auth.
- [fact] 2026-10-23: user set YOUTUBE_API_KEY as an environment variable (Google Cloud key restricted to YouTube Data API v3); youtube MCP search works.
- [decision] basic-memory semantic search fails (embedding model can't download), so .mcp.json sets BASIC_MEMORY_SEMANTIC_SEARCH_ENABLED=false (PR #17) and plain search_notes runs text search. PR #21 pinned basic-memory==0.22.1 (0.24.0 crashes at startup) and made the notes path absolute ($(pwd)/memory) so notes arriving via git are indexed. PR #22 moved BASIC_MEMORY_CONFIG_DIR to .basic-memory/v2: BASIC_MEMORY_HOME only seeds a new config, so an older .basic-memory/ kept the relative path in config and DB and nothing got indexed.

- [fact] 2026-10-22: user allowed context7.com in the environment (desktop app: right panel 환경 → 기본 → gear icon). Network change applied to the running session immediately.
- [decision] context7-mcp 4.4.4 fails TLS behind the session proxy because it passes the NODE_EXTRA_CA_CERTS bundle as one CA string. Fix in .mcp.json (PR #15): env NODE_EXTRA_CA_CERTS="" and NODE_USE_SYSTEM_CA=1 for context7 only.
- [fact] Anonymous context7 quota is exhausted on the shared egress IP; needs a free key, best stored as a network secret for context7.com (Authorization: Bearer <key>).
- [fact] 2026-10-23: unpinned `uvx basic-memory` resolved 0.24.0 with FastAPI 0.161.1. The server exits on startup with ImportError get_flat_dependant (FastAPI 0.143.0+ removed it; 0.140.0 still works). main pins basic-memory==0.22.1 (PR #21) instead.
- [fact] Running a newer basic-memory once migrates the local index .basic-memory/memory.db (alembic revision 0042), after which 0.22.1 fails with "Can't locate revision '0042'". Fix: move .basic-memory/ aside (gitignored, rebuilt from memory/*.md).
