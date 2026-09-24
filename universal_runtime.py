#!/usr/bin/env python3
"""
SkillOS Universal Runtime - Provider Agnostic
No Claude dependency, works with any LLM or local mode
"""

import os
import sys
import json
import re
import subprocess
from pathlib import Path
from datetime import datetime

ROOT = Path(__file__).parent
AGENT_DIRS = [
    ROOT / ".agents",
    ROOT / ".skillos" / "agents",
    ROOT / ".claude" / "agents",
    ROOT / "components" / "agents",
]
SKILL_DIRS = [
    ROOT / ".skillos" / "skills",
    ROOT / "system" / "skills",
    ROOT / ".skillos-cache",
]
PROJECTS_DIR = ROOT / "projects"
CONFIG_PATH = ROOT / ".skillos" / "config.json"
REGISTRY_PATH = ROOT / ".skillos" / "registry.json"

# Ensure rich
try:
    from rich.console import Console
    from rich.markdown import Markdown
    from rich.table import Table
except ImportError:
    print("Installing rich...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "rich", "-q"])
    from rich.console import Console
    from rich.markdown import Markdown
    from rich.table import Table

console = Console()

class UniversalRuntime:
    def __init__(self):
        self.root = ROOT
        self.agents = {}
        self.skills = {}
        self.providers = {}
        self.load_config()
        self.discover_agents()
        self.discover_skills()
        self.check_providers()
    
    def load_config(self):
        if CONFIG_PATH.exists():
            try:
                self.config = json.loads(CONFIG_PATH.read_text())
            except:
                self.config = {"universal": True}
        else:
            self.config = {"universal": True}
    
    def discover_agents(self):
        agents = {}
        for d in AGENT_DIRS:
            if not d.exists():
                continue
            for f in d.glob("*.md"):
                # Skip non-agent files
                if f.name.lower() in ("readme.md", "license.md"):
                    continue
                # Parse frontmatter for name
                name = f.stem
                try:
                    content = f.read_text()[:2000]
                    m = re.search(r'^name:\s*(.+)$', content, re.MULTILINE)
                    if m:
                        name = m.group(1).strip()
                except:
                    pass
                if f.name not in agents:
                    agents[f.name] = {"path": str(f), "name": name, "dir": str(d)}
        self.agents = agents
        return agents
    
    def discover_skills(self):
        skills = {}
        for d in SKILL_DIRS:
            if not d.exists():
                continue
            # Recursively find SKILL.md and *.md
            for f in d.rglob("*.md"):
                if f.name.lower() in ("readme.md", "license.md", "contributing.md"):
                    continue
                # For cache, only count SKILL.md
                if ".skillos-cache" in str(f) and f.name != "SKILL.md":
                    continue
                key = f"{d.name}/{f.parent.name}/{f.name}" if f.name == "SKILL.md" else f.name
                if f.name not in skills:
                    skills[f.name] = str(f)
        self.skills = skills
        return skills
    
    def check_providers(self):
        providers = {}
        # Check claude
        providers["claude-code"] = subprocess.run(["which", "claude"], capture_output=True).returncode == 0
        # Check python libs
        for lib in ["openai", "rich", "dotenv", "requests"]:
            try:
                __import__(lib)
                providers[lib] = True
            except:
                providers[lib] = False
        # Check env keys
        providers["env"] = {
            "OPENROUTER_API_KEY": bool(os.getenv("OPENROUTER_API_KEY")),
            "GEMINI_API_KEY": bool(os.getenv("GEMINI_API_KEY")),
            "OPENAI_API_KEY": bool(os.getenv("OPENAI_API_KEY")),
            "ANTHROPIC_API_KEY": bool(os.getenv("ANTHROPIC_API_KEY")),
        }
        # Determine best available provider
        if providers["claude-code"]:
            providers["best"] = "claude-code"
        elif providers["env"]["OPENAI_API_KEY"] and providers["openai"]:
            providers["best"] = "openai"
        elif providers["env"]["GEMINI_API_KEY"]:
            providers["best"] = "gemini"
        elif providers["env"]["OPENROUTER_API_KEY"]:
            providers["best"] = "openrouter"
        else:
            providers["best"] = "local"
        
        self.providers = providers
        return providers
    
    def list_agents_table(self):
        table = Table(title=f"Universal Agents ({len(self.agents)} discovered)", show_lines=True)
        table.add_column("Name", style="cyan", width=30)
        table.add_column("File", width=40)
        table.add_column("Location", width=20)
        for fname, info in sorted(self.agents.items())[:50]:
            table.add_row(info["name"][:30], fname[:40], Path(info["dir"]).name)
        console.print(table)
        if len(self.agents) > 50:
            console.print(f"[dim]... and {len(self.agents)-50} more[/dim]")
    
    def list_skills_table(self):
        table = Table(title=f"Universal Skills ({len(self.skills)} discovered)", show_lines=True)
        table.add_column("Skill File", style="green", width=40)
        table.add_column("Path", width=60)
        for fname, path in sorted(self.skills.items())[:50]:
            table.add_row(fname[:40], path[:60])
        console.print(table)
        if len(self.skills) > 50:
            console.print(f"[dim]... and {len(self.skills)-50} more[/dim]")
    
    def show_status(self):
        console.print()
        console.print("[bold cyan]SkillOS Universal Runtime[/bold cyan]")
        console.print(f"Root: {self.root}")
        console.print(f"Universal: {self.config.get('universal', True)} | Claude optional: {self.config.get('claude_optional', True)}")
        console.print()
        
        # Providers
        table = Table(title="Providers", show_lines=False)
        table.add_column("Provider", style="cyan")
        table.add_column("Available", style="green")
        for k,v in self.providers.items():
            if k == "env" or k == "best":
                continue
            status = "✓" if v else "✗"
            table.add_row(k, status)
        console.print(table)
        console.print(f"Best available: [bold]{self.providers.get('best', 'local')}[/bold]")
        console.print()
        
        console.print(f"Agents: {len(self.agents)} (in .agents, .skillos/agents, .claude/agents)")
        console.print(f"Skills: {len(self.skills)} (in .skillos/skills, system/skills, cache)")
        console.print(f"Projects: {len(list(PROJECTS_DIR.iterdir())) if PROJECTS_DIR.exists() else 0}")
        console.print(f"Cache repos: {len(list((ROOT/'.skillos-cache').iterdir())) if (ROOT/'.skillos-cache').exists() else 0}")
        console.print()
        
        if REGISTRY_PATH.exists():
            console.print("[dim]Registry: .skillos/registry.json[/dim]")
            try:
                reg = json.loads(REGISTRY_PATH.read_text())
                for repo in reg.get("repos", []):
                    console.print(f"  - {repo['name']}: {repo['skills']} skills ({repo['status']})")
            except:
                pass
        console.print()
    
    def execute_local(self, goal: str):
        """Local execution without LLM - creates project structure and logs"""
        console.print(f"[yellow]Executing locally (no LLM): {goal}[/yellow]")
        # Create project name from goal
        proj_name = re.sub(r'[^a-zA-Z0-9_]+', '_', goal[:30]).strip('_')
        proj_name = f"Project_{proj_name}" if proj_name else f"Project_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        proj_dir = PROJECTS_DIR / proj_name
        proj_dir.mkdir(parents=True, exist_ok=True)
        (proj_dir / "input").mkdir(exist_ok=True)
        (proj_dir / "output").mkdir(exist_ok=True)
        (proj_dir / "memory" / "short_term").mkdir(parents=True, exist_ok=True)
        (proj_dir / "memory" / "long_term").mkdir(parents=True, exist_ok=True)
        (proj_dir / "state").mkdir(exist_ok=True)
        
        # Log
        log_file = proj_dir / "memory" / "short_term" / f"{datetime.now().strftime('%Y-%m-%d_%H-%M-%S')}_local_execution.md"
        log_file.write_text(f"""---
timestamp: {datetime.now().isoformat()}
goal: {goal}
mode: local
---

# Local Execution Log

Goal: {goal}
Project: {proj_name}
Agents available: {len(self.agents)}
Skills available: {len(self.skills)}

This was executed in local mode without LLM. To enable LLM execution, set:
- OPENAI_API_KEY for OpenAI
- GEMINI_API_KEY for Gemini
- OPENROUTER_API_KEY for Qwen/Gemma via OpenRouter
- Install claude CLI for Claude Code mode

Project structure created at: {proj_dir}
""")
        console.print(f"[green]Project created: {proj_dir}[/green]")
        console.print(f"[dim]Log: {log_file}[/dim]")
        return proj_dir
    
    def repl(self):
        console.print("[bold green]SkillOS Universal REPL[/bold green] — type help, status, agents, skills, exit")
        console.print(f"Best provider: {self.providers.get('best', 'local')} | Agents: {len(self.agents)} | Skills: {len(self.skills)}")
        console.print()
        while True:
            try:
                user_input = console.input("[bold green]universal$ [/bold]")
            except (EOFError, KeyboardInterrupt):
                console.print("\n[dim]Exiting...[/dim]")
                break
            user_input = user_input.strip()
            if not user_input:
                continue
            if user_input.lower() in ("exit", "quit", "q"):
                break
            elif user_input.lower() == "help":
                console.print(Markdown("""
## Universal Commands
- `help` — this help
- `status` — system status
- `agents` — list agents
- `skills` — list skills
- `list` — list all agents with paths
- `execute: \"goal\"` or just `\"goal\"` — execute a goal
- `clear` — clear screen
- `exit` — quit

## Providers
- claude-code (if claude CLI installed)
- openai (needs OPENAI_API_KEY)
- gemini (needs GEMINI_API_KEY)
- openrouter (needs OPENROUTER_API_KEY for Qwen/Gemma)
- local (no LLM, just scaffolding)

## Universal dirs
- `.agents/` — provider-agnostic agents (NEW, universal)
- `.skillos/agents/` — universal agents
- `.claude/agents/` — Claude Code agents (backward compat)
- `.skillos/skills/` — universal skills from external repos
- `.skillos-cache/` — cloned external repos
"""))
            elif user_input.lower() == "status":
                self.show_status()
            elif user_input.lower() in ("agents", "ls agents"):
                self.list_agents_table()
            elif user_input.lower() in ("skills", "ls skills"):
                self.list_skills_table()
            elif user_input.lower() == "list":
                for k,v in sorted(self.agents.items()):
                    console.print(f"{k}: {v['path']}")
            elif user_input.lower() == "clear":
                console.clear()
            elif user_input.startswith("execute:") or len(user_input) > 5:
                goal = user_input
                if goal.startswith("execute:"):
                    goal = goal[len("execute:"):].strip().strip('"\'')
                self.execute_local(goal)
            else:
                console.print(f"[dim]Unknown: {user_input} — type help[/dim]")

def main():
    rt = UniversalRuntime()
    if len(sys.argv) > 1:
        cmd = sys.argv[1].lower()
        if cmd == "status":
            rt.show_status()
        elif cmd in ("agents", "list", "ls"):
            rt.list_agents_table()
        elif cmd == "skills":
            rt.list_skills_table()
        elif cmd == "execute" and len(sys.argv) > 2:
            goal = " ".join(sys.argv[2:])
            rt.execute_local(goal)
        elif cmd == "repl" or cmd == "interactive":
            rt.repl()
        else:
            # Treat all args as goal
            goal = " ".join(sys.argv[1:])
            rt.execute_local(goal)
    else:
        rt.show_status()
        console.print("[dim]Run with 'repl' for interactive mode, or 'agents', 'skills', 'status'[/dim]")

if __name__ == "__main__":
    main()
