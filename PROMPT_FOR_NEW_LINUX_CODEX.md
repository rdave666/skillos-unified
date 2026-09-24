# Prompt for New Linux Machine Running Codex — Install SkillOS Unified + Mega-Tron Router

Copy-paste this entire prompt into Codex on your new Linux machine. Codex will execute it.

---

You are on a fresh Linux machine with Codex CLI installed (`codex` command works). Install SkillOS Unified + Mega-Tron Router as ONE unified system.

## Context from previous machine (what we built)

- SkillOS original was Claude-locked (only `.claude/agents/` + requires `claude` CLI). We made it universal: `.agents/` (49) + `.skillos/agents/` (49) + `.claude/agents/` (54) + `.skillos/skills/` (108) + `.skillos-cache/` (4 repos, 113 SKILL.md)
- External repos from `system/sources.list`: anthropics/skills (20), huggingface/skills (26), openai/skills (44 deprecated), google-ai-edge/gallery (23)
- Created `universal_runtime.py` (provider-agnostic, no Claude needed, local mode works offline), `daily_briefing.py` (real HN + GitHub trending, no LLM), `skill-router-agent.md` (ONE skill that routes to top 2-3 based on task wording)
- Unfrozen repo: was FROZEN 2026-08-01, now v2.0-unfrozen-universal
- Mega-tron: skill OS for Codex/Claude/Gemini, solves token leak (8.4k → 150 tokens), host isolation (one master pool + symlinks), evidence blind (HELPFUL/HARMFUL verdicts + dashboard). Requires Python 3.11+, uv, Linux/macOS only

Goal: On this new Linux machine, install BOTH as unified system where mega-tron is router in front of SkillOS universal.

## Installation Steps (execute in order)

### 0. Prerequisites check

```bash
which codex && codex --version || echo "codex not found"
which git && git --version
python3 --version  # need 3.11+
which uv || curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
df -h | head
ls -la /opt || true  # check space, use /home if /opt not writable
```

### 1. Clone SkillOS and make universal

```bash
cd ~
rm -rf skillos
git clone https://github.com/EvolvingAgentsLabs/skillos.git
cd skillos

# Unfreeze (remove frozen banner)
cat > UNFROZEN.md << 'MD'
# UNFROZEN - $(date +%Y-%m-%d)
Previously frozen 2026-08-01, now active universal
MD

# Run universal setup (not Claude-locked)
chmod +x setup_universal.sh
# If setup_universal.sh doesn't exist (fresh clone), create it:
if [ ! -f setup_universal.sh ]; then
cat > setup_universal.sh << 'EOS'
#!/bin/bash
set -e
mkdir -p .agents .claude/agents .skillos/agents .skillos/skills .skillos-cache projects
python3 -m pip install --quiet rich openai python-dotenv requests
# Tier 1: system/skills
if [ -d system/skills ]; then
  find system/skills -name "*.manifest.md" | while read m; do
    type=$(grep -m1 "^type:" "$m" | sed 's/type:[[:space:]]*//' | tr -d '\r ' || true)
    [ "$type" = "agent" ] || continue
    spec=$(grep -m1 "^full_spec:" "$m" | sed 's/full_spec:[[:space:]]*//' | tr -d '\r ' || true)
    [ -n "$spec" ] && [ -f "$spec" ] && cp "$spec" .agents/ && cp "$spec" .skillos/agents/ && cp "$spec" .claude/agents/ || true
  done
fi
[ -d components/agents ] && cp components/agents/*.md .agents/ 2>/dev/null || true
[ -d components/agents ] && cp components/agents/*.md .skillos/agents/ 2>/dev/null || true
[ -d components/agents ] && cp components/agents/*.md .claude/agents/ 2>/dev/null || true
./setup_agents.sh || true
echo "Universal setup done: .agents=$(ls .agents | wc -l) skills=$(ls .skillos/skills 2>/dev/null | wc -l)"
EOS
chmod +x setup_universal.sh
fi

bash setup_universal.sh
```

### 2. Install external skill repos (4 official)

```bash
cd ~/skillos
cat system/sources.list
# Should show:
# github anthropics/skills main skills/
# github huggingface/skills main skills/
# github openai/skills main .curated/
# github google-ai-edge/gallery main skills/

# Clone all 4
mkdir -p .skillos-cache .skillos/skills
cat > install_universal_agents.sh << 'EOS'
#!/bin/bash
set -e
CACHE=.skillos-cache
SKILLS=.skillos/skills
AGENTS=.agents
mkdir -p $CACHE $SKILLS $AGENTS .claude/agents .skillos/agents
grep "^github" system/sources.list | while read type uri branch path; do
  hash=$(echo "$uri-$branch" | md5sum | cut -d' ' -f1)
  dest="$CACHE/$hash"
  [ -d "$dest" ] || git clone --depth 1 --branch "$branch" "https://github.com/$uri.git" "$dest"
  # Find SKILL.md recursively
  find "$dest" -name "SKILL.md" | while read f; do
    name=$(basename $(dirname "$f"))
    remote=$(echo "$uri" | tr '/' '_')
    cp "$f" "$SKILLS/${remote}_${name}_SKILL.md" 2>/dev/null || true
  done
done
echo "Cached: $(find $CACHE -name SKILL.md | wc -l) skills, installed: $(ls $SKILLS | wc -l)"
ls $SKILLS | wc -l
EOS
chmod +x install_universal_agents.sh
bash install_universal_agents.sh

# Verify
ls .agents/ | wc -l  # should be ~49
ls .skillos/skills/ | wc -l  # should be ~108
find .skillos-cache -name SKILL.md | wc -l  # should be 113
```

### 3. Install Mega-Tron Router

```bash
cd ~
rm -rf mega-tron
git clone https://github.com/mega-edo/mega-tron
cd mega-tron
sh install.sh  # installs uv if missing, uv tool install mega-tron, mega-tron setup
export PATH="$HOME/.local/bin:$PATH"
mega-tron --help
mega-tron setup --profile en-quality  # English-quality = SkillRet-0.6B default, 130MB
# Or for fast: --profile en-fast (bge-small-en)
# For multilingual: --profile multilingual (bge-m3)

# Verify
mega-tron skills list | head -n 20
ls ~/.local/share/mega-tron/pool/skills/ | wc -l
```

### 4. Unify SkillOS + Mega-Tron (ONE pool)

```bash
# Promote SkillOS universal agents into mega-tron master pool
cd ~/skillos
mega-tron skills promote --all 2>&1 | head || true

# Manual unify if promote doesn't cover .agents/:
for f in .agents/*.md; do
  [ -f "$f" ] || continue
  cp "$f" ~/.local/share/mega-tron/pool/skills/ 2>/dev/null || true
done

# Sync to all hosts (Codex, Claude, Gemini, ChatGPT if installed)
mega-tron skills sync

# Verify unified
ls ~/.local/share/mega-tron/pool/skills/ | wc -l  # should be 50+
ls ~/.codex/skills/ 2>/dev/null | wc -l || echo "codex skills dir not yet"
ls ~/.claude/skills/ 2>/dev/null | wc -l || true
cat ~/.codex/hooks.json 2>/dev/null | head || true
```

### 5. Create Router Skill (ONE skill to rule them all)

```bash
cd ~/skillos
cat > .agents/skill-router-agent.md << 'MD'
---
name: skill-router-agent
type: agent
description: Meta-router - ONE skill that decides which of many available skills/plugins to use based on task wording. Indexes all skills dynamically, future-proof.
tools: Read, Glob, Grep, Write, Bash
---

# Skill Router Agent - ONE skill that routes to top 2-3

On every invocation, Glob scan .agents/*.md, .skillos/skills/*, system/skills/**/, .skillos-cache/**/SKILL.md, extract name/description, score task vs description, output JSON with selected 2-3 + reason + tokens saved. Log verdict to .skillos/verdicts.json. Never hardcode list - auto-discover new skills.
MD

cp .agents/skill-router-agent.md .claude/agents/ 2>/dev/null || true
cp .agents/skill-router-agent.md .skillos/agents/ || true

# Also create universal runtime if missing
if [ ! -f universal_runtime.py ]; then
  cat > universal_runtime.py << 'PY'
import pathlib, subprocess, os
ROOT=pathlib.Path(__file__).parent
print(f"Universal Runtime - Agents: {len(list((ROOT/'.agents').glob('*.md')))} Skills: {len(list((ROOT/'.skillos/skills').glob('*.md')))}")
PY
fi

python3 universal_runtime.py status || python3 -m pip install rich && python3 universal_runtime.py status
```

### 6. Daily Useful (optional, no LLM needed)

```bash
cd ~/skillos
cat > daily_briefing.py << 'PY'
import urllib.request, json, datetime, pathlib
ROOT=pathlib.Path(__file__).parent
OUT=ROOT/"projects"/"Project_daily"/"output"
OUT.mkdir(parents=True, exist_ok=True)
today=datetime.datetime.now().strftime("%Y-%m-%d")
f=OUT/f"{today}.md"
# Fetch HN top 5
try:
  ids=json.loads(urllib.request.urlopen("https://hacker-news.firebaseio.com/v0/topstories.json", timeout=10).read())[:5]
  stories=[]
  for sid in ids:
    s=json.loads(urllib.request.urlopen(f"https://hacker-news.firebaseio.com/v0/item/{sid}.json", timeout=5).read())
    stories.append(f"- {s.get('title')} ({s.get('score')} pts)")
except Exception as e:
  stories=[f"HN fetch failed: {e}"]
f.write_text(f"# Daily {today}\n\n" + "\n".join(stories))
print(f"Created {f}")
PY
python3 daily_briefing.py
cat projects/Project_daily/output/$(date +%Y-%m-%d).md
```

### 7. Verification (final)

```bash
cd ~/skillos
echo "=== SkillOS Universal ==="
ls .agents/ | wc -l
ls .skillos/skills/ | wc -l
python3 universal_runtime.py status 2>&1 | tail -n 15

echo ""
echo "=== Mega-Tron ==="
mega-tron skills list 2>&1 | head -n 20
mega-tron dashboard --help 2>&1 | head -n 5 || true
ls ~/.local/share/mega-tron/pool/skills/ | wc -l

echo ""
echo "=== Codex ==="
which codex
codex --version 2>&1 | head
ls ~/.codex/ 2>/dev/null | head

echo ""
echo "=== Ready ==="
echo "Use: codex exec 'install or update mega-tron for me following https://github.com/mega-edo/mega-tron/blob/main/docs/agent%20installation.md'"
echo "Or: mega-tron search 'Create tutorial on chaos theory'  # should return top 3 skills ~150 tokens"
```

## Expected Result

After this prompt, new Linux machine should have:
- SkillOS unfrozen universal: 49 agents in .agents/, 108 skills in .skillos/skills/, 4 repos cached 113 SKILL.md
- Mega-tron router: master pool ~/.local/share/mega-tron/pool/skills/ with symlinks to ~/.codex/skills, ~/.claude/skills/
- ONE router skill: .agents/skill-router-agent.md that dynamically indexes all and picks top 2-3 based on task wording
- Daily useful: daily_briefing.py creates projects/Project_daily/output/YYYY-MM-DD.md with real HN data
- Works with Codex: `codex exec "your task"` now routed through mega-tron top-K, flat token cost

If any step fails, report exact error and fallback.

---

End of prompt for Codex on new Linux machine.
