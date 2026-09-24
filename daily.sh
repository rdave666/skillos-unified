#!/bin/bash
# Daily Useful - 1 command to run every morning
cd "$(dirname "$0")"

echo "=== DAILY - $(date) ==="
echo ""

echo "1. System status"
python3 universal_runtime.py status 2>&1 | tail -n 20
echo ""

echo "2. Generating daily briefing (Hacker News + GitHub trending)"
python3 daily_briefing.py 2>&1 | tail -n 30
echo ""

echo "3. Your teamily.ai findings (if any)"
ls -lh /home/user/findings/ 2>/dev/null
echo ""

echo "4. Quick daily commands:"
echo "  cat projects/Project_daily/output/$(date +%Y-%m-%d).md   # today's note"
echo "  python3 universal_runtime.py repl                      # interactive"
echo "  python3 universal_runtime.py execute \"your goal\"       # create project"
echo ""
echo "Done - today's file: projects/Project_daily/output/$(date +%Y-%m-%d).md"
