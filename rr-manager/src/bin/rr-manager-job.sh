#!/bin/sh

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
PKG_ROOT="$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)"
. "${SCRIPT_DIR}/rr-manager-lib.sh"

mode="$1"
source_value="$2"
asset_name="$3"
downloaded_archive=""
current_version=""

download_error_message='Missing download URL for the RR update.'
local_missing_message='Local update archive does not exist.'
apply_error_message='RR update failed. Check the log section for details.'
success_message='RR update completed. Reboot DSM when you are ready.'
prepare_message='Preparing RR update.'

append_job_log() {
    log_message="$1"
    rrm_ensure_dirs
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "${log_message}" >>"${RRM_JOB_LOG}"
}

try_fallback_download() {
    primary_url="$1"
    primary_name="$2"
    output_path="$3"

    case "${primary_name}" in
        updateall-*.zip)
            fallback_name="update-${primary_name#updateall-}"
            fallback_url="${primary_url%/${primary_name}}/${fallback_name}"
            ;;
        update-*.zip)
            fallback_name="updateall-${primary_name#update-}"
            fallback_url="${primary_url%/${primary_name}}/${fallback_name}"
            ;;
        *)
            return 1
            ;;
    esac

    log "Primary download failed, retrying ${fallback_url}."
    rrm_download_to "${fallback_url}" "${output_path}" >>"${UPDATE_LOG}" 2>&1
}

cleanup() {
    status_code="$1"
    append_job_log "rr-manager-job.sh exiting with status ${status_code}."
    [ -n "${downloaded_archive}" ] && rrm_do rm -f "${downloaded_archive}"
    rrm_cleanup_mounts
    rrm_release_lock
    rrm_do rm -f "${UPDATE_PID_FILE}"
    exit "${status_code}"
}

log() {
    log_message="$1"
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "${log_message}"
    append_job_log "${log_message}"
}

rrm_ensure_dirs
exec 2>>"${RRM_JOB_LOG}"
append_job_log "----- starting rr-manager-job.sh pid=$$ mode=${mode:-unknown} -----"

if ! rrm_acquire_lock; then
    rrm_write_update_state "failed" "Another RR Manager task is already running." "" "${mode}"
    append_job_log "Unable to acquire RR Manager task lock."
    cleanup 1
fi

case "${mode}" in
    rrm-online|rrm-local)
        download_error_message='Missing download URL for the RR Manager package.'
        local_missing_message='Local RR Manager package does not exist.'
        apply_error_message='RR Manager self-update failed. Check the log section for details.'
        success_message='RR Manager self-update completed.'
        prepare_message='Preparing RR Manager self-update.'
        current_version="$(rrm_current_package_version 2>/dev/null || true)"
        ;;
    *)
        current_version="$(rrm_current_version 2>/dev/null || true)"
        ;;
esac

rrm_write_update_state "running" "${prepare_message}" "${current_version}" "${mode}"
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
            if ! try_fallback_download "${source_value}" "${asset_name}" "${downloaded_archive}"; then
                rrm_write_update_state "failed" "Failed to download ${asset_name}." "${current_version}" "${mode}"
                cleanup 1
            fi
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
    rrm-online)
        [ -n "${source_value}" ] || {
            rrm_write_update_state "failed" "${download_error_message}" "${current_version}" "${mode}"
            cleanup 1
        }
        [ -n "${asset_name}" ] || asset_name="rr-manager.spk"
        downloaded_archive="${WORK_DIR}/downloads/${asset_name}"
        rrm_write_update_state "running" "Downloading ${asset_name} from GitHub." "${current_version}" "${mode}"
        log "Downloading ${source_value}."
        if ! rrm_download_to "${source_value}" "${downloaded_archive}" >>"${UPDATE_LOG}" 2>&1; then
            rrm_write_update_state "failed" "Failed to download ${asset_name}." "${current_version}" "${mode}"
            cleanup 1
        fi
        archive_path="${downloaded_archive}"
        ;;
    rrm-local)
        archive_path="${source_value}"
        [ -f "${archive_path}" ] || {
            rrm_write_update_state "failed" "${local_missing_message}" "${current_version}" "${mode}"
            cleanup 1
        }
        asset_name="$(basename "${archive_path}")"
        rrm_write_update_state "running" "Installing ${asset_name}." "${current_version}" "${mode}"
        ;;
    *)
        rrm_write_update_state "failed" "Unsupported update mode." "${current_version}" "${mode}"
        cleanup 1
        ;;
esac

case "${mode}" in
    rrm-online|rrm-local)
        log "Installing ${archive_path}."
        if ! rrm_synopkg_install "${archive_path}" >>"${UPDATE_LOG}" 2>&1; then
            rrm_write_update_state "failed" "${apply_error_message}" "${current_version}" "${mode}"
            cleanup 1
        fi
        ;;
    *)
        log "Applying ${archive_path}."
        if ! rrm_apply_update_archive "${archive_path}"; then
            rrm_write_update_state "failed" "${apply_error_message}" "${current_version}" "${mode}"
            cleanup 1
        fi
        ;;
esac

case "${mode}" in
    rrm-online|rrm-local)
        new_version="$(rrm_current_package_version 2>/dev/null || true)"
        ;;
    *)
        new_version="$(rrm_current_version 2>/dev/null || true)"
        ;;
esac

rrm_write_update_state "success" "${success_message}" "${new_version}" "${mode}"
log "Update completed successfully."
cleanup 0
