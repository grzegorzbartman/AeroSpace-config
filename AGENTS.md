# AGENTS.md

## What Is Makaron

Makaron is a macOS desktop environment manager for focused, keyboard-driven work. It orchestrates AeroSpace for tiling windows, SketchyBar as a fixed top status bar, Ghostty as the terminal, and install/update scripts for AI tools and optional developer tooling.

The desktop layout defaults to 12px window gaps, a persistent user setting. Full UI mode reserves the 40px SketchyBar height plus the configured gap on screens without a notch. SketchyBar is a floating liquid-glass bar (margin, corner radius, blur, 1px specular border, SF Pro labels) with an appearance-aware light/dark palette in `configs/sketchybar/colors.sh`. The bar's `y_offset=4` in sketchybarrc must match `MAKARON_BAR_Y_OFFSET` in `bin/makaron-ui-helpers` - it is part of the window `outer.top` math.

## General Guidelines
- Read this file for context before making changes.
- Ask 2-6 clarifying questions before implementing changes when requirements are unclear.
- If something doesn't work after 2-3 iterations, search Google using MCP Playwright.

## Contribution Workflow (Default)
Unless the user says otherwise, every change follows this flow:
- Never commit directly to `main`. Create a feature branch first (e.g. `feat/...`, `fix/...`).
- Before committing, run the pre-commit review (`.agents/skills/pre-commit-review/SKILL.md`):
  - Read this file, then `git status` and `git diff`.
  - Check for breakage risk for both new and existing users (the `makaron-update` path and `migrations/` folder).
  - Check that new keyboard shortcuts don't conflict with Polish characters (lowercase and uppercase: ą, ć, ę, ł, ń, ó, ś, ź, ż, Ą, Ć, Ę, Ł, Ń, Ó, Ś, Ź, Ż).
- Push the branch and open a Pull Request, then return the PR link to the user.

## Releasing

Full runbook: `docs/RELEASING.md`. Short version:
- Versions are git tags (`vX.Y.Z`), no VERSION file. `makaron-update` on the default `stable` channel resets the installed repo to the latest tag; `edge` follows `origin/main`.
- Semver: **patch** = bug fixes; **minor** = features, new `makaron.conf` variables, migrations; **major** = breaking changes or manual steps required.
- Cut a release after the PR merges and CI is green on `main`:

```bash
gh release create vX.Y.Z --target main --generate-notes
```

- Verify on an installed machine: `makaron-update` should show the new tag as target, then `Already up to date` on a second run; `makaron-version` prints the tag.
- Never tag a commit that predates the channel-aware `makaron-update` (stable users reset to that tag would lose the channel mechanism). Tag only current `main`.
- Merging a PR does NOT ship it to stable users - only tagging does. Batch merged PRs into a release deliberately.

## Code Style
- Short, concise shell scripts - no verbose comments.
- DRY and SOLID principles.
- Commit frequently with single-line messages when the user asks for commits.

## Installation & Updates
- Support both fresh installs and updates.
- Install scripts handle their own symlinks - detect and fix wrong targets automatically.
- Scripts must be idempotent.

### Helper Functions (`install/helpers.sh`)
Use these helpers in install scripts - they handle idempotency and errors gracefully:

```bash
# For GUI apps (casks) - skips if already in /Applications
install_cask "cask-name" "App Name"

# For CLI tools - continues on failure
install_formula "formula" "Display Name" "command-to-check"

# For critical CLI tools - exits on failure with CLT fix instructions
install_formula_critical "formula" "Display Name" "command-to-check"
```

**Important:** Never use `exit` in sourced scripts - use `return` instead, or the entire installation will stop.

**Tap trust:** Homebrew >= 6.0 will not load a non-official tap until it is trusted. Always pass the tap-qualified name (`user/tap/name`) to the install helpers - they call `brew_trust` for you, and Homebrew also self-trusts a qualified install. Short names from a third-party tap silently fail. External tap commands (e.g. `brew autoupdate`) cannot self-trust and need an explicit `brew trust --command user/tap/command`.

**Homebrew paths:** Always use `$(brew --prefix)` instead of hardcoded paths like `/opt/homebrew` - supports Apple Silicon, Intel, and local installs.

### Swift Binaries (`src/`)
Makaron compiles small Swift helpers (e.g. `swiftc -O -o bin/makaron-memory-stats src/memory_stats.swift`):

- Source files: `src/*.swift`
- Compiled binaries: `bin/` (gitignored)
- Compilation runs automatically during `install/desktop/sketchybar.sh`

### Why Swift
- `memory_stats.swift` uses Mach `host_statistics64` API to match Activity Monitor exactly. Shell-based alternatives (`vm_stat`, `top`) give inaccurate numbers.
- `has_notch.swift` reads `NSScreen.safeAreaInsets` for notch detection (compiled to avoid the ~1s `swift -e` cold start).
- `storage_stats.swift` uses `volumeAvailableCapacityForImportantUsage` to count purgeable space (e.g. Time Machine local snapshots) as free, matching Finder. `df` treats purgeable as used and over-reports.
- `help_window.swift` is the shortcut overlay panel (`bin/makaron-help-window`): borderless NSPanel + WKWebView over NSVisualEffectView glass; AeroSpace ignores non-standard panels so it is never tiled.

---

## User Commands (`bin/`)

All commands are in `bin/` and added to `$PATH` during install.

### UI Mode Commands
Two mutually exclusive modes, persisted in `~/.local/state/makaron/ui-mode`:

| Command | Components | Dock | Menu Bar |
|---|---|---|---|
| `makaron-ui-full` | AeroSpace + SketchyBar | Hidden (autohide) | Hidden (autohide) |
| `makaron-ui-stop` | Nothing | Visible | Visible |

- `makaron-ui-helpers` is a shared library, not a user command. It contains AeroSpace, SketchyBar, layout, macOS settings, and UI mode helpers.

### Layout Commands
- `makaron-gaps <0-40>` and `makaron-gaps-zero` - Persist and apply AeroSpace gaps.
- `makaron-help` - Keyboard shortcut overlay (bound to alt-shift-slash; also left click on the bar's M mark). The panel has a macOS-style close button; esc, click-away, or a second invocation also close it. Parses the live generated AeroSpace config (user overrides included) into HTML and shows it in the `makaron-help-window` glass panel; unknown user commands render verbatim. Second invocation closes the panel (toggle); falls back to the browser when the binary is missing. `--print-html` writes the HTML to stdout (tests).

### System Commands
- `makaron-update` - Resets installed repo to the latest release tag (`stable` channel, default) or `origin/main` (`edge`), runs migrations, reloads UI. `--stable`/`--edge` persist the channel in `MAKARON_CHANNEL` (makaron.conf).
- `makaron-version` - Prints `git describe` version and update channel.
- `makaron-reinstall` - Removes `~/.local/share/makaron/`, re-clones, re-installs.
- `makaron-select-packages` - Re-run optional package selection UI (gum-based).
- `makaron-reload-aerospace-sketchybar` - Reloads AeroSpace + SketchyBar and re-applies layout state.
- `makaron-macos-config-reload` - Re-applies macOS settings from `install/macos_settings.sh`.
- `makaron-doctor` - Concise health check with optional safe repairs.
- `makaron-uninstall` - Full uninstall: stops UI, restores defaults from `~/.local/state/makaron/defaults-snapshot/` (write-once snapshot taken by `install/macos_settings.sh`; key registry in `install/defaults-registry.sh`), removes symlinks/PATH/services/repo. Flags: `-y`, `--keep-packages`, `--dry-run`.

### Development Commands
- `makaron-dev-add-migration` may not exist in every checkout. If absent, create a timestamped migration manually in `migrations/`.

---

## UI Modes Detail

### AeroSpace Layout
`switch_aerospace_config()` in `makaron-ui-helpers` updates `outer.top` in `~/.aerospace.toml`.

All five regular gap fields use `AEROSPACE_GAP_SIZE` (default `12`): `inner.horizontal`, `inner.vertical`, `outer.left`, `outer.bottom`, and `outer.right`.

For gap `g`, bar height `h`, bar y-offset `y` (4) and notch-strip height `i` (from `makaron-has-notch`), the top reserve is:
- **Full mode + no notch:** `outer.top = h + y + g`
- **Full mode + built-in notch:** `outer.top = [{ monitor."Built-in" = g + max(0, h + y - i) }, h + y + g]` - the overhang term keeps a full gap below the bar, which extends past the notch strip.

Notch detection uses `NSScreen.safeAreaInsets.top`, never model names. MacBook Neo and MacBook Air M1 built-in displays are handled as screens without a notch. External monitors are always handled without a notch. Display changes invalidate the cache and reapply the same persisted gap.

The function resolves the symlink target before editing to modify the actual config file.

### macOS Settings Per Mode
- **Full**: dock autohide, window grouping on (required for AeroSpace), Three Finger Drag off (enables Mission Control), menu bar autohide.
- **Stop**: dock visible, window grouping off, Three Finger Drag on (restored).

### Menu Bar Autohide
`_set_menubar_autohide()` uses AppleScript to quit and reopen System Settings on the Menu Bar pane, find the dropdown by its current value, then apply a toggle trick (opposite value first, then target). macOS ignores `defaults write` and `CFPreferences` for this setting - UI click is the only reliable method.

---

## SketchyBar Plugins

### Architecture
Plugins live in `configs/sketchybar/plugins/`. Each plugin follows this pattern:
1. Load the colors: `source "$CONFIG_DIR/colors.sh"`
2. Get data (system call, compiled binary, etc.)
3. Update SketchyBar: `sketchybar --set "$NAME" icon="..." label="..." icon.color=$COLOR`

### Color Format
All colors use ARGB hex: `0xffRRGGBB` (ff = fully opaque). `configs/sketchybar/colors.sh` resolves the brand palette (see `assets/branding/COLORS.md`: Ink/Cream glyphs, Blue #0d6efd focus, Amber update dot, Red alerts) from the system appearance (`defaults read -g AppleInterfaceStyle`): light and dark liquid-glass variants, each with the matching system blue (`007aff` light / `0a84ff` dark). `plugins/appearance_change.sh` (hidden `appearance_check` item, 10s poll) reloads the bar when the appearance flips.

### SketchyBar Color Variables
`configs/sketchybar/colors.sh` exports:

```bash
# Bar
BAR_COLOR, BAR_BACKGROUND_COLOR, BAR_BLUR, BAR_BORDER_COLOR
# Items
ICON_COLOR, LABEL_COLOR
# Workspaces (inactive)
SPACE_ICON_COLOR, SPACE_LABEL_COLOR, SPACE_BACKGROUND_COLOR, SPACE_BORDER_COLOR
# Workspaces (focused)
SPACE_FOCUSED_ICON_COLOR, SPACE_FOCUSED_LABEL_COLOR, SPACE_FOCUSED_BACKGROUND_COLOR, SPACE_FOCUSED_BORDER_COLOR
# Threshold alerts (cpu/memory/storage pills, low battery)
ALERT_COLOR, ALERT_BACKGROUND_COLOR
# Update pill (solid brand amber, ink text; same in both modes)
UPDATE_COLOR, UPDATE_BACKGROUND_COLOR
```

### Key Plugins
- **makaron_menu.sh** - Version label for the `makaron_logo` popup (the bar's "Apple menu": outline M mark from `configs/sketchybar/assets/`, first item on the left, gated by `SKETCHYBAR_LOGO`; left click opens the shortcut overlay via `plugins/makaron_logo_click.sh`, right click opens the popup: Shortcuts / Update / Doctor / Reload bar).
- **aerospace.sh** - Workspace indicator with animated (`--animate sin 12`) three-level hierarchy: focused = accent pill + app icons, occupied = quiet pill + app icons, empty = bare dimmed number. Icons use Nerd Font. Multi-monitor aware via `$MONITOR` parameter. On `aerospace_workspace_change` it only refreshes workspaces matching `$FOCUSED_WORKSPACE` or `$PREV_WORKSPACE`; all other senders fall through to the full refresh path. Honors `SKETCHYBAR_HIDE_EMPTY_WORKSPACES` from `makaron.conf` (focused workspace is always drawn).
- **battery.sh** - Battery status with low-threshold warning from `makaron.conf`.
- **memory.sh** - Calls compiled Swift binary `makaron-memory-stats`, shows `X/Y GB`.
- **cpu.sh** / **memory.sh** - Always visible (CPU percent, memory `X/Y GB`); label turns `ALERT_COLOR` above `CPU_ALERT_THRESHOLD` / `MEMORY_ALERT_THRESHOLD` (80%).
- **storage.sh** - Threshold alert: invisible below `STORAGE_ALERT_THRESHOLD` (90%); above, an `ALERT_*`-tinted pill appears. Used% comes from `makaron-storage-stats` (Finder-style, purgeable counts as free) with a `df` fallback.
- **volume.sh** - Detects Bluetooth vs speakers (caches `system_profiler` result for 5s), different icons. Icon-only at rest; a volume change or output-device switch lights the section in the accent color with the percent label for 3s, then eases back.
- **update_check.sh** - `makaron_update` item: amber "Update" pill on the left next to the M mark, hidden unless the installed repo is behind its channel target (fetches every 4h and on wake); click runs `makaron-update` in Ghostty. Colors from `UPDATE_COLOR`/`UPDATE_BACKGROUND_COLOR`.
- **display_change.sh** - Invalidates display caches and reapplies layout on every display topology change; reloads SketchyBar when monitor count changes.

### SketchyBar Plugin Conventions
- `$NAME` - item name (set by SketchyBar, identifies which item to update).
- `$INFO` - event data (e.g. volume percentage on `volume_change`).
- Events subscribed via: `--subscribe item_name event_name`.
- Click handlers: `click_script="aerospace workspace $sid"`.

---

## Install Flow

```text
curl -sL install.sh | bash
       |
   install.sh         # Git clone/pull, then runs main.sh FROM FILE (not pipe)
       |
   install/main.sh    # Sources all.sh, sets up PATH in .zshrc/.bashrc, chmod +x bin/
       |
   install/all.sh     # Orchestrates mandatory + optional installs:
       |
       |-- install/mandatory.sh      # Always installed:
       |     |-- helpers.sh
       |     |-- makaron-conf.sh
       |     |-- brew.sh
       |     |-- gum, jq
       |     |-- desktop/ (aerospace, aerospace-swipe, sketchybar, fonts)
       |     |-- terminal/ghostty.sh
       |
       |-- install/packages.sh       # Optional packages:
       |     |-- Fresh install: gum UI per-app selection (5 groups)
       |     └── Update/reinstall: installs from ~/.config/makaron/packages.conf
       |
       |-- macos_settings.sh
       └── migrations.sh
```

**Key detail**: `install.sh` runs `bash "$MAKARON_PATH/install/main.sh"` from file, not piped stdin - this allows interactive `read` prompts and gum UI in install scripts.

### Mandatory vs Optional Packages

**Mandatory** (always installed): Homebrew, Xcode CLT, gum, jq, AeroSpace, aerospace-swipe, SketchyBar, Nerd Fonts, Ghostty.

> aerospace-swipe talks to AeroSpace over the v0.21 socket protocol, so AeroSpace **>= 0.21** is required. `install/desktop/aerospace.sh` upgrades older installs in place (`install_cask` alone skips already-installed apps).

**Optional** (user selects per-app via gum UI, grouped into 5 categories):
- Terminal Tools: btop, ffmpeg, fzf, htop, ncdu, tree
- Code Editors: VSCode, Cursor, Sublime Text, Neovim + LazyVim
- AI Tools: Codex, Claude Code
- Development: Composer, DDEV, gh, lazydocker, lazygit, Node.js, Yarn, pnpm, fnm, Upsun CLI, Docker, Sequel Ace, pipx
- Desktop Extras: Stats

Selections are stored in `~/.config/makaron/packages.conf` (survives update/reinstall). Re-run with `makaron-select-packages`.

---

## Ghostty Configuration

Makaron installs Ghostty but does not manage `~/.config/ghostty`. Terminal appearance and Ghostty preferences are user-owned and stay outside the Makaron repository.

---

## Directory Structure

### Repository Layout
```text
makaron/
├── bin/                    # User commands (added to PATH)
├── configs/                # Config files (symlinked to ~/.config/)
│   ├── aerospace/
│   ├── sketchybar/
│   │   ├── colors.sh
│   │   ├── sketchybarrc
│   │   └── plugins/
├── install/                # Installation scripts
│   ├── all.sh              # Orchestrator: mandatory -> packages -> settings
│   ├── mandatory.sh        # Core components (always installed)
│   ├── packages.sh         # Optional packages: registry, gum UI, installer
│   ├── main.sh             # Main installer (called by install.sh)
│   ├── helpers.sh          # Helper functions
│   ├── brew.sh             # Homebrew + CLT setup
│   ├── desktop/            # AeroSpace, SketchyBar, fonts
│   ├── development/        # Dev tools
│   ├── editors/            # Text editor installers
│   └── terminal/           # Terminal tools
├── migrations/             # Timestamped migration scripts
├── src/                    # Swift source files (compiled to bin/)
└── install.sh              # Bootstrap (clone + call main.sh)
```

### User System Layout
```text
$HOME/
├── .local/share/makaron/            # Clone of repo
├── .local/state/makaron/migrations/ # Migration state
├── .local/state/makaron/ui-mode     # Current UI mode
├── .config/makaron/
│   ├── makaron.conf                 # User settings
│   └── packages.conf                # Optional package selections
├── .config/sketchybar -> ...        # Symlink
└── .aerospace.toml -> ...           # Symlink
```

### Key Paths
```bash
MAKARON_PATH="$HOME/.local/share/makaron"
MAKARON_MIGRATIONS_STATE_PATH="$HOME/.local/state/makaron/migrations"
MAKARON_CONF="$HOME/.config/makaron/makaron.conf"
MAKARON_PACKAGES_CONF="$HOME/.config/makaron/packages.conf"
```

### Development vs Installed Repo
- **Dev repo**: your local clone - where you edit code.
- **Installed repo**: `~/.local/share/makaron/` - separate clone, symlinked to `~/.config/`.

For quick testing you can modify files directly in `~/.local/share/makaron/`, but revert those changes before running `makaron-update`.

---

## User Configuration

### Overview
User-specific settings are stored outside the repo in `~/.config/makaron/makaron.conf`.

### How It Works
- Template: `templates/makaron.conf.default`
- User file: `~/.config/makaron/makaron.conf`
- On install: template is copied to user location
- On update: `install/makaron-conf.sh` regenerates the file from the template (structure and comments from template, user values win, unknown user variables preserved in a "User-defined settings" section)

### Adding New Config Variables
1. Add variable to `templates/makaron.conf.default`.
2. Use in scripts: `source "$HOME/.config/makaron/makaron.conf"`.
3. Always provide fallback: `VARIABLE="${VARIABLE:-default_value}"`.

### Current Variables
```bash
BATTERY_LOW_THRESHOLD=20                # Battery warning threshold (%)
SKETCHYBAR_COMPACT_MODE=false           # Hide CPU/memory/storage on the right side
SKETCHYBAR_HIDE_EMPTY_WORKSPACES=false  # Hide empty, non-focused workspaces in the bar
AEROSPACE_SWIPE_FINGERS=4               # Trackpad fingers to switch workspaces (aerospace-swipe)
AEROSPACE_SWIPE_NATURAL=true            # Swipe direction; true matches macOS (swipe left -> next)
AEROSPACE_GAP_SIZE=12                   # Persistent gap (0-40)
SKETCHYBAR_HEIGHT=40                    # Bar height (20-80); outer.top adapts
SKETCHYBAR_LOGO=true                    # Makaron menu (outline M mark) on the left
STORAGE_ALERT_THRESHOLD=90              # Show storage item only above this disk usage (%)
CPU_ALERT_THRESHOLD=80                  # CPU label turns alert color above this usage (%)
MEMORY_ALERT_THRESHOLD=80               # Memory label turns alert color above this usage (%)
AEROSPACE_AUTO_DWINDLE=true             # Dwindle auto-layout for new windows
FLOAT_ALL_LAYOUT=cascade                # float-all (alt-shift-f) arrangement: cascade | grid
MAKARON_CHANNEL=stable                  # Update channel: stable | edge
```

---

## User Overrides

Users customize without forking via files in `~/.config/makaron/` (seeded as `*.example` by `install/makaron-conf.sh`, activated by renaming):
- `aerospace.user.toml` - merged with `configs/aerospace/.aerospace.toml` by `bin/makaron-aerospace-generate` (bash+awk) into `~/.config/makaron/generated/aerospace.toml`; `~/.aerospace.toml` symlinks to the GENERATED file. Semantics: single-line `key = value` only; user keys win in named tables; user-only tables appended; user `[[on-window-detected]]` rules run after the auto-dwindle catch-all but before base routing/float rules (first-match-wins = user overrides routing); `[gaps]` is base-only (protects the sed/verify contract). Malformed user file -> base-only output + `fallback` status in `~/.local/state/makaron/aerospace-generate.status`, never nonzero exit. A merged config rejected by `aerospace reload-config --dry-run` is rolled back to `.lastgood`.
- `colors.user.sh` - sourced at the end of `configs/sketchybar/colors.sh` (reaches sketchybarrc and all plugins).
- `sketchybar.user.sh` - sourced in a subshell right before the final `sketchybar --update`.
- `icons.user.sh` - defines `makaron_user_app_icon()` consulted before the built-in icon map in `plugins/aerospace.sh`.
- Regeneration runs in: install (`install/desktop/aerospace.sh`), `makaron-update`, `makaron-reload-aerospace-sketchybar`, and `makaron-doctor --fix`. Always follow regeneration with `apply_desktop_state`.
- `SKETCHYBAR_HEIGHT` (makaron.conf) feeds both `sketchybarrc` and `_get_bar_height()` in `makaron-ui-helpers`, keeping bar height and `outer.top` in sync. `AEROSPACE_AUTO_DWINDLE=false` drops the dwindle catch-all from the generated config.

## Migration System

### Overview
Database-style migrations provide safe, incremental config updates.

### State Tracking
- **Completed**: Empty file in `~/.local/state/makaron/migrations/`
- **Skipped**: Empty file in `~/.local/state/makaron/migrations/skipped/`
- **Pending**: No file in either location

### When to Create Migrations
- Bug fixes for existing installations
- Moving/renaming config files
- Breaking changes needing gradual rollout
- Adding new software to install scripts (existing users won't get it via update)

### When NOT to Create
- New features not affecting existing installs
- Changes only in `install.sh`
- Documentation updates

### Commands
```bash
makaron-migrate           # Run pending migrations
```

### Migration Template
```bash
#!/bin/bash
# Migration: [Title]
# [Description]

set -e
error_exit() { echo -e "\033[31mERROR: Migration failed!\033[0m" >&2; exit 1; }
trap error_exit ERR

echo "Running migration: [Title]"
MAKARON_PATH="${MAKARON_PATH:-$HOME/.local/share/makaron}"

# Check if already applied (idempotent)
if [ condition ]; then
    echo "Already applied, skipping"
    exit 0
fi

# Migration logic here

echo "Migration completed successfully"
```

### Key Patterns
```bash
# Use helpers for installing software (preferred)
if [ -f "$MAKARON_PATH/install/helpers.sh" ]; then
    source "$MAKARON_PATH/install/helpers.sh"
    install_formula "package" "Display Name" "command"
fi

# Source install script with check
if [ -f "$MAKARON_PATH/install/path/script.sh" ]; then
    source "$MAKARON_PATH/install/path/script.sh"
fi

# Graceful service restart
killall ServiceName 2>/dev/null || true
```

### Testing Migrations
1. Syntax: `bash -n migrations/TIMESTAMP.sh`
2. Run manually, verify idempotency (run twice)
3. Test with missing dependencies

## AeroSpace + SketchyBar Integration

### Critical Config
In `configs/aerospace/.aerospace.toml`:

```toml
exec-on-workspace-change = ['/bin/bash', '-c',
    'sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE PREV_WORKSPACE=$AEROSPACE_PREV_WORKSPACE'
]

on-focus-changed = ['exec-and-forget sketchybar --trigger aerospace_focus_change']
```

**Required** - without `exec-on-workspace-change`, empty workspaces won't highlight correctly. `on-focus-changed` keeps the app-icon row up to date when focus moves between windows inside the same workspace.

### SketchyBar Events
Both events are registered in `sketchybarrc`, and every `space.$sid` item subscribes to them plus `front_app_switched`:

```bash
sketchybar --add event aerospace_workspace_change
sketchybar --add event aerospace_focus_change
# ...
--subscribe space.$sid aerospace_workspace_change aerospace_focus_change front_app_switched
```

### Plugin Logic (`aerospace.sh`)
The plugin uses a selective-refresh shortcut for `aerospace_workspace_change`: only the workspaces matching `$FOCUSED_WORKSPACE` and `$PREV_WORKSPACE` actually redraw. All other senders fall through to the full refresh path.

```bash
if [[ "$SENDER" == "aerospace_workspace_change" ]]; then
  if [[ "$WORKSPACE" != "$FOCUSED_WORKSPACE" && "$WORKSPACE" != "$PREV_WORKSPACE" ]]; then
    exit 0
  fi
fi

if [[ -n "$MONITOR" ]]; then
  IS_FOCUSED=$(aerospace list-workspaces --monitor "$MONITOR" --visible 2>/dev/null)
else
  if [[ -z "$FOCUSED_WORKSPACE" ]]; then
    FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused 2>/dev/null)
  fi
  IS_FOCUSED="$FOCUSED_WORKSPACE"
fi
```

### Hiding Empty Workspaces
`SKETCHYBAR_HIDE_EMPTY_WORKSPACES` in `makaron.conf` (default `false`) hides empty, non-focused workspaces via `drawing=off`. The focused workspace is always drawn, even when empty, so the bar never loses the user's current position.

### Monitor Detection
- Single monitor: Show all workspaces on one bar
- Multi-monitor: Each bar shows only its assigned workspaces
- Auto-reload on monitor connect/disconnect via `display_change.sh`

### Known Issue
`aerospace list-workspaces --focused` fails for empty workspaces - returns last non-empty workspace. Solution: Use event-driven `$FOCUSED_WORKSPACE` from callback.

---

## Troubleshooting

### Diagnostics Tool
Use `makaron-doctor` to check system status:
- Reports component/service health for AeroSpace and SketchyBar
- Verifies symlinks, configs, and UI mode state
- Supports `--fix` for safe repairs and `--json` for machine-readable output

### Migration Not Running
```bash
ls ~/.local/state/makaron/migrations/  # Check if marked completed
rm ~/.local/state/makaron/migrations/TIMESTAMP.sh  # Remove to re-run
makaron-migrate
```

### Empty Workspaces Not Highlighting
Check `exec-on-workspace-change` in aerospace.toml, then `aerospace reload-config`.

### Wrong Workspaces After Monitor Change
```bash
sketchybar --reload
```

### makaron-update Fails (Entry not uptodate / Local changes)
If update fails due to git state, re-run the install script (it re-fetches and resets to the channel target):

```bash
curl -sL https://raw.githubusercontent.com/grzegorzbartman/makaron/main/install.sh | bash
```

Then use `makaron-update` or `makaron-update -y` for future updates.
