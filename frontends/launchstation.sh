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

    # Unless file exists and $VMC_0 is present and non-empty or not commented
    # out, we'll add the VMC
    cfg_file="$LAUNCHSTATION_DIR/NEUT-$id.cfg"
    {
        [ -f "$cfg_file" ] &&
        grep -Eq '^(#.*\$VMC_0|\$VMC_0=[^[:space:]]+)' "$cfg_file"
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
