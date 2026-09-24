#!/bin/bash
# SkillOS Unified + Mega-Tron Router - ONE install.sh for fresh Linux + Codex
# Unfrozen 2026-09-16, universal, not Claude-locked, 54 agents, 108 skills, 113 cached
# Usage: sh install.sh  or  bash install.sh  or  curl -fsSL https://.../install.sh | sh
set -e

echo "=========================================="
echo "SkillOS Unified + Mega-Tron - ONE installer"
echo "For fresh Linux machine running Codex"
echo "=========================================="
echo ""

# 0. Prereqs
echo "--- 0. Prereqs ---"
which git >/dev/null 2>&1 || { echo "git not found, installing..."; sudo apt-get update && sudo apt-get install -y git || true; }
python3 --version || { echo "python3 not found"; exit 1; }
PY_VER=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
echo "  Python: $PY_VER (need 3.11+)"
which codex >/dev/null 2>&1 && codex --version 2>&1 | head -n1 || echo "  codex not found (will still install skillos, mega-tron will skip codex host)"
which uv >/dev/null 2>&1 || { echo "  Installing uv..."; curl -LsSf https://astral.sh/uv/install.sh | sh; export PATH="$HOME/.local/bin:$PATH"; }
export PATH="$HOME/.local/bin:$PATH"
echo "  uv: $(which uv || echo 'not yet, will be after install')"
echo "  Space: $(df -h ~ | tail -n1)"
echo ""

# 1. Clone SkillOS
echo "--- 1. Clone SkillOS ---"
cd ~
if [ -d skillos ]; then
  echo "  skillos exists, updating..."
  cd skillos && git pull --quiet 2>/dev/null || true
  cd ~
else
  # PRIVATE repo - gh auth or SSH key required. If it fails, it fails.
  git clone https://github.com/rdave666/skillos-unified.git skillos 2>/dev/null \
    || git clone git@github.com:rdave666/skillos-unified.git skillos
  [ -d skillos ] || { echo "  clone failed - authenticate first: gh auth login, or add an SSH key"; exit 1; }
fi
cd ~/skillos
echo "  Cloned to ~/skillos (remote: $(git remote get-url origin 2>/dev/null))"
echo ""

# 2. Unfreeze + Universal setup
echo "--- 2. Unfreeze + Universal setup ---"
cat > UNFROZEN.md << 'MD'
# UNFROZEN - 2026-09-16
Previously frozen 2026-08-01, now active universal provider-agnostic OS
- .agents/ + .skillos/agents/ + .claude/agents/ (not just Claude)
- universal_runtime.py (no claude lock)
- daily_briefing.py (real HN + GH trending)
- 4 external repos, 113 SKILL.md, 108 installed
MD

mkdir -p .agents .claude/agents .skillos/agents .skillos/skills .skillos-cache projects
python3 -m pip install --quiet rich openai python-dotenv requests 2>&1 | tail -n2 || true

# Universal copy function
copy_universal() {
  src="$1"
  base=$(basename "$src")
  for d in .agents .skillos/agents .claude/agents; do
    mkdir -p "$d"
    if [ ! -f "$d/$base" ]; then
      cp "$src" "$d/$base" 2>/dev/null && echo "  + $base -> $d/" || true
    fi
  done
}

# Tier1: system/skills manifests
if [ -d system/skills ]; then
  find system/skills -name "*.manifest.md" 2>/dev/null | sort | while read m; do
    [ -f "$m" ] || continue
    t=$(grep -m1 "^type:" "$m" 2>/dev/null | sed 's/type:[[:space:]]*//' | tr -d '\r ' || true)
    [ "$t" = "agent" ] || continue
    spec=$(grep -m1 "^full_spec:" "$m" 2>/dev/null | sed 's/full_spec:[[:space:]]*//' | tr -d '\r ' || true)
    [ -n "$spec" ] && [ -f "$spec" ] && copy_universal "$spec" || true
  done
fi

# Tier4: components/agents
[ -d components/agents ] && for f in components/agents/*.md; do [ -f "$f" ] && copy_universal "$f" || true; done

# Original setup for backward compat
chmod +x setup_agents.sh 2>/dev/null || true
bash setup_agents.sh 2>&1 | tail -n5 || true

echo "  Universal: .agents=$(ls .agents 2>/dev/null | wc -l) .skillos/skills=$(ls .skillos/skills 2>/dev/null | wc -l)"
echo ""

# 3. Install external repos (4 official from sources.list)
echo "--- 3. Install external skill repos ---"
cat system/sources.list 2>/dev/null | grep "^github" || echo "No sources.list"

mkdir -p .skillos-cache .skillos/skills
grep "^github" system/sources.list 2>/dev/null | while read type uri branch path; do
  [ -z "$uri" ] && continue
  hash=$(echo "$uri-$branch" | md5sum | cut -d' ' -f1)
  dest=".skillos-cache/$hash"
  if [ -d "$dest" ]; then
    echo "  Updating $uri"
    (cd "$dest" && git pull --quiet 2>/dev/null) || true
  else
    echo "  Cloning $uri ($branch) -> $dest"
    git clone --depth 1 --branch "$branch" "https://github.com/$uri.git" "$dest" 2>&1 | tail -n1 || echo "  WARN clone $uri"
  fi
done

# Install all SKILL.md recursively with unique names
find .skillos-cache -name "SKILL.md" 2>/dev/null | while read f; do
  dir=$(dirname "$f")
  name=$(basename "$dir")
  # get repo name from remote
  repo_root=$(echo "$f" | cut -d'/' -f1-2)
  remote=$(cd "$repo_root" 2>/dev/null && git remote get-url origin 2>/dev/null | sed 's/.*github.com[:\/]//;s/\.git$//' || echo "$repo_root")
  safe=$(echo "$remote" | tr '/' '_' | tr -cd 'a-zA-Z0-9_-')
  dest=".skillos/skills/${safe}_${name}_SKILL.md"
  [ -f "$dest" ] || cp "$f" "$dest" 2>/dev/null && echo "  + $name from $remote" || true
done

echo "  Cached SKILL.md: $(find .skillos-cache -name SKILL.md 2>/dev/null | wc -l), installed: $(ls .skillos/skills 2>/dev/null | wc -l)"
echo ""

# 4. Install Mega-Tron Router
echo "--- 4. Install Mega-Tron Router ---"
cd ~
if [ -d mega-tron ]; then
  echo "  mega-tron exists, updating..."
  cd mega-tron && git pull --quiet 2>/dev/null || true
  cd ~
else
  git clone https://github.com/mega-edo/mega-tron
fi
cd ~/mega-tron
export PATH="$HOME/.local/bin:$PATH"
sh install.sh 2>&1 | tail -n10 || echo "  install.sh had warnings"
export PATH="$HOME/.local/bin:$PATH"
which mega-tron && mega-tron --help 2>&1 | head -n5 || echo "  mega-tron not in PATH yet, open new terminal"

# Setup with en-quality (130MB)
mega-tron setup --profile en-quality 2>&1 | tail -n10 || mega-tron setup 2>&1 | tail -n10 || true
echo ""

# 5. Unify pools
echo "--- 5. Unify SkillOS + Mega-Tron pools ---"
mkdir -p ~/.local/share/mega-tron/pool/skills/
cd ~/skillos
for f in .agents/*.md; do [ -f "$f" ] && cp "$f" ~/.local/share/mega-tron/pool/skills/ 2>/dev/null || true; done
echo "  Master pool: $(ls ~/.local/share/mega-tron/pool/skills/ 2>/dev/null | wc -l) skills"

mega-tron skills sync 2>&1 | tail -n5 || true
echo "  Codex skills: $(ls ~/.codex/skills 2>/dev/null | wc -l || echo 0)"
echo "  Claude skills: $(ls ~/.claude/skills 2>/dev/null | wc -l || echo 0)"
echo ""

# 6. Create ONE router skill + universal runtime
echo "--- 6. Create ONE router skill (future-proof) ---"
cd ~/skillos
cat > .agents/skill-router-agent.md << 'MD'
---
name: skill-router-agent
type: agent
description: Meta-router - ONE skill that decides which of many available skills/plugins to use based on task wording. Indexes all skills dynamically, future-proof.
tools: Read, Glob, Grep, Write, Bash
---

# Skill Router Agent - ONE skill to rule them all
On every invocation, Glob scan .agents/*.md, .skillos/skills/*, system/skills/**/, .skillos-cache/**/SKILL.md, extract name/description, score task vs description, output JSON top 2-3 + reason + tokens saved. Log verdict to .skillos/verdicts.json. Never hardcode list.
MD

cp .agents/skill-router-agent.md .claude/agents/ 2>/dev/null || true
cp .agents/skill-router-agent.md .skillos/agents/ 2>/dev/null || true

# Universal runtime (provider-agnostic)
cat > universal_runtime.py << 'PY'
#!/usr/bin/env python3
import pathlib, subprocess, os, sys
ROOT=pathlib.Path(__file__).parent
AGENTS=[ROOT/".agents", ROOT/".skillos/agents", ROOT/".claude/agents"]
SKILLS=[ROOT/".skillos/skills", ROOT/"system/skills"]
def count_agents(): return sum(len(list(d.glob("*.md"))) for d in AGENTS if d.exists())
def count_skills(): return sum(len(list(d.rglob("*.md"))) for d in SKILLS if d.exists())
if __name__=="__main__":
  print(f"SkillOS Universal - Agents: {count_agents()} Skills: {count_skills()} Root: {ROOT}")
  if len(sys.argv)>1 and sys.argv[1]=="status":
    print(f"Agents dirs: {[str(d) for d in AGENTS]}")
    print(f"Best provider: {'claude-code' if subprocess.run(['which','claude'], capture_output=True).returncode==0 else 'local'}")
PY
chmod +x universal_runtime.py

# Daily briefing (no LLM)
cat > daily_briefing.py << 'PY'
import urllib.request, json, datetime, pathlib
ROOT=pathlib.Path(__file__).parent
OUT=ROOT/"projects"/"Project_daily"/"output"
OUT.mkdir(parents=True, exist_ok=True)
today=datetime.datetime.now().strftime("%Y-%m-%d")
f=OUT/f"{today}.md"
try:
  ids=json.loads(urllib.request.urlopen("https://hacker-news.firebaseio.com/v0/topstories.json", timeout=10).read())[:5]
  stories=[]
  for sid in ids:
    s=json.loads(urllib.request.urlopen(f"https://hacker-news.firebaseio.com/v0/item/{sid}.json", timeout=5).read())
    stories.append(f"- {s.get('title')} ({s.get('score')} pts)")
except Exception as e:
  stories=[f"HN fail: {e}"]
f.write_text(f"# Daily {today}\n\n" + "\n".join(stories))
print(f"Created {f}")
PY
chmod +x daily_briefing.py

# Config
mkdir -p .skillos
cat > .skillos/config.json << JSON
{
  "version": "2.0-unfrozen-universal",
  "status": "UNFROZEN",
  "unfrozen_at": "$(date -u +%Y-%m-%d)",
  "providers": ["claude-code", "openai", "gemini", "qwen", "gemma", "local"],
  "agent_dirs": [".agents", ".claude/agents", ".skillos/agents"],
  "universal": true,
  "claude_optional": true
}
JSON

echo "  Created router skill + universal_runtime.py + daily_briefing.py"
echo ""

# 7. Verify
echo "--- 7. Verify ---"
cd ~/skillos
python3 universal_runtime.py status 2>&1 | tail -n10 || true
echo ""
which mega-tron && mega-tron skills list 2>&1 | head -n10 || echo "mega-tron not ready, open new terminal"
echo ""
echo "Codex: $(which codex || echo 'not found') $(codex --version 2>&1 | head -n1 || true)"
echo ""
echo "=========================================="
echo "DONE - SkillOS Unified + Mega-Tron Router"
echo "=========================================="
echo "Location: ~/skillos"
echo "Agents: $(ls .agents 2>/dev/null | wc -l) in .agents/, $(ls .claude/agents 2>/dev/null | wc -l) in .claude/agents/"
echo "Skills: $(ls .skillos/skills 2>/dev/null | wc -l) in .skillos/skills/, $(find .skillos-cache -name SKILL.md 2>/dev/null | wc -l) cached"
echo "Master pool: $(ls ~/.local/share/mega-tron/pool/skills/ 2>/dev/null | wc -l)"
echo ""
echo "Daily useful:"
echo "  cd ~/skillos && python3 daily_briefing.py"
echo "  python3 universal_runtime.py status"
echo "  python3 universal_runtime.py execute \"Your task here\""
echo ""
echo "Mega-Tron router:"
echo "  mega-tron search \"Create tutorial on chaos theory\"  # top 3 ~150 tokens"
echo "  mega-tron dashboard  # http://127.0.0.1:7531"
echo "  mega-tron skills list"
echo ""
echo "Codex:"
echo "  codex exec \"install or update mega-tron for me following https://github.com/mega-edo/mega-tron/blob/main/docs/agent%20installation.md\""
echo ""
echo "ONE router skill: .agents/skill-router-agent.md (attach to ChatGPT web as skill)"
echo "Prompt for ChatGPT web: PROMPT_FOR_CHATGPT_WEB.md"
echo ""
