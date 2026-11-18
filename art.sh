dir="$(dirname "$0")"
. "$dir/log.sh"
. "$dir/binaries.sh"
. "$dir/defaults.sh"

XLENORE_URL_BASE="https://raw.githubusercontent.com/xlenore/ps2-covers/main/covers/default"
OPLM_URL_BASE="https://archive.org/download/OPLM_ART_2024_09/OPLM_ART_2024_09.zip"

handle_art() (
    trap 'exit 1' HUP INT QUIT TERM
    mkdir -p "$ART_DIR" || {
        log_err "Failed to create ART directory"
        return 1
    }

    id="$1"
    cov_file="$ART_DIR/${id}_COV.png"
    [ -f "$cov_file" ] && return 0
    cov_tmp="$(mktemp)"
    trap 'rm -rf "$cov_tmp"' EXIT

    # set args for curl
    set --                \
        -sSL              \
        -w '%{http_code}' \
        -o "$cov_tmp"
    case $ART_SOURCE in
        xlenore)
            xlenore_id="$(echo "$id" | awk -F'[_.]' '{ print $1 "-" $2 $3 }')"
            url="$XLENORE_URL_BASE/$xlenore_id.jpg"
            ;;
        oplm)
            url="$OPLM_URL_BASE/PS2%2F${id}%2F${id}_COV.png"
            ;;
        *)
            log_err "Unsupported art source '$ART_SOURCE'"
            return 1
            ;;
    esac

    code="$("$CURL" "$@" "$url")"
    case $code in
        404|503) # Why does IA throw 503 when the file doesn't exist?
            ;;
        200)
            case $ART_SOURCE in
                xlenore)
                    # Convert to the same image format as OPLM
                    "$MAGICK" -quiet "$cov_tmp" \
                        -strip                  \
                        -resize '140x200!'      \
                        -colors 256             \
                        "PNG8:$cov_file" || {
                        log_err "Failed to convert xlenore JPG cover to PNG file"
                        return 1
                    }
                    ;;
                oplm)
                    { mv "$cov_tmp" "$cov_file" && chmod 644 "$cov_file"; } || {
                        log_err "Failed to move downloaded cover to destination"
                        return 1
                    }
                    ;;
            esac
            ;;
        *)
            log_err "Failed to fetch cover art for $id"
            return 1
            ;;
    esac
    
    return 0
)
