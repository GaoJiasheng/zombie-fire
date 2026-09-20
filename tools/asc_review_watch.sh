#!/usr/bin/env bash
# Poll App Store review status and raise a macOS notification whenever it changes.
# Read-only; exits once the version leaves the waiting/in-review states.
#
#   nohup tools/asc_review_watch.sh >/dev/null 2>&1 &
#
# Log: ~/Library/Logs/zombiefire_asc_review.log  (a final line starts with TERMINAL)
set -uo pipefail

PROJ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG="${ASC_WATCH_LOG:-$HOME/Library/Logs/zombiefire_asc_review.log}"
INTERVAL="${ASC_WATCH_INTERVAL:-600}"
last=""

while true; do
    report="$(python3 "$PROJ/tools/asc_review_status.py" 2>/dev/null)" || report=""
    if [[ -n "$report" ]]; then
        summary="$(printf '%s\n' "$report" | grep -E '^(version|in-app purchases|  !)' | tr '\n' ' ')"
        if [[ "$summary" != "$last" ]]; then
            printf '%s %s\n' "$(date '+%F %T')" "$summary" >> "$LOG"
            [[ -n "$last" ]] && osascript -e "display notification \"$summary\" with title \"Zombie Fire 审核状态变化\" sound name \"Glass\"" >/dev/null 2>&1
            last="$summary"
        fi
        state="$(printf '%s\n' "$report" | sed -n '1s/.*: //p')"
        case "$state" in
            WAITING_FOR_REVIEW|IN_REVIEW|"") ;;
            *) printf 'TERMINAL %s %s\n' "$(date '+%F %T')" "$state" >> "$LOG"; exit 0 ;;
        esac
    fi
    sleep "$INTERVAL"
done
