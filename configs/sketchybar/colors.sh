#!/bin/bash

# Liquid glass palette following the system appearance.
# plugins/appearance_change.sh reloads the bar when the appearance flips.
if defaults read -g AppleInterfaceStyle >/dev/null 2>&1; then
    # Dark: dark translucent glass, white overlays, dark-mode system blue
    export BAR_COLOR=0x661c1c1e
    export BAR_BACKGROUND_COLOR=0x00000000
    export BAR_BLUR=60
    export BAR_BORDER_COLOR=0x26ffffff

    export ICON_COLOR=0xfffafbfc
    export LABEL_COLOR=0xfffafbfc

    export SPACE_ICON_COLOR=0xffd1d1d6
    export SPACE_LABEL_COLOR=0xffd1d1d6
    export SPACE_BACKGROUND_COLOR=0x33ffffff
    export SPACE_BORDER_COLOR=0x00000000

    export SPACE_FOCUSED_ICON_COLOR=0xffffffff
    export SPACE_FOCUSED_LABEL_COLOR=0xffffffff
    export SPACE_FOCUSED_BACKGROUND_COLOR=0xff2b7dfd
    export SPACE_FOCUSED_BORDER_COLOR=0xff2b7dfd

    export ALERT_COLOR=0xfff87171
    export ALERT_BACKGROUND_COLOR=0x33f87171

    # White-outline M reads on the dark glass
    export MAKARON_LOGO_IMAGE=makaron-m@2x.png
else
    # Light: translucent glass, dark text, system blue
    export BAR_COLOR=0x66f5f5f7
    export BAR_BACKGROUND_COLOR=0x00000000
    export BAR_BLUR=60
    export BAR_BORDER_COLOR=0x40ffffff

    export ICON_COLOR=0xff0f172a
    export LABEL_COLOR=0xff0f172a

    export SPACE_ICON_COLOR=0xff3a3a3c
    export SPACE_LABEL_COLOR=0xff3a3a3c
    export SPACE_BACKGROUND_COLOR=0x73ffffff
    export SPACE_BORDER_COLOR=0x00000000

    export SPACE_FOCUSED_ICON_COLOR=0xffffffff
    export SPACE_FOCUSED_LABEL_COLOR=0xffffffff
    export SPACE_FOCUSED_BACKGROUND_COLOR=0xff0d6efd
    export SPACE_FOCUSED_BORDER_COLOR=0xff0d6efd

    export ALERT_COLOR=0xffef4444
    export ALERT_BACKGROUND_COLOR=0x26ef4444

    # Ink-outline M matches the dark glyphs on the light glass
    export MAKARON_LOGO_IMAGE=makaron-m-ink@2x.png
fi

# User color overrides (sourced by sketchybarrc and every plugin)
# shellcheck disable=SC1090
[ -f "$HOME/.config/makaron/colors.user.sh" ] && source "$HOME/.config/makaron/colors.user.sh"
