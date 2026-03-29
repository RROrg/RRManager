#!/bin/sh

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
PKG_ROOT="$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)"
. "${SCRIPT_DIR}/rr-manager-lib.sh"

mode="$1"
source_value="$2"
asset_name="$3"
downloaded_archive=""

cleanup() {
    status_code="$1"
    [ -n "${downloaded_archive}" ] && rm -f "${downloaded_archive}"
    rrm_cleanup_mounts
    rrm_release_lock
    rm -f "${UPDATE_PID_FILE}"
    exit "${status_code}"
}

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1"
}

rrm_ensure_dirs

if ! rrm_acquire_lock; then
    rrm_write_update_state "failed" "Another RR Manager task is already running." "" "${mode}"
    cleanup 1
fi

current_version="$(rrm_current_version 2>/dev/null || true)"
rrm_write_update_state "running" "Preparing RR update." "${current_version}" "${mode}"
log "Starting update job in mode ${mode}."

case "${mode}" in
    online)
        [ -n "${source_value}" ] || {
            rrm_write_update_state "failed" "Missing download URL for the RR update." "${current_version}" "${mode}"
            cleanup 1
        }
        [ -n "${asset_name}" ] || asset_name="updateall.zip"
        downloaded_archive="${WORK_DIR}/downloads/${asset_name}"
        rrm_write_update_state "running" "Downloading ${asset_name} from GitHub." "${current_version}" "${mode}"
        log "Downloading ${source_value}."
        if ! rrm_download_to "${source_value}" "${downloaded_archive}" >>"${UPDATE_LOG}" 2>&1; then
            rrm_write_update_state "failed" "Failed to download ${asset_name}." "${current_version}" "${mode}"
            cleanup 1
        fi
        archive_path="${downloaded_archive}"
        ;;
    local)
        archive_path="${source_value}"
        [ -f "${archive_path}" ] || {
            rrm_write_update_state "failed" "Local update archive does not exist." "${current_version}" "${mode}"
            cleanup 1
        }
        asset_name="$(basename "${archive_path}")"
        rrm_write_update_state "running" "Applying ${asset_name}." "${current_version}" "${mode}"
        ;;
    *)
        rrm_write_update_state "failed" "Unsupported update mode." "${current_version}" "${mode}"
        cleanup 1
        ;;
esac

log "Applying ${archive_path}."
if ! rrm_apply_update_archive "${archive_path}"; then
    rrm_write_update_state "failed" "RR update failed. Check the log section for details." "${current_version}" "${mode}"
    cleanup 1
fi

new_version="$(rrm_current_version 2>/dev/null || true)"
rrm_write_update_state "success" "RR update completed. Reboot DSM when you are ready." "${new_version}" "${mode}"
log "Update completed successfully."
cleanup 0
