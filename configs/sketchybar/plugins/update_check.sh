#!/bin/sh
# Update-available indicator: shown only when the installed Makaron is behind
# its channel target (latest release tag on stable, origin/main on edge).
# Click runs makaron-update in a new Ghostty window.

source "$CONFIG_DIR/colors.sh"

REPO="$HOME/.local/share/makaron"
[ -d "$REPO/.git" ] || { sketchybar --set "$NAME" drawing=off; exit 0; }

MAKARON_CHANNEL=stable
[ -f "$HOME/.config/makaron/makaron.conf" ] && . "$HOME/.config/makaron/makaron.conf"
case "$MAKARON_CHANNEL" in stable|edge) ;; *) MAKARON_CHANNEL=stable ;; esac

# Network fetch; on failure keep the current indicator state
git -C "$REPO" fetch --tags --force -q origin 2>/dev/null || exit 0

if [ "$MAKARON_CHANNEL" = "edge" ]; then
  TARGET=$(git -C "$REPO" rev-parse origin/main 2>/dev/null)
else
  TAG=$(git -C "$REPO" tag -l 'v*' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1)
  [ -z "$TAG" ] && { sketchybar --set "$NAME" drawing=off; exit 0; }
  TARGET=$(git -C "$REPO" rev-parse "refs/tags/$TAG^{commit}" 2>/dev/null)
fi

HEAD_REV=$(git -C "$REPO" rev-parse HEAD 2>/dev/null)

if [ -n "$TARGET" ] && [ "$HEAD_REV" != "$TARGET" ]; then
  sketchybar --set "$NAME" drawing=on \
    icon.color="${UPDATE_COLOR:-0xff1c1c1e}" \
    label.color="${UPDATE_COLOR:-0xff1c1c1e}" \
    background.color="${UPDATE_BACKGROUND_COLOR:-0xfff59e0b}"
else
  sketchybar --set "$NAME" drawing=off
fi
