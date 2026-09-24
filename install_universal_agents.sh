#!/bin/bash
set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
CACHE=".skillos-cache"
UNIVERSAL_AGENTS=".agents"
CLAUDE_AGENTS=".claude/agents"
SKILLOS_AGENTS=".skillos/agents"
SKILLOS_SKILLS=".skillos/skills"

mkdir -p "$UNIVERSAL_AGENTS" "$CLAUDE_AGENTS" "$SKILLOS_AGENTS" "$SKILLOS_SKILLS"

echo "=== Universal Agent Installer ==="
echo "Finding all SKILL.md in $CACHE..."

TOTAL_SKILL=0
TOTAL_AGENT=0

# Find all SKILL.md recursively
find "$CACHE" -name "SKILL.md" | while read skill_file; do
    # Get parent dir name as skill name
    skill_dir=$(dirname "$skill_file")
    skill_name=$(basename "$skill_dir")
    repo_hash=$(echo "$skill_file" | cut -d'/' -f2)
    # Get repo name from cache metadata or path
    repo_path=$(find "$CACHE/$repo_hash" -maxdepth 1 -type d -name ".git" 2>/dev/null | head -n1 | xargs dirname 2>/dev/null || echo "$CACHE/$repo_hash")
    # Try to get remote url
    if [[ -d "$repo_path/.git" ]]; then
        remote=$(cd "$repo_path" && git remote get-url origin 2>/dev/null | sed 's/.*github.com[:\/]//;s/\.git$//')
    else
        remote="unknown"
    fi
    
    # Create unique name: repo_skill_SKILL.md
    safe_remote=$(echo "$remote" | tr '/' '_')
    dest_name="${safe_remote}_${skill_name}_SKILL.md"
    # If safe_remote empty, use hash
    if [[ "$safe_remote" == "_" || -z "$safe_remote" ]]; then
        dest_name="${repo_hash}_${skill_name}_SKILL.md"
    fi
    
    # Copy to universal skills
    if [[ ! -f "$SKILLOS_SKILLS/$dest_name" ]]; then
        cp "$skill_file" "$SKILLOS_SKILLS/$dest_name"
        echo "  SKILL: $dest_name from $remote/$skill_name"
        TOTAL_SKILL=$((TOTAL_SKILL+1))
    fi
    
    # Check if it's an agent (look for type: agent or tools in frontmatter, or name contains agent)
    if grep -q "type:.*agent" "$skill_file" 2>/dev/null || grep -q "name:.*agent" "$skill_file" 2>/dev/null || [[ "$skill_name" == *"agent"* ]]; then
        for dest_root in "$UNIVERSAL_AGENTS" "$CLAUDE_AGENTS" "$SKILLOS_AGENTS"; do
            dest="$dest_root/${safe_remote}_${skill_name}.md"
            if [[ ! -f "$dest" ]]; then
                cp "$skill_file" "$dest"
                TOTAL_AGENT=$((TOTAL_AGENT+1))
            fi
        done
    fi
done

# Also install from system/skills (local)
echo ""
echo "Installing local system/skills..."
find system/skills -name "*.md" -type f | while read f; do
    [[ -f "$f" ]] || continue
    base=$(basename "$f")
    # Skip manifests? Keep them but also full specs
    if [[ "$base" == *".manifest.md" ]]; then
        continue
    fi
    for dest_root in "$UNIVERSAL_AGENTS" "$CLAUDE_AGENTS" "$SKILLOS_AGENTS"; do
        dest="$dest_root/$base"
        if [[ ! -f "$dest" ]]; then
            cp "$f" "$dest" 2>/dev/null || true
        fi
    done
done

# Count
echo ""
echo "=== Summary ==="
echo "Universal agents (.agents): $(ls $UNIVERSAL_AGENTS | wc -l)"
echo "Claude agents (.claude/agents): $(ls $CLAUDE_AGENTS | wc -l)"
echo "SkillOS agents (.skillos/agents): $(ls $SKILLOS_AGENTS | wc -l)"
echo "Universal skills (.skillos/skills): $(ls $SKILLOS_SKILLS | wc -l)"
echo "Cache repos: $(ls $CACHE | wc -l)"
echo "Cache SKILL.md total: $(find $CACHE -name "SKILL.md" | wc -l)"

# Create universal registry
cat > .skillos/registry.json << JSON
{
  "version": "1.0-universal",
  "generated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "repos": [
    {"name": "anthropics/skills", "status": "cloned", "skills": $(find $CACHE -path "*aafebdd99c3d93bce27447b3bab75c16*" -name "SKILL.md" | wc -l), "path": ".skillos-cache/aafebdd99c3d93bce27447b3bab75c16"},
    {"name": "huggingface/skills", "status": "cloned", "skills": $(find $CACHE -path "*b05e288abc1617d90cc880ab10b853b0*" -name "SKILL.md" | wc -l), "path": ".skillos-cache/b05e288abc1617d90cc880ab10b853b0"},
    {"name": "openai/skills", "status": "cloned-deprecated", "skills": $(find $CACHE -path "*ceac4d14d257b71828b21d6b9b10e5f4*" -name "SKILL.md" | wc -l), "path": ".skillos-cache/ceac4d14d257b71828b21d6b9b10e5f4", "note": "deprecated, use openai/plugins"},
    {"name": "google-ai-edge/gallery", "status": "cloned", "skills": $(find $CACHE -path "*c5111dc180304308df93c8a928175c2f*" -name "SKILL.md" | wc -l), "path": ".skillos-cache/c5111dc180304308df93c8a928175c2f"}
  ],
  "total_cached_skills": $(find $CACHE -name "SKILL.md" | wc -l),
  "universal_agents": $(ls $UNIVERSAL_AGENTS | wc -l),
  "universal_skills": $(ls $SKILLOS_SKILLS | wc -l),
  "provider_agnostic": true
}
JSON
cat .skillos/registry.json
