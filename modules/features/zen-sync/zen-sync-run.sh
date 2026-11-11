# shellcheck disable=SC2154
#
# Prefix supplied by Nix:
#   REAL_ZEN, PROC_NAME, ZEN_SYNC_BIN, META_BIN
#
# The launcher owns the Zen lifecycle so the session is only read or written
# while Zen is not holding it in memory.

set -uo pipefail

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/zen-sync"
PROFILE="${ZEN_PROFILE:-$HOME/.config/zen/default}"
LOG="$STATE/log"
LOCK="${XDG_RUNTIME_DIR:-$STATE}/zen-sync.lock"
QUIET="${QUIET:-0}"

mkdir -p "$STATE/backups"

log() {
  printf '%s %s\n' "$(date -Is)" "$*" >>"$LOG"
}

notify() {
  [ "$QUIET" = "1" ] && return 0
  notify-send -a "Zen Sync" "$@" >/dev/null 2>&1 || true
}

zen_running() {
  pgrep -x "$PROC_NAME" >/dev/null 2>&1
}

state_get() {
  cat "$STATE/$1" 2>/dev/null || true
}

state_set() {
  printf '%s\n' "$2" >"$STATE/$1"
}

session_hash() {
  local file="$PROFILE/zen-sessions.jsonlz4"
  [ -f "$file" ] || return 1
  sha256sum "$file" | cut -d' ' -f1
}

snapshot() {
  local dir
  dir="$STATE/backups/$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$dir"
  if [ -f "$PROFILE/zen-sessions.jsonlz4" ]; then
    cp -a "$PROFILE/zen-sessions.jsonlz4" "$dir/" 2>/dev/null || true
  fi
  if [ -f "$PROFILE/sessionstore-backups/recovery.jsonlz4" ]; then
    cp -a "$PROFILE/sessionstore-backups/recovery.jsonlz4" "$dir/" 2>/dev/null || true
  fi
  find "$STATE/backups" -mindepth 1 -maxdepth 1 -type d | sort | head -n -20 | xargs -r rm -rf
}

run_sync() {
  local action="$1"
  log "running zen-sync $action"
  timeout 120 "$ZEN_SYNC_BIN" "$action" >>"$LOG" 2>&1
}

remote_ts() {
  local out
  if ! out=$(timeout 60 "$META_BIN" 2>/dev/null); then
    echo error
    return
  fi
  if ! printf '%s' "$out" | python3 -c '
import json
import sys

try:
    data = json.load(sys.stdin)
except Exception:
    print("error")
    raise SystemExit(0)

print(data.get("timestamp") or "none")
' 2>/dev/null; then
    echo error
  fi
}

update_after_pull() {
  local hash ts
  hash=$(session_hash) && state_set last-pushed-hash "$hash"
  ts=$(remote_ts)
  if [ "$ts" != "error" ] && [ "$ts" != "none" ]; then
    state_set last-remote-ts "$ts"
  fi
}

update_after_push() {
  local hash ts
  hash=$(session_hash) && state_set last-pushed-hash "$hash"
  ts=$(remote_ts)
  if [ "$ts" != "error" ] && [ "$ts" != "none" ]; then
    state_set last-remote-ts "$ts"
  fi
}

consume_request() {
  local file="$STATE/request"
  [ -s "$file" ] || return 0

  local action
  action=$(head -n 1 "$file")
  rm -f "$file"

  case "$action" in
    pull | merge) printf '%s' "$action" ;;
  esac
}

sync_at_open() {
  local request
  request=$(consume_request)
  if [ -n "$request" ]; then
    snapshot
    if run_sync "$request"; then
      if [ "$request" = "pull" ]; then
        update_after_pull
      else
        local ts
        ts=$(remote_ts)
        if [ "$ts" != "error" ] && [ "$ts" != "none" ]; then
          state_set last-remote-ts "$ts"
        fi
      fi
      log "queued $request applied"
    else
      log "queued $request failed"
      notify "Sync failed" "Queued $request failed. See $LOG."
    fi
    return
  fi

  local ts
  ts=$(remote_ts)
  if [ -z "$ts" ] || [ "$ts" = "error" ]; then
    log "remote status failed; skipping open sync"
    return
  fi
  if [ "$ts" = "none" ]; then
    return
  fi
  if [ "$ts" = "$(state_get last-remote-ts)" ]; then
    return
  fi

  snapshot

  local hash last
  hash=$(session_hash) || hash=""
  last=$(state_get last-pushed-hash)

  if [ -z "$hash" ] || [ "$hash" = "$last" ]; then
    if run_sync pull; then
      update_after_pull
      log "pulled remote $ts"
    else
      log "pull failed"
      notify "Sync failed" "Pull failed. See $LOG."
    fi
  else
    if run_sync merge; then
      state_set last-remote-ts "$ts"
      log "merged remote $ts"
    else
      log "merge failed"
      notify "Sync failed" "Merge failed. See $LOG."
    fi
  fi
}

sync_at_close() {
  if [ ! -f "$PROFILE/zen-sessions.jsonlz4" ]; then
    log "no local session; skipping push"
    return 0
  fi

  local ts
  ts=$(remote_ts)
  if [ -z "$ts" ] || [ "$ts" = "error" ]; then
    log "remote status failed; skipping push"
    notify "Sync warning" "Could not reach R2; push skipped."
    return 0
  fi

  if [ "$ts" != "none" ] && [ "$ts" != "$(state_get last-remote-ts)" ]; then
    snapshot
    if run_sync merge; then
      state_set last-remote-ts "$ts"
      log "merged remote changes before push"
    else
      log "merge before push failed; skipping push"
      notify "Sync warning" "Merge failed; push skipped to avoid overwriting remote."
      return 0
    fi
  fi

  snapshot
  if run_sync push; then
    update_after_push
    log "pushed"
    return 0
  fi

  log "push failed"
  notify "Sync warning" "Push failed. It will retry later."
  return 1
}

wait_for_exit() {
  local i
  for i in $(seq 1 30); do
    zen_running || return 0
    sleep 0.5
  done
  log "Zen still running after wait; continuing"
}

wait_for_profile_lock() {
  local lock="$PROFILE/.parentlock"
  local i
  for i in $(seq 1 30); do
    if ! lsof "$lock" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.5
  done
  log "profile lock still held after wait; continuing"
}

close_zen() {
  zen_running || return 0
  log "closing Zen for sync"
  pkill -TERM -x "$PROC_NAME" 2>/dev/null || true
  wait_for_exit
  wait_for_profile_lock
}

flush() {
  QUIET=1
  if zen_running; then
    log "flush skipped: Zen running"
    return 0
  fi

  local hash last
  hash=$(session_hash) || hash=""
  last=$(state_get last-pushed-hash)
  if [ -n "$hash" ] && [ "$hash" = "$last" ]; then
    log "flush: clean"
    return 0
  fi

  sync_at_close
}

sync_now() {
  local action="$1"
  case "$action" in
    push | pull | merge) ;;
    *)
      echo "usage: zen-sync-run --sync-now <push|pull|merge>" >&2
      return 2
      ;;
  esac

  if zen_running; then
    echo "Zen is running; close it first." >&2
    return 1
  fi

  if [ "$action" = "push" ] && [ ! -f "$PROFILE/zen-sessions.jsonlz4" ]; then
    echo "No local Zen session to push." >&2
    return 1
  fi

  exec 9>"$LOCK"
  if ! flock -w 180 9; then
    echo "Another sync is already running." >&2
    return 1
  fi

  snapshot
  if ! run_sync "$action"; then
    notify "Sync failed" "$action failed. See $LOG."
    return 1
  fi

  case "$action" in
    pull)
      update_after_pull
      ;;
    merge)
      local ts
      ts=$(remote_ts)
      if [ "$ts" != "error" ] && [ "$ts" != "none" ]; then
        state_set last-remote-ts "$ts"
      fi
      ;;
    push)
      update_after_push
      ;;
  esac

  notify "Zen Sync" "$action complete."
}

restart_with() {
  local action="$1"
  case "$action" in
    pull | merge) ;;
    *)
      echo "usage: zen-sync-run --restart-with <pull|merge>" >&2
      exit 2
      ;;
  esac

  close_zen

  exec 9>"$LOCK"
  if ! flock -w 180 9; then
    notify "Sync failed" "Could not acquire sync lock."
    exit 1
  fi

  snapshot
  if ! run_sync "$action"; then
    notify "Sync failed" "$action failed. See $LOG."
    exit 1
  fi

  case "$action" in
    pull)
      update_after_pull
      ;;
    merge)
      local ts
      ts=$(remote_ts)
      if [ "$ts" != "error" ] && [ "$ts" != "none" ]; then
        state_set last-remote-ts "$ts"
      fi
      ;;
  esac

  flock -u 9
  exec 9>&-
  exec "$0"
}

case "${1:-}" in
  --flush)
    flush
    exit $?
    ;;
  --sync-now)
    shift
    if [ "$#" -ne 1 ]; then
      echo "usage: zen-sync-run --sync-now <push|pull|merge>" >&2
      exit 2
    fi
    sync_now "$1"
    exit $?
    ;;
  --restart-with)
    shift
    if [ "$#" -ne 1 ]; then
      echo "usage: zen-sync-run --restart-with <pull|merge>" >&2
      exit 2
    fi
    restart_with "$1"
    ;;
esac

if zen_running; then
  exec "$REAL_ZEN" "$@"
fi

exec 9>"$LOCK"
if ! flock -n 9; then
  exec "$REAL_ZEN" "$@"
fi

sync_at_open

"$REAL_ZEN" "$@" &
pid=$!

trap 'kill -TERM "$pid" 2>/dev/null || true' TERM INT
trap '' HUP

wait "$pid"
status=$?

wait_for_exit
wait_for_profile_lock
sync_at_close || true

exit "$status"
