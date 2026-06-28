# Clawcast — Claude Code plugin

A daily two-host podcast of what your Claude Code agents built. Same engine as the
`curl | bash` installer — just packaged as a managed plugin.

## What it does (identical to the install script)
- Registers **`SessionEnd`** + a **debounced `Stop`** hook that run the Clawcast
  generator on your machine.
- The generator (`generate.py`, fetched fresh from clawcast.fm each run) scans the
  last window of agent activity, writes the episode script with your own
  authenticated CLI, and ships **only the finished script** — never raw transcripts.
- A **`SessionStart`** hook mirrors your token into `~/.config/claudecast/credentials`.
- `/clawcast` forces an episode now (the plugin equivalent of the script's
  "generate your first episode immediately").

Cost is bounded the same four ways: the Stop debounce, `generate.py`'s
single-instance lock and 6h gate, and the backend's one-render-per-local-day cap.

## Why a plugin (vs the script)
- Token is stored in your **OS keychain** (`userConfig` → `sensitive`), not pasted
  into a shell one-liner.
- Clean install / update / uninstall via Claude Code — no editing `settings.json`.
- A real `/clawcast` slash command.

## Install
```
claude plugin marketplace add <this-repo-or-url>
claude plugin install clawcast@clawcast
```
You'll be prompted for your **Clawcast token** (from https://clawcast.fm). Set your
generation engine/model and voices at https://clawcast.fm/settings.

## Layout
```
.claude-plugin/plugin.json        manifest + userConfig (token, api)
.claude-plugin/marketplace.json   marketplace listing
hooks/hooks.json                  SessionStart / SessionEnd / Stop
hook.sh                           the runner (debounce, token sync, detached gen)
skills/clawcast/SKILL.md          /clawcast force-generate command
```
