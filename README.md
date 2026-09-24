# SkillOS Unified — Pure Markdown OS + Mega-Tron Router

> **This is the unified fork: [`rdave666/skillos-unified`](https://github.com/rdave666/skillos-unified)** (private).
> Unfrozen 2026-09-16 from [EvolvingAgentsLabs/skillos](https://github.com/EvolvingAgentsLabs/skillos) (the original, frozen 2026-08-01, kept here as upstream for history + attribution).
> Universal & provider-agnostic: Claude, OpenAI, Gemini, Qwen, Gemma, or local mode — no Claude lock.
> Ships with **mega-tron router** integration and **one meta-router skill** (`skill-router-agent`) that picks the right skill(s) for your task wording out of 170+.

<p align="center">
  <img src="docs/img/skillos.jpg" alt="A document that becomes executable partway down" width="100%">
</p>

SkillOS is a proof-of-concept OS where every component — agents, tools, memory, orchestration — is defined entirely in markdown documents. No code compilation. No complex APIs. Just markdown that any LLM interprets at runtime to become a composable problem-solving system.

> Evolved from [LLMos](https://github.com/EvolvingAgentsLabs/llmos) — testing Skills as basic programs.

## Install (fresh Linux machine, one command)

```bash
# This repo is PRIVATE — authenticate first (or use SSH):
gh auth login          # or: git config credential.helper / fine-grained PAT

git clone https://github.com/rdave666/skillos-unified.git
cd skillos-unified
bash install.sh
```

`install.sh` runs everything: prereqs (`git`, `python3.11+`, `uv`) → universal agent dirs → 4 external skill repos (anthropics, huggingface, openai, google-ai-edge) → mega-tron install + unified pool → router skill + `daily_briefing.py` → verification.

## Use it (task in → output out)

```bash
# status: agents / skills / best provider
python3 universal_runtime.py status

# your task:
python3 universal_runtime.py execute "Create a tutorial on chaos theory with Python examples"
# → creates projects/Project_<goal>/ with input/, output/, memory/, state/

# interactive
python3 universal_runtime.py repl

# daily useful (real HN + GitHub trending, no LLM, no API key)
python3 daily_briefing.py
```

With keys (optional — better output):
```bash
export OPENAI_API_KEY=...     # or GEMINI_API_KEY / OPENROUTER_API_KEY
python3 universal_runtime.py execute "Your goal"
```

Original Claude terminal still works: `./skillos.sh` → `skillos$ <your goal>`.

## The Router — ONE skill to rule them all

```
.agents/skill-router-agent.md        # meta-router: indexes ALL skills dynamically,
                                     # scores task wording vs skill descriptions,
                                     # loads only top 2-3 (~150 tok vs ~8k)
```

- **Dynamic index:** Glob-scans `.agents/`, `.skillos/skills/`, `system/skills/`, `.skillos-cache/` every run — new skills auto-discovered, no code change
- **Skills + plugins:** both are markdown with frontmatter, both indexed
- **Verdicts:** HELPFUL/HARMFUL/NEUTRAL logged to `.skillos/verdicts.json`; 3 failures → auto-retire
- **mega-tron (optional, installed by `install.sh`):** semantic top-K embedding router across Codex/Claude/Gemini hosts, shared master pool `~/.local/share/mega-tron/pool/skills/`, dashboard at `mega-tron dashboard` (127.0.0.1:7531)

```bash
mega-tron search "Create tutorial on chaos theory"   # top 3 skills, flat ~150 tokens
mega-tron skills sync                                 # one pool → all hosts, no drift
```

## Runtimes

| Runtime | Command | Needs |
|---|---|---|
| **Universal (recommended)** | `python3 universal_runtime.py execute "<goal>"` | Python 3.11+, works offline in local mode |
| **Mega-tron router** | `mega-tron search / skills list / dashboard` | `install.sh` does it (Python 3.11+, uv, Linux/macOS) |
| **Claude Code** | `./skillos.sh` or `claude` + `boot skillos` | Claude CLI |
| **ChatGPT web** | attach `.agents/skill-router-agent.md` + prompts | see `PROMPT_FOR_CHATGPT_WEB.md` |
| **Codex on new machine** | paste `PROMPT_FOR_NEW_LINUX_CODEX.md` into codex | codex CLI |

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
planning/       hwm/            hwm-planner-agent
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

This fork adds:
```
.agents/              # 51 universal agents (incl. skill-router-agent)
.skillos/agents/      # 51 universal (mirror)
.claude/agents/       # 54 Claude compat
.skillos/skills/      # 108 external skills
.skillos-cache/       # 4 repos, 113 SKILL.md (regenerable, gitignored)
install.sh            # one-command unified installer
```

## Key Features

- **Pure Markdown** — No code compilation. The LLM is the interpreter.
- **Universal** — Any provider, no Claude lock
- **One-Command Install** — `install.sh` packs SkillOS + mega-tron for fresh Linux
- **Smart Routing** — `skill-router-agent` + mega-tron per-turn top-K: ~150 tokens instead of ~8k, flat cost as skills grow
- **Future-Proof Index** — new skills/plugins auto-discovered, never hardcoded
- **Daily Useful** — `daily_briefing.py`: real HN + GitHub trending into `projects/Project_daily/`
- **Hierarchical Skills** — Domain → Family → Skill taxonomy, 61% token reduction + dialects 50-99%
- **Memory System** — every execution improves future runs; verdict-based skill retirement
- **Private fork, upstream history** — full frozen-era git history preserved from [EvolvingAgentsLabs/skillos](https://github.com/EvolvingAgentsLabs/skillos)

## Docs & Prompts

- [`Boot.md`](Boot.md) — boot manifest (paste into any LLM to become SkillOS)
- [`system/skills/SkillIndex.md`](system/skills/SkillIndex.md) — skill taxonomy index
- [`UNFROZEN.md`](UNFROZEN.md) — what changed when unfreezing
- [`README_UNIVERSAL.md`](README_UNIVERSAL.md) — universal setup guide
- [`PROMPT_FOR_CHATGPT_WEB.md`](PROMPT_FOR_CHATGPT_WEB.md) — prompt to get a ChatGPT-web plan for the router
- [`PROMPT_FOR_NEW_LINUX_CODEX.md`](PROMPT_FOR_NEW_LINUX_CODEX.md) — step-by-step prompt equivalent to `install.sh`
- [`findings/`](findings/) — (local only, not committed) passive assessments

See `docs/` for full docs.

## License

Apache License 2.0 — see LICENSE

*Fork of [EvolvingAgentsLabs/skillos](https://github.com/EvolvingAgentsLabs/skillos) (Evolving Agents Labs Initiative), unfrozen 2026-09-16, unified with [mega-tron](https://github.com/mega-edo/mega-tron) router as `rdave666/skillos-unified`.*
