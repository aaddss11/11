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
