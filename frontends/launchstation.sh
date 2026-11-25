dir="$(dirname "$0")"
. "$dir/log.sh"
. "$dir/defaults.sh"

handle_launchstation() (
    trap 'exit 1' HUP INT QUIT TERM
    id="$1"
    vmc_id="$2"

    mkdir -p "$LAUNCHSTATION_DIR" || {
        log_err "Failed to create CFG directory for Launchstation"
        return 1
    }

    # VMCs will be handled unless:
    # - $VMC_0 is defined and non-empty
    # - There is a line starting with '#NO_VMC'
    cfg_file="$LAUNCHSTATION_DIR/NEUT-$id.cfg"
    {
        [ -f "$cfg_file" ] &&
        grep -Eq '^(#NO_VMC|\$VMC_0=[^[:space:]]+)' "$cfg_file"
    } && return 0

    tmp_cfg="$(mktemp)"
    trap 'rm -f "$tmp_cfg"' EXIT
    {
        [ -f "$cfg_file" ] && sed '/^$VMC_0\|^$End/d' "$cfg_file"
        echo "\$VMC_0=$vmc_id"
        echo "\$End=1"
    } > "$tmp_cfg"
    { mv "$tmp_cfg" "$cfg_file" && chmod 644 "$cfg_file"; } || {
        log_err "Failed to write Launchstation conf file for $id"
        return 1
    }
)
