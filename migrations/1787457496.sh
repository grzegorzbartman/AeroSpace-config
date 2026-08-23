#!/bin/bash
# Migration: Recompile notch binary, compile storage stats binary
# Stale makaron-has-notch builds print "1" without the top-inset value; the
# probe rejected that and cached "0 0", so notched MacBooks got the full
# no-notch top reserve. Recompile it and clear the cache. Also compile the
# new makaron-storage-stats (Finder-style used%, purgeable counts as free).

set -e
error_exit() { echo -e "\033[31mERROR: Migration failed!\033[0m" >&2; exit 1; }
trap error_exit ERR

echo "Running migration: Recompile notch binary, compile storage stats binary"
MAKARON_PATH="${MAKARON_PATH:-$HOME/.local/share/makaron}"

compile() {
    local src="$1" bin="$2"
    if command -v swiftc >/dev/null 2>&1 && [ -f "$MAKARON_PATH/src/$src" ]; then
        swiftc -O -o "$MAKARON_PATH/bin/$bin" "$MAKARON_PATH/src/$src" 2>/dev/null \
            && echo "  ✓ Compiled $bin" \
            || echo "  ⚠️  $bin compile failed, fallback stays in use"
    else
        echo "  ⚠️  swiftc not available, $bin fallback stays in use"
    fi
}

if [ -x "$MAKARON_PATH/bin/makaron-has-notch" ] \
    && "$MAKARON_PATH/bin/makaron-has-notch" 2>/dev/null | grep -qE '^[01] [0-9]+$'; then
    echo "  ✓ makaron-has-notch already current"
else
    compile has_notch.swift makaron-has-notch
fi

if [ -x "$MAKARON_PATH/bin/makaron-storage-stats" ]; then
    echo "  ✓ makaron-storage-stats already compiled"
else
    compile storage_stats.swift makaron-storage-stats
fi

rm -f "/tmp/makaron_$(id -u)_notch_v2" 2>/dev/null || true

echo "Migration completed successfully"
