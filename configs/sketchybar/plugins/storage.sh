#!/bin/sh
# Disk usage for SketchyBar - always visible, matches Finder (purgeable
# space counts as free via makaron-storage-stats, df fallback). Alert
# color above STORAGE_ALERT_THRESHOLD percent used.

MAKARON_PATH="${MAKARON_PATH:-$HOME/.local/share/makaron}"
source "$CONFIG_DIR/colors.sh"

STORAGE_ALERT_THRESHOLD=90
[ -f "$HOME/.config/makaron/makaron.conf" ] && . "$HOME/.config/makaron/makaron.conf"
case "$STORAGE_ALERT_THRESHOLD" in (*[!0-9]*|"") STORAGE_ALERT_THRESHOLD=90 ;; esac

# Output format: "1.4/2 TB" (used/total, same unit)
DISPLAY=$("$MAKARON_PATH/bin/makaron-storage-stats" 2>/dev/null)
case "$DISPLAY" in
  (*/*) PCT=$(echo "$DISPLAY" | awk -F'[/ ]' 'NF>=2 && $2>0 {printf "%.0f", $1*100/$2}') ;;
  (*)   DISPLAY="" ;;
esac

if [ -z "$DISPLAY" ]; then
  # df fallback: raw sizes with their suffixes, percent from Capacity
  set -- $(df -H /System/Volumes/Data 2>/dev/null | tail -1)
  DISPLAY="${3:-N/A}/${2:-N/A}"
  PCT=$(echo "${5:-}" | tr -d '%')
fi
case "$PCT" in (*[!0-9]*|"") PCT="" ;; esac

if [ -n "$PCT" ] && [ "$PCT" -ge "$STORAGE_ALERT_THRESHOLD" ] 2>/dev/null; then
  COLOR="${ALERT_COLOR:-0xffff3b30}"
else
  COLOR="${LABEL_COLOR:-0xffc0caf5}"
fi

sketchybar --set "$NAME" label="$DISPLAY" \
           --animate sin 15 --set "$NAME" \
  icon.color="$COLOR" label.color="$COLOR" 2>/dev/null
