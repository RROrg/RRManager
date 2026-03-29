#!/bin/sh

PACKAGE_ROOT="${SYNOPKG_PKGDEST}"
UI_DIR="${PACKAGE_ROOT}/app"

register_indexes() {
    pkgindexer_add "${UI_DIR}/index.conf"
    pkgindexer_add "${UI_DIR}/helptoc.conf"
}

unregister_indexes() {
    pkgindexer_del "${UI_DIR}/helptoc.conf"
    pkgindexer_del "${UI_DIR}/index.conf"
}

fix_permissions() {
    chmod 0755 "${UI_DIR}/scripts/api.cgi"
    chmod 0755 "${PACKAGE_ROOT}/bin/rr-manager-lib.sh" "${PACKAGE_ROOT}/bin/rr-manager-job.sh"
    chmod 0755 "${PACKAGE_ROOT}/var"
}

cleanup_legacy_ui() {
    rm -f "${UI_DIR}/index.cgi" "${UI_DIR}/api.cgi"
    rm -rf "${PACKAGE_ROOT}/ui"
}

service_postinst() {
    mkdir -p "${PACKAGE_ROOT}/var"
    cleanup_legacy_ui
    fix_permissions
    register_indexes
}

service_postupgrade() {
    mkdir -p "${PACKAGE_ROOT}/var"
    cleanup_legacy_ui
    fix_permissions
    register_indexes
}

service_postuninst() {
    unregister_indexes
}
