# Platform Install Prompts — skillos-unified (private repo)

Repo: `https://github.com/rdave666/skillos-unified` — PRIVATE, so every flow needs auth once:
`gh auth login`, or an SSH key added to GitHub, or a fine-grained PAT (scope: contents:read) in the clone URL.

---

## 1. LINUX (with Codex agent) — paste into codex

```
Install SkillOS Unified on this Linux machine. The repo is PRIVATE (rdave666/skillos-unified).

Run:
  export PATH="$HOME/.local/bin:$PATH"
  cd ~
  gh auth status || gh auth login
  [ -d skillos ] || git clone https://github.com/rdave666/skillos-unified.git skillos || git clone git@github.com:rdave666/skillos-unified.git skillos
  cd ~/skillos && bash install.sh

install.sh does everything: universal agents (.agents/ + .claude/agents/), 4 external skill repos,
mega-tron router (uv tool install, en-quality profile, unified pool + sync to ~/.codex/skills),
skill-router-agent.md, universal_runtime.py, daily_briefing.py.

Then verify and report actual output:
  python3 universal_runtime.py status
  mega-tron skills list | head
  python3 daily_briefing.py && cat projects/Project_daily/output/$(date +%Y-%m-%d).md

If a step fails: show the exact error, fix it, re-run. Do NOT clone from any other repo
besides rdave666/skillos-unified. If it can't authenticate, stop and tell me exactly what's missing.
```

---

## 2. WINDOWS — paste into PowerShell (Admin)

```
wsl --install -d Ubuntu-24.04
```
Reboot, open Ubuntu, then run the LINUX flow above inside WSL (mega-tron works — it's a real Linux).

**No-WSL fallback (reduced, no mega-tron — Unix sockets Linux/macOS only):**
```powershell
winget install git Git.Python.3.12
# new terminal:
git clone https://github.com/rdave666/skillos-unified.git C:\skillos
cd C:\skillos
pip install rich requests openai python-dotenv
python universal_runtime.py status
python daily_briefing.py
python universal_runtime.py execute "Create a tutorial on chaos theory"
```
Router works in keyword mode via `.agents/skill-router-agent.md`. `install.sh` itself: Git-Bash can run it with `SKIP_MEGATRON=1`, but WSL is the supported path.

---

## 3. ANDROID PHONE with agent (Codex mobile app / any shell-capable agent) — paste into the agent

```
You are on a cloud sandbox. Install my private SkillOS and use it once:

1. Authenticate to GitHub (use my connected account, or the PAT I provide).
2. git clone https://github.com/rdave666/skillos-unified.git skillos && cd skillos
3. bash install.sh
4. python3 daily_briefing.py
5. Reply me with: the universal_runtime.py status output + the full daily briefing markdown.
6. Commit the daily briefing back to the repo so it persists after this sandbox dies:
   git add projects/ && git commit -m "daily $(date +%F) from android" && git push

Repo is private (rdave666/skillos-unified) — if auth fails, stop and tell me, do not use any other repo.
```
Note: sandbox FS is ephemeral — step 6 (agent pushes to your repo) is what makes phone results survive.

---

## 4. ANDROID PHONE on Termux, NO agent — paste line by line

```bash
# base
pkg update -y && pkg install -y git python curl

# auth once (pick ONE):
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519 && cat ~/.ssh/id_ed25519.pub
#   -> add that key at github.com Settings > SSH keys
# or: git clone https://rdave666:<FINE-GRAINED-PAT>@github.com/rdave666/skillos-unified.git skillos

git clone git@github.com:rdave666/skillos-unified.git skillos
cd skillos
SKIP_MEGATRON=1 bash install.sh   # mega-tron needs Linux glibc+torch; Termux skips it, router runs keyword mode

# use it
python3 universal_runtime.py status
python3 universal_runtime.py execute "Create a tutorial on chaos theory"
python3 daily_briefing.py && cat projects/Project_daily/output/$(date +%Y-%m-%d).md

# optional daily at 09:00 without agent:
pkg install -y termux-api && termux-wake-lock
(echo "0 9 * * * cd ~/skillos && python3 daily_briefing.py"; crontab -l 2>/dev/null) | crontab -
```

---

## What differs per platform

| | clone auth | mega-tron | install.sh | router mode | persistence |
|---|---|---|---|---|---|
| Linux+Codex | gh auth | ✅ full (embeddings, dashboard) | ✅ full | semantic top-K | disk |
| Windows (WSL) | gh auth | ✅ via WSL | ✅ full | semantic | disk |
| Windows (native) | git PAT | ❌ skipped | ⚠️ Git-Bash SKIP_MEGATRON=1 | keyword | disk |
| Android + agent | sandbox GitHub/PAT | ⚠️ sandbox Linux, works but ephemeral | ✅ full | semantic | only via push-back |
| Android Termux | ssh key / PAT in URL | ❌ (SKIP_MEGATRON=1 forced) | ✅ guarded | keyword | disk (app-private) |

All four get: 51 agents in `.agents/`, 108 skills, skill-router-agent, universal_runtime.py, daily_briefing.py.
