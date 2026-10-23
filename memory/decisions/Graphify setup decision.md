---
title: Graphify setup decision
type: note
permalink: main/decisions/graphify-setup-decision
tags:
- graphify
- ponytail
- plugins
---

- [decision] Graphify (Graphify-Labs/graphify, PyPI `graphifyy`) ships no Claude Code plugin/marketplace; installed as project skill via `graphify install --project` (.claude/skills/graphify/), CLI installed by .claude/hooks/session-start.sh (`uv tool install graphifyy`).
- [decision] Skipped graphify's always-on mode (PreToolUse `graphify hook-guard` hooks + CLAUDE.md section): no graph built yet, and the hooks error on every tool call where the CLI is missing. Enable with `graphify claude install` after building a graph if wanted.
- [fact] Ponytail is installed as plugin ponytail@ponytail (PR aaddss11/11#27); auto-activation at session start confirmed working.