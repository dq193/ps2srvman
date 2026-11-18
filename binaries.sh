# This file just checks if binaries necessary to run the main script fully
# are all present. If any binary does not exist, the script will exit here

dir="$(dirname "$0")"
. "$dir/log.sh"
. "$dir/defaults.sh"

: "${BSDTAR:=bsdtar}"
: "${CURL:=curl}"
: "${MKFS_PS2:=mkfs.ps2}"
: "${MAGICK:=magick}"
: "${INOTIFYWAIT:=inotifywait}"

handle_binaries() (
    command -v "$MKFS_PS2" >/dev/null 2>&1 || {
        log_err "mkfs.ps2 binary not found"
        return 1
    }
    command -v "$BSDTAR" >/dev/null 2>&1 || {
        log_err "bsdtar binary not found"
        return 1
    }
    command -v "$CURL" >/dev/null 2>&1 || {
        log_err "curl binary not found"
        return 1
    }
    [ "$ART_SOURCE" = "xlenore" ] && ! command -v "$MAGICK" >/dev/null 2>&1 && {
        log_err "magick binary not found (needed when source is xlenore)"
        return 1
    }
    
    # inotifywait is checked in watch.sh specifically, since it's not needed
    # when running the script manually.
    return 0
)
