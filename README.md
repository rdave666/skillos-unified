# SkillOS — Pure Markdown Operating System (UNFROZEN - Universal)

> **UNFROZEN — 2026-09-16.** Previously frozen 2026-08-01, now active as universal provider-agnostic OS.
> Original frozen note: idea carried forward in ai-os as ai-flows, but this repo is now unfrozen and maintained as universal version.
> Universal runtime: `.agents/` + `.skillos/agents/` + `.claude/agents/`, 54 agents, 108 external skills, no Claude lock.

<p align="center">
  <img src="docs/img/skillos.jpg" alt="A document that becomes executable partway down" width="100%">
</p>

SkillOS is a proof-of-concept OS where every component [agents, tools, memory, orchestration] is defined entirely in markdown documents. No code compilation. No complex APIs. Just markdown that any LLM interprets at runtime to become a composable problem-solving system.

> Evolved from [LLMos](https://github.com/EvolvingAgentsLabs/llmos) — testing Skills as basic programs.
> **Now universal:** Works with Claude, OpenAI, Gemini, Qwen, Gemma, or local mode (no API key).

## Quick Start - Universal (No Claude needed)

```bash
# 1. Clone
git clone https://github.com/EvolvingAgentsLabs/skillos.git && cd skillos

# 2. Universal setup (not Claude-locked)
./setup_universal.sh          # creates .agents/, .skillos/agents/, .skillos/skills/
./install_universal_agents.sh # installs 113 skills from 4 repos

# 3. Check status
python3 universal_runtime.py status

# 4. Daily useful
bash daily.sh
# or
python3 daily_briefing.py
```

### Original Claude Setup (still works)

```bash
./setup_agents.sh    # Mac/Linux
.\setup_agents.ps1   # Windows
claude --dangerously-skip-permissions
boot skillos
```

Requires: Python 3.11+, Git. Optional: Claude Code CLI, Node.js 18+.

---

## Runtimes - Now Universal

### Option 1: Universal Runtime (NEW - Recommended for daily use)
**Best for:** Daily useful, no Claude lock, works offline

```bash
python3 universal_runtime.py status
python3 universal_runtime.py agents
python3 universal_runtime.py repl
python3 universal_runtime.py execute "Create a tutorial on chaos theory"
bash daily.sh
```

No API key needed for local mode. With keys:
```bash
export OPENAI_API_KEY=...
export GEMINI_API_KEY=...
export OPENROUTER_API_KEY=...  # for Qwen/Gemma free tier
python3 universal_runtime.py execute "Your goal"
```

### Option 2: SkillOS Terminal (Claude)
**Best for:** Full Unix-like experience with Claude

```bash
./skillos.sh
# Or directly:
python3 skillos.py
```

```
skillos$ Create a tutorial on chaos theory
skillos$ Monitor tech news and generate a briefing
skillos$ help
```

> Requires: Python 3.11+, `rich`, Claude Code CLI

### Option 3: Multi-Provider (Qwen/Gemini/Gemma)
**Best for:** Lightweight, free-tier

```bash
pip install openai python-dotenv
python3 universal_runtime.py execute "Your goal"  # auto picks best provider
```

---

## Core Concept

Everything is either an **Agent** (decision maker) or a **Tool** (executor), defined in markdown:

```markdown
---
name: example-agent
type: agent
description: An agent that solves problems
tools: Read, Write, WebFetch
extends: orchestration/base
---

# ExampleAgent
You are a research specialist. Given a topic, you...
```

Skills are organized in a **3-level hierarchy** (Domain → Family → Skill) with a 4-step lazy loading protocol that reduces routing-phase token consumption by ~61% versus a flat registry.

```
Domain → Family → Skill
──────────────────────────────────────────────────
orchestration/  core/           system-agent
                ingress/        intent-compiler-agent
                egress/         human-renderer-agent
memory/         analysis/       memory-analysis-agent
                consolidation/  memory-consolidation-agent
                query/          query-memory-tool
planning/       hwm/            hwm-planner-agent      ← HWM paper (arXiv:2604.03208)
                flat/           flat-planner-agent
robot/          navigation/     roclaw-navigation-agent
                scene/          roclaw-scene-analysis-agent
                dream/          roclaw-dream-agent
dialects/       compiler/       dialect-compiler-agent
                expander/       dialect-expander-agent
                registry/       dialect-registry-tool
validation/     system/         validation-agent
recovery/       error/          error-recovery-agent
project/        scaffold/       project-scaffold-tool
                packages/       skill-package-manager-tool
auto-improve/   usage-tracker/  usage-tracker (tool)
                meta-agent/     auto-improve-meta-agent
```

Universal adds:
```
.agents/                           # 49 universal agents (NEW)
.sklillos/agents/                  # 49 universal
.claude/agents/                    # 54 Claude compat
.sklillos/skills/                  # 108 external skills
.sklillos-cache/                   # 4 repos, 113 SKILL.md
```

---

## Daily Useful (NEW)

```bash
bash daily.sh
# Creates projects/Project_daily/output/YYYY-MM-DD.md with:
# - Hacker News Top 5 (live API)
# - GitHub Trending Top 3 (live API)
# - Tasks checklist + evening review
# No LLM, no API key needed
```

---

## Key Features

- **Pure Markdown** — No code compilation. The LLM is the interpreter.
- **Universal** — Works with any provider, not Claude-locked (NEW)
- **Daily Useful** — `daily.sh` + `daily_briefing.py` for real daily use (NEW)
- **HWM Planning** — Two-level hierarchical planner
- **Hierarchical Skills** — Domain → Family → Skill taxonomy
- **Token Efficient** — 61% reduction + 14 dialects 50-99%
- **54 Agents, 108 Skills** — Ready to use
- **Memory System** — Every execution improves future runs
- **Self-Optimization** — Auto-improve loop

See docs/ for full docs, README_UNIVERSAL.md for universal guide.

## License

Apache License 2.0 — see LICENSE

*Built by Evolving Agents Labs Initiative — Unfrozen 2026-09-16 as universal version*
