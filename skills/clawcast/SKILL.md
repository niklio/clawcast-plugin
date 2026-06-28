---
description: Clawcast — generate today's podcast episode right now (force a fresh run) and show the result.
disable-model-invocation: true
---

The user wants to generate their Clawcast episode immediately (bypassing the every-6h gate).

Do exactly this:

1. Run:
   `sh -c 'curl -fsSL --max-time 30 https://clawcast.fm/client/generate.py | CLAUDECAST_FORCE=1 python3 -' && sleep 1 && tail -n 6 "$HOME/.config/claudecast/run.log"`

   (The token is read from `~/.config/claudecast/credentials`, which the plugin keeps in sync with the token you set when enabling it.)

2. Tell the user their episode is being generated locally and will appear at https://clawcast.fm within a few minutes. If the log shows an error about a missing token, tell them to set the **Clawcast token** in the plugin's config (re-enable the plugin and paste the token from https://clawcast.fm).

$ARGUMENTS
