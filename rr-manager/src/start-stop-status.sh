#!/bin/sh

case "$1" in
    start|stop|status)
        exit 0
        ;;
    log)
        echo "/var/packages/rr-manager/target/var/update.log"
        exit 0
        ;;
    *)
        exit 1
        ;;
esac
