#!/bin/sh
set -u

dir="$(dirname "$0")"
. "$dir/defaults.sh"
. "$dir/log.sh"
. "$dir/art.sh"
. "$dir/vmc.sh"

get_game_id() (
    iso="$1"

    id="$("$BSDTAR" -xOf "$iso" "SYSTEM.CNF" |
        sed -n 's/^BOOT2.*\([A-Z]\{4\}_[0-9]\{3\}\.[0-9]\{2\}\).*/\1/p')" || {
        log_err "Failed to parse game ID from $iso"
        return 1
    }
    [ -n "$id" ] || {
        log_err "No BOOT2 entry found in SYSTEM.CNF of $iso"
        return 1
    }
    
    echo "$id"
    return 0
)

mkdir -p "$DATA_DIR" || exit 1

handle_binaries || exit 1

iso="$1"
id="$(get_game_id "$iso")" || exit 1
name="$(basename "${iso%.*}")"

[ "$HANDLE_VMC" -eq 1 ] && handle_vmc "$id" "$name"
[ "$HANDLE_ART" -eq 1 ] && handle_art "$id"