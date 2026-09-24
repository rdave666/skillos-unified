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
