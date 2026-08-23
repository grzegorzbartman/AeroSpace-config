#!/bin/bash
# Left click on the M mark opens the shortcut overlay; right click opens the
# Makaron menu popup (Update / Doctor / Reload).

if [ "$BUTTON" = "right" ]; then
    sketchybar --set makaron_logo popup.drawing=toggle
else
    sketchybar --set makaron_logo popup.drawing=off
    "$HOME/.local/share/makaron/bin/makaron-help"
fi
