dir="$(dirname "$0")"
. "$dir/log.sh"
. "$dir/defaults.sh"

NHDDL_DIR="$PS2_DIR/nhddl"

handle_nhddl() (
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
    
    echo "mc0: /VMC/$vmc_id.bin" >> "$cfg_file" || {
        log_err "Failed to write NHDDL conf for $id"
        return 1
    }
)
