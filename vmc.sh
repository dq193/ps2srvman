dir="$(dirname "$0")"
. "$dir/log.sh"
. "$dir/binaries.sh"
. "$dir/defaults.sh"

. "$dir/frontends/nhddl.sh"
. "$dir/frontends/launchstation.sh"

VMC_GROUP_LIST_URL='https://raw.githubusercontent.com/sync-on-luma/xebplus-neutrino-loader-plugin/refs/heads/main/List%20Builder/vmc_groups.list'
VMC_GROUP_LIST_FILE="$DATA_DIR/vmc_groups.list"
VMC_GROUP_LIST_BUF_FILE="$VMC_GROUP_LIST_FILE.buf"
VMC_GROUP_LIST_HDR_FILE="$VMC_GROUP_LIST_FILE.header"
VMC_GROUP_LIST_ETAG_FILE="$VMC_GROUP_LIST_FILE.etag"

LAUNCHSTATION_DIR="$PS2_DIR/CFG"

_fetch_vmc_group_list() (
    curr_etag="$(cat "$VMC_GROUP_LIST_ETAG_FILE" 2>/dev/null)"
    [ -f "$VMC_GROUP_LIST_FILE" ] || curr_etag=""

    # Handle curl opts
    set --                            \
        -sSL                          \
        -o "$VMC_GROUP_LIST_BUF_FILE" \
        -D "$VMC_GROUP_LIST_HDR_FILE" \
        -w '%{http_code}'
    [ -n "$curr_etag" ] && set -- "$@" -H "If-None-Match: $curr_etag"
    
    code="$("$CURL" "$@" "$VMC_GROUP_LIST_URL")"
    case $code in
        200)
            # List has been updated; update ETag and list file
            mv "$VMC_GROUP_LIST_BUF_FILE" "$VMC_GROUP_LIST_FILE" || {
                log_err "Failed to update VMC group list with new data"
                return 1
            }
            awk -F: 'tolower($0) ~ /^etag:/ {
                gsub(/[[:space:]]/, "", $NF)
                print $NF
            }' "$VMC_GROUP_LIST_HDR_FILE"     \
                | tail -n1                    \
                > "$VMC_GROUP_LIST_ETAG_FILE"
            ;;
        304)
            # Nothing changed
            ;;
        *)
            rm -f "$VMC_GROUP_LIST_HDR_FILE" "$VMC_GROUP_LIST_BUF_FILE"
            log_err "Failed to fetch VMC group list from $VMC_GROUP_LIST_URL"
            return 1
            ;;
    esac

    rm -f "$VMC_GROUP_LIST_HDR_FILE" "$VMC_GROUP_LIST_BUF_FILE"
    return 0
)

_get_vmc_id() (
    id="$1"

    _fetch_vmc_group_list || [ -f "$VMC_GROUP_LIST_FILE" ] || {
        log_err "Failed to get VMC file for $id"
        return 1
    }

    id_line="$(grep -Fn "$id" "$VMC_GROUP_LIST_FILE")" || {
        # Game not found in VMC group file; give it its own VMC file
        echo "$id"
        return 0
    }
    id_line="${id_line%%:*}"

    group_id="$(sed -n "1,${id_line}p" "$VMC_GROUP_LIST_FILE" | grep XEBP |
        tail -n1)"
    echo "$group_id"
    return 0
)

handle_vmc() (
    mkdir -p "$VMC_DIR" || {
        log_err "Failed to create VMC directory"
        return 1
    }

    id="$1"
    name="$2"

    vmc_id="$(_get_vmc_id "$id")" || return 1
    vmc_file="$VMC_DIR/$vmc_id.bin"
    [ -f "$vmc_file" ] || "$MKFS_PS2" -o "$vmc_file" -s 8 || {
        rm -f "$vmc_file"
        log_err "Failed to make VMC file $vmc_file"
        return 1
    }

    set -- "$id" "$vmc_id" "$name"
    case "$VMC_FRONTENDS" in
        *NHDDL*) handle_nhddl "$@" || : ;;
    esac
    case "$VMC_FRONTENDS" in
        *LAUNCHSTATION*) handle_launchstation "$@" || : ;;
    esac

    return 0
)
