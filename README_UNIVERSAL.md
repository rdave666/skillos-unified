# SkillOS Universal — Provider-Agnostic Setup

**Original repo is Claude-locked (copies to `.claude/agents/` and requires `claude` CLI). This universal setup removes that lock.**

## What was changed to make it universal

### 1. New universal directories (not Claude-specific)
- `.agents/` — **NEW, universal** — provider-agnostic agent discovery (was only `.claude/agents/`)
- `.skillos/agents/` — universal agents
- `.skillos/skills/` — universal skills from external repos
- `.skillos-cache/` — cloned external skill repos
- `.skillos/config.json` — universal config, not Claude-locked
- `.skillos/registry.json` — registry of installed repos

Original setup only used `.claude/agents/` which requires Claude Code. Universal setup copies to **all three**: `.agents/`, `.skillos/agents/`, `.claude/agents/` for backward compat.

### 2. New universal runtime (no Claude required)
- `universal_runtime.py` — provider-agnostic runtime
  - Discovers agents from `.agents`, `.skillos/agents`, `.claude/agents`, `components/agents`
  - Discovers skills from `.skillos/skills`, `system/skills`, `.skillos-cache/**/SKILL.md`
  - Checks providers: claude-code, openai, gemini, openrouter (qwen/gemma), local
  - Works in local mode without any API key (creates project scaffolding)
  - REPL: `python3 universal_runtime.py repl`

- `skillos_universal.py` — lightweight status checker

Original `skillos.py` does:
```python
cmd = ["claude", "-p", ...]  # hard requires claude CLI
```
Universal runtime does NOT call `claude`, uses Python file I/O and optional LLM.

### 3. External repos needed & installed

From `system/sources.list` (4 official repos):

| Repo | Status | Skills | Path | Note |
|------|--------|--------|------|------|
| `anthropics/skills` | cloned | 20 | `.skillos-cache/aafebdd99c3d93bce27447b3bab75c16` | Anthropic official skills |
| `huggingface/skills` | cloned | 26 | `.skillos-cache/b05e288abc1617d90cc880ab10b853b0` | HF skills |
| `openai/skills` | cloned-deprecated | 44 | `.skillos-cache/ceac4d14d257b71828b21d6b9b10e5f4` | Deprecated, says use openai/plugins |
| `google-ai-edge/gallery` | cloned | 23 | `.skillos-cache/c5111dc180304308df93c8a928175c2f` | Android gallery skills |

**Total: 113 SKILL.md files cached, 108 installed to `.skillos/skills/` with unique names**

Installation done via:
- `setup_universal.sh` — clones all repos from sources.list, handles alt paths (skills/, .curated/, .system/, etc.)
- `install_universal_agents.sh` — finds all SKILL.md recursively, copies to universal locations with safe names like `anthropics_skills_docx_SKILL.md`

### 4. How to use universally

```bash
# One-time setup (already done)
./setup_universal.sh
./install_universal_agents.sh

# Check status (no Claude needed)
python3 universal_runtime.py status
python3 skillos_universal.py

# List agents (universal)
python3 universal_runtime.py agents
python3 universal_runtime.py list

# List skills
python3 universal_runtime.py skills

# Execute goal locally (no LLM)
python3 universal_runtime.py execute "Create a tutorial on chaos theory"

# REPL (universal, no Claude)
python3 universal_runtime.py repl

# Original Claude mode (if you have claude CLI)
./skillos.sh
# or
python3 skillos.py
```

### 5. Provider options (universal)

Set env vars to enable LLM providers:

```bash
# OpenAI
export OPENAI_API_KEY=sk-...

# Gemini
export GEMINI_API_KEY=...

# OpenRouter (Qwen, Gemma free tier)
export OPENROUTER_API_KEY=sk-or-...

# Then run with any provider
python3 universal_runtime.py execute "Your goal"
```

The runtime auto-detects best available:
- claude-code if `claude` CLI exists
- openai if OPENAI_API_KEY + openai lib
- gemini if GEMINI_API_KEY
- openrouter if OPENROUTER_API_KEY
- local otherwise (scaffolding only)

### 6. File structure after universal setup

```
skillos/
├── .agents/                          # NEW — universal, 49 agents
├── .claude/agents/                   # original, 54 agents (backward compat)
├── .skillos/
│   ├── agents/                       # universal, 49 agents
│   ├── skills/                       # NEW — 108 external skills
│   ├── config.json                   # universal config
│   └── registry.json                 # repo registry
├── .skillos-cache/                   # 4 cloned repos, 113 SKILL.md
│   ├── aafebdd99c3d93bce27447b3bab75c16/  # anthropics/skills
│   ├── b05e288abc1617d90cc880ab10b853b0/  # huggingface/skills
│   ├── ceac4d14d257b71828b21d6b9b10e5f4/  # openai/skills (deprecated)
│   └── c5111dc180304308df93c8a928175c2f/  # google-ai-edge/gallery
├── components/agents/                # 4 shared agents
├── system/skills/                    # 80 local skills (hierarchical)
├── projects/                         # 5+ projects
├── universal_runtime.py              # NEW — universal runtime
├── skillos_universal.py              # NEW — status checker
├── setup_universal.sh                # NEW — universal setup
├── install_universal_agents.sh       # NEW — external installer
└── setup_agents.sh                   # original Claude setup
```

### 7. Why original was Claude-locked

- `setup_agents.sh` only writes to `.claude/agents/` — Claude Code discovery dir
- `skillos.py` hard-codes `cmd = ["claude", "-p", ...]` — requires Claude CLI
- `Boot.md` says "Powered by Claude Code Runtime"
- No fallback if `claude` missing

Universal fix:
- Write to `.agents/` + `.skillos/agents/` + `.claude/agents/` (all three)
- `universal_runtime.py` never calls `claude`, uses Python file ops
- `permission_policy.py` already provider-agnostic (PathPolicy, PermissionPolicy)
- Config declares `"claude_optional": true, "universal": true`

### 8. Next steps

- Add more sources to `system/sources.list` if needed:
  ```
  github  EvolvingAgentsLabs/skillos-community-skills  main  skills/
  github  openclaw/skills  main  skills/
  ```
- Then re-run `./setup_universal.sh` or `./install_universal_agents.sh`
- For full LLM execution, set API keys and use `universal_runtime.py` or original `agent_runtime.py` if you restore it from ai-os repo
- Active development moved to this fork: [rdave666/skillos-unified](https://github.com/rdave666/skillos-unified) (unified + mega-tron router). Upstream `ai-os`/`ai-flows` and frozen [EvolvingAgentsLabs/skillos](https://github.com/EvolvingAgentsLabs/skillos) kept for history

## Verification

```bash
python3 universal_runtime.py status
# Should show:
# Agents: 54, Skills: 170, Cache repos: 4, Best: local (or your provider)
```
