#!/bin/bash

source "$MAKARON_PATH/install/helpers.sh"

# Install SketchyBar (CRITICAL component)
# Tap-qualified name is required: Homebrew >= 6.0 ignores the short name until
# the tap or formula is trusted.
brew tap FelixKratz/formulae 2>/dev/null || true
install_formula_critical "felixkratz/formulae/sketchybar" "SketchyBar" "sketchybar"

# Compile memory stats binary (uses Mach API for accurate Activity Monitor values)
if [ -f "$MAKARON_PATH/src/memory_stats.swift" ]; then
    echo "Compiling memory_stats..."
    swiftc -O -o "$MAKARON_PATH/bin/makaron-memory-stats" "$MAKARON_PATH/src/memory_stats.swift" 2>/dev/null || {
        echo "Warning: Failed to compile memory_stats.swift, memory display may be inaccurate"
    }
fi

# Compile storage stats binary (Finder-style used%, counts purgeable as free)
if [ -f "$MAKARON_PATH/src/storage_stats.swift" ]; then
    echo "Compiling storage_stats..."
    swiftc -O -o "$MAKARON_PATH/bin/makaron-storage-stats" "$MAKARON_PATH/src/storage_stats.swift" 2>/dev/null || {
        echo "Warning: Failed to compile storage_stats.swift, falling back to df"
    }
fi

# Compile notch detection binary (avoids slow `swift -e` cold start)
if [ -f "$MAKARON_PATH/src/has_notch.swift" ]; then
    echo "Compiling has_notch..."
    swiftc -O -o "$MAKARON_PATH/bin/makaron-has-notch" "$MAKARON_PATH/src/has_notch.swift" 2>/dev/null || {
        echo "Warning: Failed to compile has_notch.swift, falling back to swift -e"
    }
fi

# Compile shortcut overlay panel (NSPanel + WKWebView, used by makaron-help)
if [ -f "$MAKARON_PATH/src/help_window.swift" ]; then
    echo "Compiling help_window..."
    swiftc -O -o "$MAKARON_PATH/bin/makaron-help-window" "$MAKARON_PATH/src/help_window.swift" 2>/dev/null || {
        echo "Warning: Failed to compile help_window.swift, makaron-help will open in the browser"
    }
fi

# Setup SketchyBar config
mkdir -p "$HOME/.config"

if [ ! -L "$HOME/.config/sketchybar" ] && [ ! -d "$HOME/.config/sketchybar" ]; then
    ln -s "$MAKARON_PATH/configs/sketchybar" "$HOME/.config/sketchybar"
else
    # Check if symlink points to wrong location
    if [ -L "$HOME/.config/sketchybar" ]; then
        current_target=$(readlink "$HOME/.config/sketchybar")
        if [[ "$current_target" != "$MAKARON_PATH/configs/sketchybar" ]]; then
            echo "Fixing SketchyBar symlink to point to new location..."
            rm "$HOME/.config/sketchybar"
            ln -s "$MAKARON_PATH/configs/sketchybar" "$HOME/.config/sketchybar"
        fi
    else
        # Directory exists but is not a symlink - back it up and replace
        echo "Backing up existing SketchyBar config..."
        mv "$HOME/.config/sketchybar" "$HOME/.config/sketchybar.backup.$(date +%s)"
        ln -s "$MAKARON_PATH/configs/sketchybar" "$HOME/.config/sketchybar"
    fi
fi
