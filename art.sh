dir="$(dirname "$0")"
. "$dir/log.sh"
. "$dir/binaries.sh"
. "$dir/defaults.sh"

DB_URL_BASE='https://raw.githubusercontent.com/Luden02/psx-ps2-opl-art-database/main/PS2'

handle_art() (
    id="$1"

    mkdir -p "$ART_DIR" || {
        log_err "Failed to create ART directory"
        return 1
    }

    dest_prefix="$ART_DIR/${id}_"
    url_prefix="$DB_URL_BASE/$id/${id}_"

    # Each line has the dest file on the left and URL on the right
    set --                                                 \
        "${dest_prefix}COV.png"  "${url_prefix}COV.png"    \
        "${dest_prefix}COV2.png" "${url_prefix}COV2.png"   \
        "${dest_prefix}ICO.png"  "${url_prefix}ICO.png"    \
        "${dest_prefix}LAB.png"  "${url_prefix}LAB.png"    \
        "${dest_prefix}LGO.png"  "${url_prefix}LGO.png"    \
        "${dest_prefix}BG.png"   "${url_prefix}BG_00.png"  \
        "${dest_prefix}SCR0.png" "${url_prefix}SCR_00.png" \
        "${dest_prefix}SCR1.png" "${url_prefix}SCR_01.png"
    
    failed=0
    while [ $# -gt 0 ]; do
        dest="$1" url="$2"
        shift 2
        [ -f "$dest" ] && continue

        tmp="$dest.tmp"
        code="$("$CURL"                         \
            -sSL                                \
            --connect-timeout 15 --max-time 120 \
            -w '%{http_code}'                   \
            -o "$tmp"                           \
            "$url")" || code=000
        case "$code" in
            404)
                ;;
            200)
                mv "$tmp" "$dest" || {
                    log_err "Failed to save $dest"
                    failed=1
                }
                ;;
            *)
                log_err "Failed to fetch $url for $id (got HTTP $code)"
                failed=1
                ;;
        esac

        rm -f "$tmp"
    done

    return "$failed"
)
