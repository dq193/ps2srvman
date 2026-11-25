#!/bin/sh
set -u

dir="$(dirname "$0")"
. "$dir/defaults.sh"
. "$dir/log.sh"
. "$dir/binaries.sh"

process() {
    "$dir/ps2srvman.sh" "$1" || :
}

command -v "$INOTIFYWAIT" >/dev/null 2>&1 || {
    log_err "inotifywait binary not found"
    return 1
}

mkdir -p "$PS2_DIR/CD" "$PS2_DIR/DVD" || exit 1

"$INOTIFYWAIT"                       \
    -m -q                            \
    --includei '\.iso$'              \
    -e close_write -e moved_to       \
    --format '%w%f'                  \
    "$PS2_DIR/CD" "$PS2_DIR/DVD" | {
    
    # Handle any files added while script was not running
    for f in "$PS2_DIR"/CD/*.[iI][sS][oO] "$PS2_DIR"/DVD/*.[iI][sS][oO]; do
        [ -f "$f" ] && process "$f"
    done

    # Handle new additions
    while IFS= read -r f; do
        process "$f"
    done

    log_err "inotifywait terminated unexpectedly"
    exit 1
}
