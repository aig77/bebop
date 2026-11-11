# shellcheck disable=SC2154
#
# Prefix supplied by Nix:
#   PROC_NAME
#
# The menu is intentionally small. Lifecycle work belongs to zen-sync-run.

set -uo pipefail

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/zen-sync"
LOG="$STATE/log"

mkdir -p "$STATE"

notify() {
  notify-send -a "Zen Sync" "$@" >/dev/null 2>&1 || true
}

zen_running() {
  pgrep -x "$PROC_NAME" >/dev/null 2>&1
}

choice=$(
  printf '%s\n' \
    "Status" \
    "Push now" \
    "Pull now (restart Zen)" \
    "Merge now (restart Zen)" \
    "Queue pull for next start" \
    "Queue merge for next start" |
    fuzzel --dmenu --prompt "Zen Sync: " --width 40
) || exit 0

case "$choice" in
  "Status")
    output=$(timeout 60 zen-sync status 2>&1 | sed -e 's/\x1b\[[0-9;]*m//g' | head -n 20) || output="Status failed. See $LOG."
    notify "Zen Sync status" "$output"
    ;;

  "Push now")
    if zen_running; then
      notify "Zen Sync" "Zen is running. It will push when you close it."
    elif timeout 130 zen-sync-run --sync-now push >/dev/null 2>&1; then
      notify "Zen Sync" "Push complete."
    else
      notify "Zen Sync" "Push failed. See $LOG."
    fi
    ;;

  "Pull now (restart Zen)")
    answer=$(
      printf '%s\n' "Cancel" "Yes, restart and pull" |
        fuzzel --dmenu --prompt "This replaces local state. Continue? " --width 40
    ) || exit 0
    [ "$answer" = "Yes, restart and pull" ] || exit 0
    notify "Zen Sync" "Restarting Zen and pulling..."
    setsid zen-sync-run --restart-with pull >/dev/null 2>&1 </dev/null &
    ;;

  "Merge now (restart Zen)")
    answer=$(
      printf '%s\n' "Cancel" "Yes, restart and merge" |
        fuzzel --dmenu --prompt "Merge remote into local? " --width 40
    ) || exit 0
    [ "$answer" = "Yes, restart and merge" ] || exit 0
    notify "Zen Sync" "Restarting Zen and merging..."
    setsid zen-sync-run --restart-with merge >/dev/null 2>&1 </dev/null &
    ;;

  "Queue pull for next start")
    printf 'pull\n' >"$STATE/request"
    notify "Zen Sync" "Pull queued. Restart Zen to apply."
    ;;

  "Queue merge for next start")
    printf 'merge\n' >"$STATE/request"
    notify "Zen Sync" "Merge queued. Restart Zen to apply."
    ;;
esac
