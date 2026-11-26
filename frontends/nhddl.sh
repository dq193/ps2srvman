dir="$(dirname "$0")"
. "$dir/log.sh"
. "$dir/defaults.sh"

NHDDL_DIR="$PS2_DIR/nhddl"

handle_nhddl() (
    trap 'exit 1' HUP INT QUIT TERM
    id="$1"
    vmc_id="$2"
    name="$3"

    mkdir -p "$NHDDL_DIR" || {
        log_err "Failed to create NHDDL directory"
        return 1
    }

    # Unless file exists and mc0 has been set or disabled, we'll add the VMC
    cfg_file="$NHDDL_DIR/$name.yaml"
    { [ -f "$cfg_file" ] && grep -Eq '^\$?mc0:' "$cfg_file"; } && return 0
    
    tmp_cfg="$cfg_file.nhddl.tmp"
    trap 'rm -f "$tmp_cfg"' EXIT
    
    {
        [ ! -f "$cfg_file" ] || cat "$cfg_file" &&
        echo "mc0: /VMC/$vmc_id.bin"
    } > "$tmp_cfg" || {
        log_err "Failed to write NHDDL conf for $id"
        return 1
    }
    mv "$tmp_cfg" "$cfg_file" || {
        log_err "Failed to save $cfg_file"
        return 1
    }

    return 0
)
