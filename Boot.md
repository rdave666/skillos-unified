---
name: boot
type: skill
priority: 0
description: SkillOS boot manifest — every agent and runtime MUST read this first before any execution
runtimes:
  - claude-code
  - qwen
  - codex
  - any-llm-runtime
  - universal
---

# SkillOS Boot

> **UNFROZEN 2026-09-16 - Universal.** Previously frozen 2026-08-01, now active universal OS.
> This is the first skill loaded by every SkillOS-compatible runtime.

## Banner

```
   _____ __   _ ____             ____  _____
  / ___// /__(_) / /            / __ \/ ___/
  \__ \/ //_/ / / /   ______   / / / /\__ \
 ___/ / ,< / / / /   /_____/  / /_/ /___/ /
/____/_/|_/_/_/_/              \____//____/

  Pure Markdown Operating System v2.0 - UNFROZEN Universal
  Powered by Universal Runtime - Claude, OpenAI, Gemini, Local
```

## Boot Checklist

Every runtime MUST complete these steps before processing any user command:

1. **Read this file** (`Boot.md`) — you are here
2. **Verify working directory** — confirm you are running from the SkillOS root
3. **Load Skill Index** — read `system/skills/SkillIndex.md` for skill routing
4. **Check agent discovery** — scan `.agents/` + `.skillos/agents/` + `.claude/agents/` for available agents (universal, not just Claude)
5. **Initialize project structure** — ensure `projects/` directory exists
6. **System ready** — report status and await first goal

## Boot Protocol by Runtime

### Universal Runtime (`universal_runtime.py`) - NEW DEFAULT
- Read `Boot.md` and render banner
- Display system status (working dir, agents 54, skills 170, providers)
- Works offline, no API key needed for local mode
- With keys: OPENAI_API_KEY, GEMINI_API_KEY, OPENROUTER_API_KEY

### Claude Code (`skillos.py` terminal)
- Read `Boot.md` and render banner
- Display system status
- Start scheduler background thread
- Invoke `boot skillos` to initialize session

### Any LLM Runtime / Codex / External Agent
- Treat `Boot.md` as system manifest
- All agents and tools are defined as markdown files

## System Invariants

- Everything is markdown — agents, tools, skills are `.md` files
- No hardcoded logic — behavior emerges from LLM interpreting markdown
- Projects are isolated — each goal creates/uses `projects/[ProjectName]/`
- Memory is sacred — always log interactions
- Agents compose — complex tasks = multiple focused agents
- Universal — works with any provider, not Claude-locked

## File Locations

- `.agents/` — 49 universal agents (NEW)
- `.skillos/agents/` — 49 universal
- `.claude/agents/` — 54 Claude compat (backward compat)
- `.skillos/skills/` — 108 external skills
- `.skillos-cache/` — 4 repos, 113 SKILL.md
- `projects/` — daily projects
- `universal_runtime.py` — universal runtime (NEW)
- `daily.sh` + `daily_briefing.py` — daily useful (NEW)
