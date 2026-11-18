#!/bin/sh
set -u

# RUN AS ROOT

: "${INSTALL_DIR:=/usr/local/lib/ps2srvman}"
mkdir -p "$INSTALL_DIR"

cd "$(dirname "$0")" || exit 1

install                                          \
    -v                                           \
    -m 644                                       \
    -t "$INSTALL_DIR"                            \
    art.sh binaries.sh defaults.sh log.sh vmc.sh \
    || exit 1

install                   \
    -v                    \
    -m 755                \
    -t "$INSTALL_DIR"     \
    ps2srvman.sh watch.sh \
    || exit 1

[ -f '/etc/systemd/system/ps2srvman.service' ] ||
    install                      \
        -v                       \
        -m 644                   \
        -t '/etc/systemd/system' \
        ps2srvman.service        \
        || exit 1

systemctl daemon-reload || exit 1
systemctl enable ps2srvman.service || exit 1
systemctl restart ps2srvman.service || exit 1