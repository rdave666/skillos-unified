# Prompt for ChatGPT Web - Build Router Skill for 100+ Skills

Copy-paste this entire prompt into ChatGPT web (chat, work, or Codex) to get plan + solution.

---

## Context: What we have done so far

1. **Teamily.ai passive exposure assessment** (done, in `findings/`):
   - Verified apex 34.53.63.161, 7 prod hosts (open.teamily.ai, imserver.teamily.ai, blog Ghost/Fastly, p.teamily.ai PostHog, BunnyCDN static/storage, preview.teamily.run), 6 test hosts on 34.53.28.16 (chat-test live with debug flags true), 8 public skill repos, APK artifact
   - Lead register 13 VERIFIED-SURFACE, 1 PLAUSIBLE ownership boundary

2. **SkillOS cloned and made universal** (was Claude-locked, now not):
   - Original: only `.claude/agents/` + requires `claude` CLI (`skillos.py` hard-codes `["claude", "-p"]`)
   - Now: `.agents/` (49 universal) + `.skillos/agents/` (49) + `.claude/agents/` (54) + `.skillos/skills/` (108) + `.skillos-cache/` (4 repos, 113 SKILL.md)
   - Created `universal_runtime.py` (no Claude needed, works local/offline), `daily_briefing.py` (real HN + GitHub trending, no LLM), `daily.sh`
   - Unfrozen repo: removed FROZEN 2026-08-01 banner, now v2.0-unfrozen-universal
   - Installed 4 repos from `system/sources.list`: anthropics/skills (20), huggingface/skills (26), openai/skills (44 deprecated), google-ai-edge/gallery (23)

3. **Evaluated mega-edo/mega-tron**:
   - Skill OS for Codex/Claude/Gemini, 3 problems: token leak (hi with 150 skills = 8.4k tokens), host isolation (one pool + symlinks), evidence blind (HELPFUL/HARMFUL verdicts + dashboard 127.0.0.1:7531)
   - Router: per-turn semantic top-K ~150 tokens vs ~30k, flat cost even at 500 skills, coverage 0.892
   - Verdict: useful as optional external router if you use 3 CLIs daily with 100+ skills, but heavy (130-570MB embedder, daemon, uv, Linux/macOS only) for frozen SkillOS

## My Idea Crystallized

**I want ONE skill attached to ChatGPT web that decides which of the many available skills/plugins to actually use based on task wording.**

Requirements:
- Must index all available skills/plugins somehow (currently 54 agents + 108 skills + system/skills 80 = 170 total, growing)
- Future-proof: as new skills come in (new files in `.agents/` or `.skillos-cache/`), auto-discovered, no code change
- Dynamically updated: new skill added → next task auto-indexed
- Inclusive: skills AND plugins (both are markdown with frontmatter `name:`, `description:`, `type:`)
- Token efficient: don't inject 170 skills every turn, only top 2-3 relevant (~150 tokens vs ~8k)
- Works across ChatGPT chat, work, and Codex

This is exactly what mega-tron does, but I want it as ONE ChatGPT skill itself, not external daemon.

## What I Need From You (ChatGPT Web)

Come up with **plan and solution** how to achieve this router skill using:

1. **ChatGPT chat** (web, no token count/limit, no hourly limit, canvas files persist in same chat)
2. **ChatGPT work** (token paid, hourly/weekly limits, stricter)
3. **Codex** (local, same limits as work, can run bash, git, python, file system)

For each runtime, explain:
- How to implement the ONE router skill
- How indexing works (dynamic scan vs static list)
- How future-proof update works (new skill arrives)
- How task wording → top-K selection works (keyword vs embedding)
- Token cost: chat (unlimited) vs work (paid, must save) vs Codex (local, save)
- Where it breaks: useful → headache → unusable threshold

## Deliverables I Want

1. **The ONE router skill file** (markdown with frontmatter) that I can attach to ChatGPT web - it should:
   - On every invocation, Glob scan `.agents/*.md`, `.skillos/skills/*`, `system/skills/**/`, `.skillos-cache/**/SKILL.md`
   - Extract name/description/keywords
   - Score task vs skill descriptions (simple keyword overlap for chat, embedding if available for work/Codex)
   - Output JSON with selected 2-3 skills + reason + tokens saved
   - Log verdict HELPFUL/HARMFUL to `.skillos/verdicts.json` for future ranking

2. **Plan for each runtime:**
   - ChatGPT chat: how to attach skill, how to use canvas, how to persist index
   - ChatGPT work: how to handle token limits, hourly limits, how to keep router itself small (~400 tokens)
   - Codex: how to run locally with file system, git, python, how to symlink pool like mega-tron

3. **Future-proof strategy:**
   - How new skills auto-discovered without restart
   - How to handle skills and plugins both
   - How to auto-retire failing skills (3 HARMFUL)

4. **Attack your own plan:** Where does it break? When does it go from practical to headache?

## Constraints

- No abstract theory, give copy-paste commands and file paths
- Use what we already have: `/home/user/skillos/.agents/` (49), `.skillos/skills/` (108), `system/skills/SkillIndex.md` (29 skills table), `universal_runtime.py` (already provider-agnostic)
- Reference mega-tron ideas but don't require its daemon (130MB embedder) unless you justify
- Keep router skill itself small (<500 tokens) so it can always be loaded

## My Setup Now (for reference)

```
skillos/
├── .agents/ (49 universal)
├── .claude/agents/ (54)
├── .skillos/agents/ (49)
├── .skillos/skills/ (108 external)
├── .skillos-cache/ (4 repos, 113 SKILL.md)
├── system/skills/ (80 local, hierarchical)
├── universal_runtime.py (54 agents discovered, 170 skills, local mode)
├── daily_briefing.py (real HN API, no LLM)
└── findings/ (teamily.ai report)
```

I have 170 total skills/plugins, growing. I want ONE skill to rule them.

Give me plan + solution + router skill file.

---

End of prompt — paste into ChatGPT web to get plan.
