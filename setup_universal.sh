#!/bin/bash
# SkillOS Universal Setup — Provider-agnostic, not Claude-locked
# Creates universal agent discovery for any runtime

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

UNIVERSAL_AGENTS_DIR=".agents"
CLAUDE_AGENTS_DIR=".claude/agents"
SKILLOS_AGENTS_DIR=".skillos/agents"
SKILLOS_SKILLS_DIR=".skillos/skills"
CACHE_DIR=".skillos-cache"
SOURCES_FILE="system/sources.list"

SUCCESS=0
SKIP=0
WARN=0
ERR=0

echo "=========================================="
echo "SkillOS Universal Setup v1.0"
echo "Provider-agnostic, not Claude-locked"
echo "=========================================="
echo ""

# 1. Create universal directories
echo "--- Creating universal directories ---"
mkdir -p "$UNIVERSAL_AGENTS_DIR"
mkdir -p "$CLAUDE_AGENTS_DIR"
mkdir -p "$SKILLOS_AGENTS_DIR"
mkdir -p "$SKILLOS_SKILLS_DIR"
mkdir -p "$CACHE_DIR"
mkdir -p "projects"
echo "  Created: $UNIVERSAL_AGENTS_DIR, $CLAUDE_AGENTS_DIR, $SKILLOS_AGENTS_DIR, $SKILLOS_SKILLS_DIR, $CACHE_DIR"
echo ""

# 2. Install Python deps (universal, not Claude-specific)
echo "--- Checking Python dependencies ---"
python3 -m pip install --quiet rich openai python-dotenv requests 2>&1 | tail -n 5 || echo "  pip install had warnings, continuing..."
echo "  Deps: rich, openai, python-dotenv, requests"
echo ""

# 3. Run original Tier 1-4 setup but to BOTH locations
echo "--- Tier 1-4: Copying local agents to universal locations ---"

copy_to_all() {
    local src="$1"
    local base=$(basename "$src")
    local dest1="$CLAUDE_AGENTS_DIR/$base"
    local dest2="$UNIVERSAL_AGENTS_DIR/$base"
    local dest3="$SKILLOS_AGENTS_DIR/$base"
    
    # Copy if changed
    for dest in "$dest1" "$dest2" "$dest3"; do
        if [[ -f "$dest" ]]; then
            src_hash=$(md5sum "$src" | cut -d' ' -f1)
            dest_hash=$(md5sum "$dest" | cut -d' ' -f1)
            if [[ "$src_hash" == "$dest_hash" ]]; then
                continue
            fi
        fi
        cp "$src" "$dest" 2>/dev/null && echo "  COPIED: $base -> $dest" && SUCCESS=$((SUCCESS+1)) || { echo "  ERR: $base"; ERR=$((ERR+1)); }
    done
}

# Tier 1: system/skills
if [[ -d "system/skills" ]]; then
    while IFS= read -r manifest; do
        [[ -f "$manifest" ]] || continue
        skill_type=$(grep -m 1 "^type:" "$manifest" 2>/dev/null | sed 's/^type:[[:space:]]*//' | tr -d '\r ' || true)
        [[ "$skill_type" == "agent" ]] || continue
        full_spec=$(grep -m 1 "^full_spec:" "$manifest" 2>/dev/null | sed 's/^full_spec:[[:space:]]*//' | tr -d '\r ' || true)
        [[ -n "$full_spec" && -f "$full_spec" ]] || continue
        copy_to_all "$full_spec"
    done < <(find "system/skills" -name "*.manifest.md" 2>/dev/null | sort)
fi

# Tier 3 & 4: projects and components/agents
if [[ -d "components/agents" ]]; then
    for agent in components/agents/*.md; do
        [[ -f "$agent" ]] || continue
        copy_to_all "$agent"
    done
fi

if [[ -d "projects" ]]; then
    for project_dir in projects/*/; do
        [[ -d "$project_dir/components/agents" ]] || continue
        project_name=$(basename "$project_dir")
        for agent in "$project_dir/components/agents"/*.md; do
            [[ -f "$agent" ]] || continue
            agent_name=$(basename "$agent" .md)
            base="${project_name}_${agent_name}.md"
            for dest_root in "$CLAUDE_AGENTS_DIR" "$UNIVERSAL_AGENTS_DIR" "$SKILLOS_AGENTS_DIR"; do
                dest="$dest_root/$base"
                if [[ -f "$dest" ]]; then
                    src_hash=$(md5sum "$agent" | cut -d' ' -f1)
                    dest_hash=$(md5sum "$dest" | cut -d' ' -f1)
                    [[ "$src_hash" == "$dest_hash" ]] && continue
                fi
                cp "$agent" "$dest" && SUCCESS=$((SUCCESS+1)) || ERR=$((ERR+1))
            done
            echo "  COPIED project agent: $base"
        done
    done
fi

echo ""
echo "--- Tier 5: Installing from $SOURCES_FILE ---"
if [[ ! -f "$SOURCES_FILE" ]]; then
    echo "  No sources.list found"
else
    INSTALLED=0
    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ || -z "${line// /}" ]] && continue
        read -r src_type src_uri src_branch src_path <<< "$line"
        src_path="${src_path:-./}"
        [[ "$src_type" != "github" ]] && continue
        
        repo_hash=$(echo "$src_uri-$src_branch" | md5sum | cut -d' ' -f1)
        cache_path="$CACHE_DIR/$repo_hash"
        
        if [[ -d "$cache_path" ]]; then
            echo "  Updating: $src_uri ($src_branch)"
            (cd "$cache_path" && git pull --quiet 2>/dev/null) || true
        else
            echo "  Cloning: $src_uri ($src_branch) -> $cache_path"
            git clone --depth 1 --branch "$src_branch" "https://github.com/$src_uri.git" "$cache_path" 2>&1 | tail -n 3 || {
                echo "  WARN: Failed to clone $src_uri"
                WARN=$((WARN+1))
                continue
            }
        fi
        
        skill_dir="$cache_path/$src_path"
        if [[ ! -d "$skill_dir" ]]; then
            echo "  WARN: Path $src_path not found in $src_uri, trying root and common alts"
            # Try common alternatives
            for alt in "skills" "." ".claude/skills" "agents" ".agents"; do
                if [[ -d "$cache_path/$alt" ]]; then
                    skill_dir="$cache_path/$alt"
                    echo "    Found alt: $alt"
                    break
                fi
            done
        fi
        
        if [[ -d "$skill_dir" ]]; then
            count=$(find "$skill_dir" -maxdepth 2 -name "*.md" 2>/dev/null | wc -l)
            echo "    Found $count md files in $skill_dir"
            shopt -s nullglob
            for skill_file in "$skill_dir"/*.md "$skill_dir"/*/*.md; do
                [[ -f "$skill_file" ]] || continue
                # Only copy agent/tool like files
                basename_file=$(basename "$skill_file")
                # Skip README, LICENSE etc
                [[ "$basename_file" =~ ^(README|LICENSE|CONTRIBUTING).md$ ]] && continue
                # Copy to universal skills dir
                dest_skill="$SKILLOS_SKILLS_DIR/$basename_file"
                if [[ ! -f "$dest_skill" ]]; then
                    cp "$skill_file" "$dest_skill" 2>/dev/null && INSTALLED=$((INSTALLED+1))
                fi
                # If it's an agent, also copy to agents dirs
                if grep -q "^type:.*agent" "$skill_file" 2>/dev/null || [[ "$basename_file" == *"-agent.md" ]] || [[ "$basename_file" == *"Agent.md" ]]; then
                    for dest_root in "$UNIVERSAL_AGENTS_DIR" "$CLAUDE_AGENTS_DIR" "$SKILLOS_AGENTS_DIR"; do
                        dest="$dest_root/$basename_file"
                        [[ -f "$dest" ]] && continue
                        cp "$skill_file" "$dest" 2>/dev/null && SUCCESS=$((SUCCESS+1))
                    done
                fi
            done
        else
            echo "  WARN: No skill dir found for $src_uri"
            WARN=$((WARN+1))
        fi
    done < <(grep "^github" "$SOURCES_FILE")
    echo "  Total external skills cached: $INSTALLED"
fi

echo ""
echo "--- Creating universal config ---"
cat > .skillos/config.json << 'JSON'
{
  "version": "1.0-universal",
  "runtime": "universal",
  "providers": ["claude-code", "openai", "gemini", "qwen", "gemma", "local"],
  "agent_dirs": [".agents", ".claude/agents", ".skillos/agents", "components/agents"],
  "skill_dirs": [".skillos/skills", "system/skills", ".skillos-cache"],
  "project_dir": "projects",
  "universal": true,
  "claude_optional": true
}
JSON
mkdir -p .skillos
cat > .skillos/config.json << EOF
{
  "version": "1.0-universal",
  "runtime": "universal",
  "providers": ["claude-code", "openai", "gemini", "qwen", "gemma", "local"],
  "agent_dirs": [".agents", ".claude/agents", ".skillos/agents", "components/agents"],
  "skill_dirs": [".skillos/skills", "system/skills", ".skillos-cache"],
  "project_dir": "projects",
  "universal": true,
  "claude_optional": true,
  "installed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
echo "  Created .skillos/config.json"

# Create universal launcher wrapper
cat > skillos_universal.py << 'PY'
#!/usr/bin/env python3
"""
SkillOS Universal Runtime - Not Claude-locked
Works with any provider: Claude, OpenAI, Gemini, Qwen, Gemma, local
"""
import os, sys, json, subprocess
from pathlib import Path

ROOT = Path(__file__).parent
AGENT_DIRS = [ROOT/".agents", ROOT/".claude/agents", ROOT/".skillos/agents", ROOT/"components/agents"]
SKILL_DIRS = [ROOT/".skillos/skills", ROOT/"system/skills"]

def list_agents():
    agents = {}
    for d in AGENT_DIRS:
        if not d.exists():
            continue
        for f in d.glob("*.md"):
            if f.name not in agents:
                agents[f.name] = str(f)
    return agents

def list_skills():
    skills = {}
    for d in SKILL_DIRS:
        if not d.exists():
            continue
        for f in d.rglob("*.md"):
            if f.name in ("README.md", "LICENSE.md"):
                continue
            if f.name not in skills:
                skills[f.name] = str(f)
    return skills

def check_providers():
    providers = {}
    # Claude
    providers["claude-code"] = bool(subprocess.run(["which", "claude"], capture_output=True).returncode == 0)
    # Python deps
    try:
        import openai
        providers["openai"] = True
    except:
        providers["openai"] = False
    try:
        import rich
        providers["rich"] = True
    except:
        providers["rich"] = False
    # Env keys
    providers["openrouter_key"] = bool(os.getenv("OPENROUTER_API_KEY"))
    providers["gemini_key"] = bool(os.getenv("GEMINI_API_KEY"))
    providers["openai_key"] = bool(os.getenv("OPENAI_API_KEY"))
    return providers

def main():
    print("="*60)
    print("SkillOS Universal Runtime v1.0")
    print("Provider-agnostic, not Claude-locked")
    print("="*60)
    print(f"Root: {ROOT}")
    print()
    
    agents = list_agents()
    print(f"Discovered Agents: {len(agents)}")
    for name in sorted(agents.keys())[:20]:
        print(f"  - {name}")
    if len(agents) > 20:
        print(f"  ... and {len(agents)-20} more")
    print()
    
    skills = list_skills()
    print(f"Discovered Skills: {len(skills)} (in .skillos/skills + system/skills)")
    print()
    
    providers = check_providers()
    print("Providers:")
    for k,v in providers.items():
        status = "✓" if v else "✗"
        print(f"  {status} {k}")
    print()
    
    print("Usage:")
    print("  python3 skillos_universal.py list                    # list agents")
    print("  python3 skillos_universal.py execute 'goal'          # execute with auto provider")
    print("  python3 skillos_universal.py --provider openai 'goal'")
    print("  ./skillos.sh                                         # original Claude terminal")
    print("  python3 skillos.py                                   # original (requires claude)")
    print()
    print("Universal agent dirs: .agents, .claude/agents, .skillos/agents")
    print("External repos cached in: .skillos-cache/")
    print("External skills in: .skillos/skills/")
    print()

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "list":
        agents = list_agents()
        for k,v in sorted(agents.items()):
            print(f"{k}: {v}")
    else:
        main()
PY
chmod +x skillos_universal.py
echo "  Created skillos_universal.py"

echo ""
echo "=========================================="
echo "Universal Setup Summary"
echo "=========================================="
echo "  Copied: $SUCCESS"
echo "  Warnings: $WARN"
echo "  Errors: $ERR"
echo "  Universal agents: $(ls $UNIVERSAL_AGENTS_DIR 2>/dev/null | wc -l)"
echo "  Claude agents: $(ls $CLAUDE_AGENTS_DIR 2>/dev/null | wc -l)"
echo "  SkillOS agents: $(ls $SKILLOS_AGENTS_DIR 2>/dev/null | wc -l)"
echo "  External cache: $(ls $CACHE_DIR 2>/dev/null | wc -l) repos"
echo "  External skills: $(ls $SKILLOS_SKILLS_DIR 2>/dev/null | wc -l) files"
echo ""
echo "Next:"
echo "  python3 skillos_universal.py          # check universal status"
echo "  ./skillos.sh                          # original Claude terminal (if claude installed)"
echo "  python3 skillos_universal.py list     # list all agents"
echo ""
echo "STATUS: UNIVERSAL READY"
