# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, check the repo first.
- For small, reversible choices, state the assumption and proceed. Ask only when the ambiguity affects requirements, security, or data loss.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something unclear meets that bar, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

Stop looping when the same failure repeats or the environment blocks progress. Report the cause and what remains unverified. Never describe a check you didn't run as passing.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

## Cross-checking with GPT (Codex CLI)

When the user asks for a GPT/Codex opinion or cross-check, run the Codex CLI and compare its answer with your own:

```
codex exec -s read-only "<question, with the relevant files or diff named>"
```

- `-s read-only`: blocks file writes only. Codex can still run commands and use network/MCP tools, and the files it reads are sent to the model, so don't point it at secrets.
- Codex uses the user's ChatGPT login (`codex login`), not an API key. If it reports not being logged in, tell the user to run `codex login`; never fall back to an API key.
- Report where Codex and you agree and disagree; don't just paste its output.

## Reference apps (awesome-llm-apps)

When the user asks to build an LLM app or agent, first look in the `awesome-llm-apps/` submodule (run `git submodule update --init` if it is empty) for similar apps, and tell the user which ones you found and what you'd reuse from them before writing code.

- Search by goal: `rag_tutorials/` (Q&A over documents), `starter_ai_agents/` and `advanced_ai_agents/` (agents), `advanced_ai_agents/multi_agent_apps/` (agent teams), `mcp_ai_agents/` (MCP), `voice_ai_agents/` (voice).
- Check each app's `requirements.txt` for its provider (openai, anthropic, google-genai, ollama) and say which API key it needs.
- Treat them as reference code: copy only what is needed into this repo, adapted to the task, rather than importing from the submodule.

## Basic Memory

The `basic-memory` MCP server stores notes as Markdown in `memory/`, and a Stop hook commits them onto `main` and pushes `main` after each response, whatever branch is checked out.

- On other branches, `memory/` changes stay uncommitted in the working tree but are already on `main`. The Stop hook hides them from `git status` (`.git/info/exclude` and `skip-worktree`): don't commit them to the branch, and if they block a merge or pull, run `git ls-files -z memory | xargs -0 git update-index --no-skip-worktree`, then discard them (`git checkout -- memory`, delete untracked notes) first.
- The Stop hook only adds and updates notes on `main`; it never deletes one, so a note deleted locally stays on `main` until removed there by hand.
- When another session changed the same note on `main`, the hook merges both versions line by line (`git merge-file --union`) and writes the result back to the local note, so lines from both sessions are kept.
- Without being asked, save a note with `write_note` when you learn something worth keeping across sessions: a decision and its reason, a user preference, a project fact that took effort to find. Don't save routine task chatter or anything secret.
- Before starting work, `search_notes` for related notes and build on them; update an existing note rather than writing a duplicate.
