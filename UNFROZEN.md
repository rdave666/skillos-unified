# UNFROZEN - 2026-09-16

This repo was frozen on 2026-08-01 with note "Not under development, carried forward in ai-os as ai-flows"

Now UNFROZEN as universal provider-agnostic version:

- Removed Claude lock: .agents/ + .skillos/agents/ alongside .claude/agents/
- Added universal_runtime.py (no claude CLI needed)
- Added daily.sh + daily_briefing.py for daily useful (Hacker News + GitHub trending, no LLM)
- Installed 4 external repos from sources.list: 113 SKILL.md, 108 installed
- 54 agents, 170 skills discovered
- Works with any provider: claude-code, openai, gemini, openrouter, local

Quick start:
  ./setup_universal.sh
  ./install_universal_agents.sh
  bash daily.sh
  python3 universal_runtime.py status

Original frozen notice preserved in git history, but README now says UNFROZEN.

Status: ACTIVE, DAILY USEFUL
