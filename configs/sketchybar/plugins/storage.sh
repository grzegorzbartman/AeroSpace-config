#!/bin/sh
# Disk usage for SketchyBar - always visible, matches Finder (purgeable
# space counts as free via makaron-storage-stats, df fallback). Alert
# color above STORAGE_ALERT_THRESHOLD percent used.

MAKARON_PATH="${MAKARON_PATH:-$HOME/.local/share/makaron}"
source "$CONFIG_DIR/colors.sh"

STORAGE_ALERT_THRESHOLD=90
[ -f "$HOME/.config/makaron/makaron.conf" ] && . "$HOME/.config/makaron/makaron.conf"
case "$STORAGE_ALERT_THRESHOLD" in (*[!0-9]*|"") STORAGE_ALERT_THRESHOLD=90 ;; esac

USED_PCT=$("$MAKARON_PATH/bin/makaron-storage-stats" 2>/dev/null)
case "$USED_PCT" in (*[!0-9]*|"")
  USED_PCT=$(df -H /System/Volumes/Data 2>/dev/null | tail -1 | awk '{print $5}' | tr -d '%') ;;
esac
case "$USED_PCT" in (*[!0-9]*|"") USED_PCT="" ;; esac

if [ -n "$USED_PCT" ] && [ "$USED_PCT" -ge "$STORAGE_ALERT_THRESHOLD" ] 2>/dev/null; then
  COLOR="${ALERT_COLOR:-0xffff3b30}"
else
  COLOR="${LABEL_COLOR:-0xffc0caf5}"
fi

LABEL="${USED_PCT}%"
[ -z "$USED_PCT" ] && LABEL="N/A"

sketchybar --set "$NAME" label="$LABEL" \
           --animate sin 15 --set "$NAME" \
  icon.color="$COLOR" label.color="$COLOR" 2>/dev/null
