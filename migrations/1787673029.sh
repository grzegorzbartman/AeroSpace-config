#!/bin/bash
# Migration: Recompile storage stats binary for used/total output
# makaron-storage-stats now prints "used/total unit" (e.g. "1.4/2 TB")
# instead of a bare percent; older builds break the always-visible disk
# label, so recompile when the output has no slash.

set -e
error_exit() { echo -e "\033[31mERROR: Migration failed!\033[0m" >&2; exit 1; }
trap error_exit ERR

echo "Running migration: Recompile storage stats binary for used/total output"
MAKARON_PATH="${MAKARON_PATH:-$HOME/.local/share/makaron}"

if [ -x "$MAKARON_PATH/bin/makaron-storage-stats" ] \
    && "$MAKARON_PATH/bin/makaron-storage-stats" 2>/dev/null | grep -q "/"; then
    echo "  ✓ makaron-storage-stats already current"
elif command -v swiftc >/dev/null 2>&1 && [ -f "$MAKARON_PATH/src/storage_stats.swift" ]; then
    swiftc -O -o "$MAKARON_PATH/bin/makaron-storage-stats" "$MAKARON_PATH/src/storage_stats.swift" 2>/dev/null \
        && echo "  ✓ Compiled makaron-storage-stats" \
        || echo "  ⚠️  Compile failed, df fallback stays in use"
else
    echo "  ⚠️  swiftc not available, df fallback stays in use"
fi

echo "Migration completed successfully"
