#!/bin/sh
# Storage alert for SketchyBar (APFS-aware): hidden below the threshold,
# shown as a warning pill when the disk is nearly full.

MAKARON_PATH="${MAKARON_PATH:-$HOME/.local/share/makaron}"
source "$CONFIG_DIR/colors.sh"

STORAGE_ALERT_THRESHOLD=90
[ -f "$HOME/.config/makaron/makaron.conf" ] && . "$HOME/.config/makaron/makaron.conf"
case "$STORAGE_ALERT_THRESHOLD" in (*[!0-9]*|"") STORAGE_ALERT_THRESHOLD=90 ;; esac

# Finder-style used% (purgeable space counts as free); df fallback
USED_PCT=$("$MAKARON_PATH/bin/makaron-storage-stats" 2>/dev/null)
case "$USED_PCT" in (*[!0-9]*|"")
  USED_PCT=$(df -H /System/Volumes/Data 2>/dev/null | tail -1 | awk '{print $5}' | tr -d '%') ;;
esac
case "$USED_PCT" in (*[!0-9]*|"") USED_PCT=0 ;; esac

STATE_FILE="/tmp/sketchybar_$(id -u)_storage_alert"

if [ "$USED_PCT" -gt "$STORAGE_ALERT_THRESHOLD" ]; then
  if [ ! -f "$STATE_FILE" ]; then
    # First appearance: ease the pill in from transparent
    touch "$STATE_FILE"
    sketchybar --set "$NAME" drawing=on label="${USED_PCT}% full" \
      background.color=0x00ff3b30 icon.color=0x00ff3b30 label.color=0x00ff3b30 \
               --animate sin 20 --set "$NAME" \
      background.color="${ALERT_BACKGROUND_COLOR:-0x26ff3b30}" \
      icon.color="${ALERT_COLOR:-0xffff3b30}" \
      label.color="${ALERT_COLOR:-0xffff3b30}" 2>/dev/null
  else
    sketchybar --set "$NAME" drawing=on label="${USED_PCT}% full" \
      background.color="${ALERT_BACKGROUND_COLOR:-0x26ff3b30}" \
      icon.color="${ALERT_COLOR:-0xffff3b30}" \
      label.color="${ALERT_COLOR:-0xffff3b30}" 2>/dev/null
  fi
else
  rm -f "$STATE_FILE"
  sketchybar --set "$NAME" drawing=off 2>/dev/null
fi
