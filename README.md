# Argus



### Motivation

Running several MCP servers and AI-related local services at once made it tedious to keep track of what's actually up - checking status, restarting, or stopping any of them meant switching to a terminal and remembering the right command for each one. Argus puts all of that in one menu bar icon: status at a glance, one click for the common actions, no terminal needed.

### Basis: SwiftBar

Argus is a plugin for [SwiftBar](https://github.com/swiftbar/SwiftBar) - it does the actual work of turning a shell script's output into a live-updating macOS menu bar item, on a timer, with clickable actions. None of this would exist without it - thank you to its maintainers and contributors.

### Built with Claude

Every decision in Argus - what to monitor, how each menu should behave, which edge cases actually mattered, what felt wrong and needed fixing - came out of many rounds of hands-on testing and iteration by the author. Claude Code wrote the actual shell/Python under that direction, as a pair-programming tool rather than an autonomous author. Worth saying plainly, since that's the honest shape of how this got built.

### Overview

One macOS menu bar icon that monitors and controls local/remote services in one place. At the moment a local `mcp-proxy` (hosts MCP servers over HTTP/SSE), ComfyUI, a local llama.cpp server used for code fill-in-the-middle completion, a remote Forgejo/Gitea MCP server, a remote Home Assistant MCP webhook, and two local macOS apps (Paste, Open WebUI) that each expose their own MCP server are implemented.

Each service gets its own submenu: status (via SF Symbol shape, not color - matches native macOS style), Start/Stop/Restart/Activate/Deactivate where applicable, an Update button when a newer version is actually available, and read-only info (version, loaded models, hosted MCP servers, ...).

MCP Proxy's submenu also has a "Claude Verbindung" entry per hosted MCP server, showing whether it's currently registered in Claude Code's user-scope config and letting you connect/disconnect it with one click (`claude mcp add`/`remove -s user`) - without running `claude mcp list`, which does a live health check per server and takes a few seconds.

### This is a personal, opinionated setup

This repo is published as a reference/starting point, not a plug-and-play install for someone else's machine. The services monitored, and most paths/ports/URLs used to reach them, are specific to how the author runs these tools locally. To adapt this to your own setup:

- Personal-but-not-secret values (your dev path, ComfyUI's launchd label, Forgejo/Gitea and Home Assistant hostnames, the `claude` CLI path) live in `lib/config.local.sh`, which is gitignored and never committed. Copy `lib/config.example.sh` to `lib/config.local.sh` and fill in your own values - see that file for what each one means. Without it, Argus still runs off the tracked `config.example.sh` placeholders, just with a non-functional Gitea/HA entry, no "Claude Verbindung" connect/disconnect actions, and no "Argus Version" footer link.
- Genuine secrets - anything where knowing the value alone grants access, not just an address - go in the macOS Keychain instead, see [Credentials](#credentials). This currently covers the Paste bearer token, the Open WebUI API key, and the Home Assistant webhook URL (a webhook's ID *is* its access credential, unlike a plain hostname).
- Beyond that, each `services/*.sh` still hardcodes things like ports and install paths for that one service (e.g. ComfyUI's/mcp-proxy's install location) - edit these directly, or delete/replace the services you don't run yourself. See [Adding a new service](#adding-a-new-service) below for the shape a service file follows.

### About this branch

Development happens on `main` in a private repository; what you're looking at here is `public` - a separate, orphan branch (no shared git history with `main`) that gets snapshotted from `main`'s current state automatically on every push. That split exists because `main`'s early history briefly had personal paths/hostnames inline, before the `lib/config.local.sh`/Keychain separation described above - `public` only ever contains clean, current snapshots, never that history. If you're reading this on GitHub, you're on a mirror of `public`; there's no `main` branch here.

The sync itself runs as a Forgejo Actions workflow (`.forgejo/workflows/sync-public.yml`, private-repo-only - not part of `public`/this mirror) triggered on every push to `main`, followed by a Forgejo push mirror that forwards `public` to GitHub. Neither step needs a manual trigger.

### Requirements

- macOS
- [SwiftBar](https://github.com/swiftbar/SwiftBar) - beta 2.1.2 or newer recommended (fixes a menu-item-greying rendering bug present in 2.1.1)
- [`terminal-notifier`](https://github.com/julienXX/terminal-notifier) (`brew install terminal-notifier`) - used instead of plain `osascript` notifications because it lets the native "Show" button macOS adds to every notification be wired to something useful (`-execute` opens the relevant folder) and lets the notification appear under SwiftBar's own name/icon (`-sender`); a plain `osascript` notification's "Show" button just opens Script Editor pointlessly
- `python3` (used for JSON parsing throughout)

## Setup

Just want to run it? Clone (or copy) this repo directly into place - no symlinks needed - then point SwiftBar's plugin folder (SwiftBar Preferences) at `<wherever-you-cloned-it>/plugins`:

```bash
git clone <this-repo-url> ~/.local/share/swiftbar
```

Then set up [Configuration](#configuration)/[Credentials](#credentials) and edit `services/*.sh` for your own setup (see [above](#this-is-a-personal-opinionated-setup)), and restart SwiftBar:

```bash
osascript -e 'quit app "SwiftBar"'; sleep 2; open -a SwiftBar
```

### Development setup

If you're going to keep editing this (which is how the author actually runs it): keep the repo wherever you normally do your development work, and symlink the individual files into `~/.local/share/swiftbar/` instead of cloning straight into it. That way edits in your normal dev location take effect immediately (next refresh, or "Letztes Update" in the menu) with no extra copy/sync step, while SwiftBar itself only ever looks at `~/.local/share/swiftbar/`.

```bash
DEV="$(pwd)"                    # wherever you keep the dev copy of this repo
RT="$HOME/.local/share/swiftbar"
mkdir -p "$RT"/{plugins,helpers,lib,services}
ln -sf "$DEV/plugins/argus.30s.sh" "$RT/plugins/argus.30s.sh"
for f in "$DEV"/helpers/*.sh;  do ln -sf "$f" "$RT/helpers/$(basename "$f")";  done
for f in "$DEV"/lib/*.sh;      do ln -sf "$f" "$RT/lib/$(basename "$f")";      done
for f in "$DEV"/services/*.sh; do ln -sf "$f" "$RT/services/$(basename "$f")"; done
```

### Configuration

Copy `lib/config.local.sh` from the tracked template and fill in your own values:

```bash
cp lib/config.example.sh lib/config.local.sh
```

`lib/config.example.sh` documents what each value means. This file is gitignored - it never gets committed, in either the just-run-it or the development setup above.

### Credentials

Genuine secrets - anything where knowing the value alone grants access - are read from the macOS login Keychain at runtime instead, never stored in this repo or in `config.local.sh`:

```bash
# Paste MCP - generate in Paste's own settings
security add-generic-password -a "$USER" -s "swiftbar-paste-mcp-token" -w "<token>" -U

# Open WebUI - API key from Settings > Account > API Keys (used only for a
# read-only "is a newer app version available?" check, not a trigger)
security add-generic-password -a "$USER" -s "swiftbar-openwebui-api-key" -w "<key>" -U

# Home Assistant - the full URL of a webhook trigger you've set up
# (Settings > Automations & Scenes > create/open an automation with a
# "Webhook" trigger to get its URL). Its ID is the entire access
# credential - there's no separate token to send alongside it.
security add-generic-password -a "$USER" -s "swiftbar-ha-webhook-url" -w "<url>" -U
```

## Structure

| Path | Purpose |
|---|---|
| `plugins/argus.30s.sh` | The actual SwiftBar plugin (`.30s.` = 30s refresh interval). Orchestrator only - sources `lib/` and `services/`, calls each `service_<name>`, prints header/footer/notifications. |
| `services/*.sh` | One file per monitored service, each defining a single `service_<name>()` function: fetch state, print menu lines. |
| `lib/core.sh` | Constants (`SF_*` status icons, `SEP`, `STATE_DIR`, ...), menu-building primitives (`add()`, `note_top_sf()`), shared action-button logic (`add_service_actions()`, `app_state_sf()`). |
| `lib/queries.sh` | Shared query/probe helpers: `launchd_info()`, `mcp_probe()`, `pypi_latest_version()`, `git_remote_head()`, `owui_latest_version()`. |
| `lib/text.sh` | Pure formatting/local-lookup helpers (`gb()`, `npx_package_version()`). |
| `lib/json.sh` | Generic single-field JSON extraction (`json_field()`) for the common "pull a few fields out of one object" shape. Array filtering/counting/row-building stays inline per service - too different per endpoint to generalize usefully. |
| `lib/strings.sh` | Every user-visible menu/notification string. Change or translate the UI here, nowhere else. |
| `lib/config.example.sh` | Tracked template for personal-but-not-secret config (dev path, launchd labels, service hostnames) - see [Configuration](#configuration). |
| `lib/config.local.sh` | Your own copy of the above, gitignored, never committed. |
| `helpers/*.sh` | Standalone scripts invoked by SwiftBar's `bash=` click actions - a menu item can't run inline shell, only call an executable file. |
| `.forgejo/workflows/sync-public.yml` | Private-repo-only automation (see [About this branch](#about-this-branch)) - not part of `public`/this mirror. |

## Adding a new service

1. Create `services/<name>.sh` with one `service_<name>()` function: fetch state, `add "Label | sfimage=..."`, action lines, a separator, info lines. Use `lib/strings.sh` variables for all text, not literals.
2. `source` it in `plugins/argus.30s.sh` and add the call in the ordering block (services are called alphabetically by display name).
3. Any click action needs its own file under `helpers/`, an entry in `EXPECTED_HELPERS` in `plugins/argus.30s.sh` (the misconfiguration-notification check depends on it), and a runtime symlink.
4. New UI text goes into `lib/strings.sh` as `STR_<SCOPE>_<PURPOSE>` (dynamic parts as `%s`, filled via `printf`).

## Key conventions

- SwiftBar line syntax: `Title | param1=value param2=value`. No leading dash = a top-level item; `--` = one submenu level deep, `----` = two levels, etc.
- A separator line **within** a submenu needs exactly `-----` (5 dashes) - 4 dashes render as literal text, live-verified against SwiftBar. A top-level separator (between the header and the dropdown, or between dropdown sections) is `---` (3 dashes) instead.
- There is no `disabled=` parameter in SwiftBar - an action that doesn't currently apply is omitted from the menu entirely rather than greyed out.
- Helper/lib/service scripts must live outside `plugins/` - SwiftBar scans that folder and tries to load every file in it as its own separate menu bar icon.
- For the three launchd-managed services (MCP Proxy, ComfyUI, llama FIM): while registered with launchd, only Restart + Deactivate are offered (KeepAlive is active for all three, so a plain Stop would just be undone by launchd within seconds). Once deactivated, Activate is always available, plus a one-time manual Start/Stop of the bare process via `manual_launchd_start.sh`/`manual_launchd_stop.sh`, independent of launchd.

## Testing a change

```bash
bash -n plugins/argus.30s.sh lib/*.sh services/*.sh helpers/*.sh   # syntax check
~/.local/share/swiftbar/plugins/argus.30s.sh                       # dry-run, raw menu output
osascript -e 'quit app "SwiftBar"'; sleep 2; open -a SwiftBar      # reload
```

## License

[MIT](LICENSE)
