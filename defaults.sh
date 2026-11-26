: "${DATA_DIR:=/var/lib/ps2srvman}"
: "${PS2_DIR:=/srv/ps2}"

: "${HANDLE_ART:=1}"
: "${HANDLE_VMC:=1}"

: "${VMC_FRONTENDS:=NHDDL,LAUNCHSTATION}"

# These are based on $PS2_DIR and cannot be set beforehand
ART_DIR="$PS2_DIR/ART"
VMC_DIR="$PS2_DIR/VMC"
