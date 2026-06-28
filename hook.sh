#!/bin/sh
# Clawcast plugin hook — identical behavior to the install script's hook:
#   • SessionStart : mirror the plugin's stored token into the credentials file
#                    generate.py reads (no generation).
#   • SessionEnd   : generate the episode.
#   • Stop         : generate, but debounced to <= once/hour so a busy session
#                    can't spawn it every turn.
#   • generate     : forced run (used by the /clawcast slash command).
#
# The token comes from the plugin's userConfig (OS keychain) as
# $CLAUDE_PLUGIN_OPTION_TOKEN. Cost is bounded exactly as with the script: the
# Stop debounce here, plus generate.py's single-instance lock + 6h gate, plus the
# backend's one-render-per-local-day cap. The heavy work is detached so the 10s
# hook timeout can't kill an in-flight generation.
set -u

D="$HOME/.config/claudecast"
mkdir -p "$D"
API="${CLAUDE_PLUGIN_OPTION_API:-https://clawcast.fm}"
TOKEN="${CLAUDE_PLUGIN_OPTION_TOKEN:-}"
EVENT="${1:-}"

# Keep the credentials file in sync with the keychain-stored token, so generate.py
# (and the slash command) always have it.
if [ -n "$TOKEN" ]; then
  printf 'CLAUDECAST_TOKEN=%s\n' "$TOKEN" > "$D/credentials"
  chmod 600 "$D/credentials" 2>/dev/null || true
fi

# Apply the install-time engine choice (claude|codex) to the backend ONCE — and
# again only if it changes — so it sets the initial engine without overriding a
# later choice the user makes on the website.
ENGINE="${CLAUDE_PLUGIN_OPTION_ENGINE:-}"
[ "$ENGINE" = "codex" ] && ENGINE="openai"
if [ -n "$TOKEN" ] && { [ "$ENGINE" = "claude" ] || [ "$ENGINE" = "openai" ]; }; then
  if [ "$(cat "$D/.engine_init" 2>/dev/null)" != "$ENGINE" ]; then
    curl -fsS --max-time 10 -X POST "$API/api/settings" \
      -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
      -d "{\"gen_engine\":\"$ENGINE\"}" >/dev/null 2>&1 && printf '%s' "$ENGINE" > "$D/.engine_init"
  fi
fi

# SessionStart only syncs the token + engine above — never generates.
[ "$EVENT" = "SessionStart" ] && exit 0

# Stop fires every turn on a busy session; debounce to once an hour.
if [ "$EVENT" = "Stop" ]; then
  [ -z "$(find "$D/.stoptick" -mmin -60 2>/dev/null)" ] || exit 0
  touch "$D/.stoptick"
fi

FORCE=""
[ "$EVENT" = "generate" ] && FORCE=1   # /clawcast: bypass the 6h gate for an immediate episode

# Detach: fetch the latest generator and run it in the background, then return so
# the hook doesn't block (or get killed at the 10s timeout).
export CLAUDECAST_API="$API" CLAUDECAST_TOKEN="$TOKEN" CLAUDECAST_FORCE="$FORCE"
nohup sh -c 'curl -fsSL --max-time 30 "$CLAUDECAST_API/client/generate.py" | python3 -' >> "$D/run.log" 2>&1 &
exit 0
