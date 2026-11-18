log_err() (
    exe="${0##*/}"
    >&2 echo "$exe: error:" "$@"
)
