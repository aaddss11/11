---
title: Plugins and skills setup decisions
type: note
permalink: main/decisions/plugins-and-skills-setup-decisions
tags:
- plugins
- skills
- environment
---

# Plugins and skills setup decisions (2026-10-22/23)

- [decision] Installed Claude Code plugins superpowers (obra/superpowers-marketplace), mattpocock-skills (mattpocock/skills) and andrej-karpathy-skills (multica-ai/andrej-karpathy-skills) next to ecc, project scope (PR #6). .claude/hooks/session-start.sh installs them one after another, not as separate hooks, because hooks on the same event run in parallel and would race writing .claude/settings.json.
- [fact] 2026-10-23: a fresh-clone run of the session-start hook with an empty HOME installed all 4 plugins and fetched the submodule in ~22 s, exit 0.
- [decision] Copied 7 agent skills from Shubhamsaboo/awesome-llm-apps agent_skills/ (upstream 6c16b23) into .claude/skills/, with the upstream Apache-2.0 license as .claude/skills/LICENSE-awesome-llm-apps (PR #7).
- [decision] Removed advisor-orchestrator-worker (PR #19) at the user's request: it runs the agy CLI with --dangerously-skip-permissions and sends task content to the Gemini and Anthropic APIs. 6 skills remain: commit-archaeologist, dependency-doctor, first-reader, project-graveyard, scope-creep-detector, thinking-out-loud.
- [decision] awesome-llm-apps is a git submodule (PR #8), not copied files: copying would add 1,984 files / 94 MB. The session-start hook runs `git submodule update --init --depth 1` (94 MB instead of 312 MB with history, PR #18).
- [preference] User wants app-building work to start from similar apps in awesome-llm-apps; this rule is in CLAUDE.md under "Reference apps" (PR #9).
- [fact] The auto mode classifier blocks Claude from editing .claude/settings.json and hook files as "Self-Modification", even after the user says yes in chat. The user ended up approving some of these edits, and edits to other config files went through.
