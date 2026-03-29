#!/bin/sh

PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH}"
exec 2>>/tmp/rr-manager-api-error.log

PKG_NAME="${PKG_NAME:-rr-manager}"
PKG_ROOT="${PKG_ROOT:-/var/packages/${PKG_NAME}/target}"
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
if [ ! -f "${PKG_ROOT}/bin/rr-manager-lib.sh" ]; then
    PKG_ROOT="$(CDPATH= cd -- "${SCRIPT_DIR}/../.." && pwd)"
fi
if [ ! -f "${PKG_ROOT}/bin/rr-manager-lib.sh" ]; then
    echo 'Status: 500 Internal Server Error'
    echo 'Content-Type: application/json; charset=UTF-8'
    echo 'Cache-Control: no-store'
    echo
    printf '%s\n' '{"ok":false,"error":"RR Manager backend library was not found."}'
    exit 1
fi
. "${PKG_ROOT}/bin/rr-manager-lib.sh"

mkdir -p "${STATE_DIR}" 2>/dev/null || true
exec 2>>"${STATE_DIR}/api-error.log"

read_body() {
    if [ "${REQUEST_METHOD}" = "POST" ] && [ -n "${CONTENT_LENGTH}" ] && [ "${CONTENT_LENGTH}" -gt 0 ] 2>/dev/null; then
        dd bs=1 count="${CONTENT_LENGTH}" 2>/dev/null
    fi
}

url_decode() {
    decoded="$(printf '%s' "$1" | sed 's/+/ /g;s/%/\\x/g')"
    printf '%b' "${decoded}"
}

get_param_from_blob() {
    wanted="$1"
    blob="$2"
    old_ifs="${IFS}"
    IFS='&'
    for pair in ${blob}; do
        key="${pair%%=*}"
        [ "${key}" = "${wanted}" ] || continue
        value="${pair#*=}"
        url_decode "${value}"
        IFS="${old_ifs}"
        return 0
    done
    IFS="${old_ifs}"
    return 1
}

get_param() {
    value="$(get_param_from_blob "$1" "${QUERY_STRING:-}" 2>/dev/null || true)"
    if [ -n "${value}" ]; then
        printf '%s' "${value}"
        return 0
    fi
    get_param_from_blob "$1" "${BODY:-}" 2>/dev/null || true
}

locale_value="$(get_param lang 2>/dev/null || true)"
[ -n "${locale_value}" ] || locale_value="${HTTP_ACCEPT_LANGUAGE%%,*}"
RRM_UI_LOCALE="${locale_value}"
export RRM_UI_LOCALE

json_quote() {
    printf '"%s"' "$(rrm_json_escape "$1")"
}

send_json() {
    status_code="$1"
    payload="$2"
    case "${status_code}" in
        200) status_text='200 OK' ;;
        400) status_text='400 Bad Request' ;;
        404) status_text='404 Not Found' ;;
        409) status_text='409 Conflict' ;;
        500) status_text='500 Internal Server Error' ;;
        502) status_text='502 Bad Gateway' ;;
        *) status_text="${status_code} OK" ;;
    esac
    echo "Status: ${status_text}"
    echo 'Content-Type: application/json; charset=UTF-8'
    echo 'Cache-Control: no-store'
    echo
    printf '%s\n' "${payload}"
}

send_error() {
    status_code="$1"
    shift
    message="$*"
    send_json "${status_code}" "{\"ok\":false,\"error\":$(json_quote "${message}")}"
}

send_ok() {
    send_json 200 "$1"
}

send_json_stream_start() {
    status_code="$1"
    case "${status_code}" in
        200) status_text='200 OK' ;;
        400) status_text='400 Bad Request' ;;
        404) status_text='404 Not Found' ;;
        409) status_text='409 Conflict' ;;
        500) status_text='500 Internal Server Error' ;;
        502) status_text='502 Bad Gateway' ;;
        *) status_text="${status_code} OK" ;;
    esac
    echo "Status: ${status_text}"
    echo 'Content-Type: application/json; charset=UTF-8'
    echo 'Cache-Control: no-store'
    echo
}

with_locked_mount() {
    lock_acquired=0
    attempt=0
    while [ "${attempt}" -lt 5 ]; do
        if rrm_acquire_lock; then
            lock_acquired=1
            break
        fi
        attempt=$((attempt + 1))
        sleep 1
    done
    if [ "${lock_acquired}" -ne 1 ]; then
        return 10
    fi
    if ! rrm_mount_synoboot; then
        rrm_cleanup_mounts
        rrm_release_lock
        return 11
    fi
    return 0
}

release_locked_mount() {
    rrm_cleanup_mounts
    rrm_release_lock
}

csv_to_lines() {
    printf '%s' "$1" | tr ',' '\n' | sed 's/\r//g' | sed '/^[[:space:]]*$/d'
}

collect_overview() {
    state_value="$(rrm_read_update_state_field state 2>/dev/null || printf 'idle')"
    message_value="$(rrm_read_update_state_field message 2>/dev/null || printf 'Ready.')"
    version_value="$(rrm_current_version 2>/dev/null || true)"
    busy_value='false'
    mount_status='ready'
    mount_message='Ready.'

    dmi_vendor="$(rrm_dmi_value /sys/class/dmi/id/sys_vendor 2>/dev/null || printf 'unknown')"
    dmi_product="$(rrm_dmi_value /sys/class/dmi/id/product_name 2>/dev/null || printf 'unknown')"
    dmi_version="$(rrm_dmi_value /sys/class/dmi/id/product_version 2>/dev/null || printf 'unknown')"
    bios_version="$(rrm_dmi_value /sys/class/dmi/id/bios_version 2>/dev/null || printf 'unknown')"
    cpu_model="$(rrm_cpu_model 2>/dev/null || printf 'unknown')"
    cpu_cores="$(rrm_cpu_cores 2>/dev/null || printf 'unknown')"
    ram_total="$(rrm_ram_total 2>/dev/null || printf 'unknown')"
    kernel_release="$(rrm_kernel_release 2>/dev/null || printf 'unknown')"
    machine_arch="$(rrm_machine_arch 2>/dev/null || printf 'unknown')"
    access_method="$(rrm_boot_access_method 2>/dev/null || printf 'unknown')"
    boot_type='unknown'
    boot_model='unknown'
    boot_version='unknown'
    boot_kernel='unknown'
    boot_lkm='unknown'
    boot_mev='unknown'

    rrm_cleanup_stale_lock >/dev/null 2>&1 || true

    if rrm_is_busy; then
        busy_value='true'
        mount_status='busy'
        mount_message='RR Manager is busy with another task.'
    else
        if with_locked_mount; then
            config_path="$(rrm_managed_file_path user-config 2>/dev/null || true)"
            mounted_version="$(rrm_current_version 2>/dev/null || true)"
            [ -n "${mounted_version}" ] && version_value="${mounted_version}"
            if [ -n "${config_path}" ] && [ -f "${config_path}" ]; then
                boot_type_raw="$(rrm_yaml_scalar_value dt "${config_path}" 2>/dev/null || true)"
                boot_model="$(rrm_yaml_scalar_value model "${config_path}" 2>/dev/null || printf 'unknown')"
                boot_version="$(rrm_yaml_scalar_value productver "${config_path}" 2>/dev/null || printf 'unknown')"
                boot_kernel="$(rrm_yaml_scalar_value kernel "${config_path}" 2>/dev/null || printf 'unknown')"
                boot_lkm="$(rrm_yaml_scalar_value lkm "${config_path}" 2>/dev/null || printf 'unknown')"
                boot_mev="$(rrm_yaml_scalar_value mev "${config_path}" 2>/dev/null || printf 'unknown')"

                case "$(printf '%s' "${boot_type_raw}" | tr '[:upper:]' '[:lower:]')" in
                    true|yes|1) boot_type='DT' ;;
                    false|no|0|'') boot_type='Non-DT' ;;
                    *) boot_type="${boot_type_raw}" ;;
                esac
            fi
            release_locked_mount
        else
            mount_status='unavailable'
            mount_message='Unable to mount loader disk to inspect the current RR version.'
        fi
    fi

    running_value='false'
    rrm_is_update_running && running_value='true'

    send_ok "$(cat <<EOF
{"ok":true,"busy":${busy_value},"currentVersion":$(json_quote "${version_value}"),"updateState":$(json_quote "${state_value}"),"updateMessage":$(json_quote "${message_value}"),"updateRunning":${running_value},"hardware":{"dmiVendor":$(json_quote "${dmi_vendor}"),"dmiProduct":$(json_quote "${dmi_product}"),"dmiVersion":$(json_quote "${dmi_version}"),"biosVersion":$(json_quote "${bios_version}"),"cpuModel":$(json_quote "${cpu_model}"),"cpuCores":$(json_quote "${cpu_cores}"),"ramTotal":$(json_quote "${ram_total}"),"kernel":$(json_quote "${kernel_release}"),"arch":$(json_quote "${machine_arch}")},"boot":{"lockState":$(json_quote "$( [ "${busy_value}" = 'true' ] && printf 'busy' || printf 'idle' )"),"mountStatus":$(json_quote "${mount_status}"),"mountMessage":$(json_quote "${mount_message}"),"accessMethod":$(json_quote "${access_method}"),"bootType":$(json_quote "${boot_type}"),"model":$(json_quote "${boot_model}"),"version":$(json_quote "${boot_version}"),"kernel":$(json_quote "${boot_kernel}"),"lkm":$(json_quote "${boot_lkm}"),"mev":$(json_quote "${boot_mev}")}}
EOF
)"
}

read_file_action() {
    file_id="$(get_param file)"
    [ -n "${file_id}" ] || file_id='user-config'

    label="$(rrm_managed_file_label "${file_id}" 2>/dev/null || true)"
    [ -n "${label}" ] || {
        send_error 400 "Unsupported file identifier."
        return
    }

    with_locked_mount
    case "$?" in
        10)
            send_error 409 "RR Manager is busy with another task."
            return
            ;;
        11)
            send_error 500 "Unable to mount /dev/synoboot1."
            return
            ;;
    esac

    content="$(rrm_read_managed_file "${file_id}" 2>/dev/null || true)"
    path_value="$(rrm_managed_file_path "${file_id}" 2>/dev/null || true)"
    release_locked_mount

    if [ -z "${content}" ] && [ ! -f "${path_value}" ]; then
        send_error 404 "The selected file was not found on the bootloader partition."
        return
    fi

    send_ok "{\"ok\":true,\"file\":$(json_quote "${file_id}"),\"label\":$(json_quote "${label}"),\"path\":$(json_quote "${path_value}"),\"content\":$(json_quote "${content}")}"
}

write_file_action() {
    file_id="$(get_param file)"
    content_value="$(get_param content)"
    [ -n "${file_id}" ] || file_id='user-config'

    label="$(rrm_managed_file_label "${file_id}" 2>/dev/null || true)"
    [ -n "${label}" ] || {
        send_error 400 "Unsupported file identifier."
        return
    }

    with_locked_mount
    case "$?" in
        10)
            send_error 409 "RR Manager is busy with another task."
            return
            ;;
        11)
            send_error 500 "Unable to mount /dev/synoboot1."
            return
            ;;
    esac

    temp_file="$(mktemp "${STATE_DIR}/edit.XXXXXX")" || {
        release_locked_mount
        send_error 500 "Unable to allocate a temporary file."
        return
    }
    printf '%s' "${content_value}" >"${temp_file}"

    if ! rrm_write_managed_file "${file_id}" "${temp_file}" >/dev/null 2>&1; then
        rm -f "${temp_file}"
        release_locked_mount
        send_error 500 "Failed to save the file to the bootloader partition."
        return
    fi

    rm -f "${temp_file}"
    release_locked_mount
    send_ok "{\"ok\":true,\"message\":$(json_quote "${label} saved successfully.")}"
}

release_action() {
    release_json="$(rrm_fetch_latest_release_json 2>/dev/null || true)"
    [ -n "${release_json}" ] || {
        send_error 502 "Unable to query the latest RR release from GitHub."
        return
    }

    tag_value="$(rrm_release_tag_from_json "${release_json}")"
    published_value="$(rrm_release_published_from_json "${release_json}")"
    asset_line="$(rrm_release_asset_line_from_json "${release_json}")"
    asset_name="$(rrm_release_asset_name_from_line "${asset_line}")"
    asset_url="$(rrm_release_asset_url_from_line "${asset_line}")"

    [ -n "${tag_value}" ] || {
        send_error 502 "GitHub returned an unexpected release payload."
        return
    }

    current_version="$(rrm_current_version 2>/dev/null || true)"
    send_ok "{\"ok\":true,\"currentVersion\":$(json_quote "${current_version}"),\"latestVersion\":$(json_quote "${tag_value}"),\"publishedAt\":$(json_quote "${published_value}"),\"assetName\":$(json_quote "${asset_name}"),\"assetUrl\":$(json_quote "${asset_url}"),\"htmlUrl\":$(json_quote "https://github.com/RROrg/rr/releases/tag/${tag_value}")}"
}

start_online_update_action() {
    if rrm_is_update_running; then
        send_error 409 "An RR update is already running."
        return
    fi

    release_json="$(rrm_fetch_latest_release_json 2>/dev/null || true)"
    [ -n "${release_json}" ] || {
        send_error 502 "Unable to query the latest RR release from GitHub."
        return
    }

    tag_value="$(rrm_release_tag_from_json "${release_json}")"
    asset_line="$(rrm_release_asset_line_from_json "${release_json}")"
    asset_name="$(rrm_release_asset_name_from_line "${asset_line}")"
    asset_url="$(rrm_release_asset_url_from_line "${asset_line}")"

    [ -n "${asset_url}" ] || {
        send_error 502 "No update archive was found in the latest RR release."
        return
    }

    : >"${UPDATE_LOG}"
    "${PKG_ROOT}/bin/rr-manager-job.sh" online "${asset_url}" "${asset_name}" >>"${UPDATE_LOG}" 2>&1 &
    echo "$!" >"${UPDATE_PID_FILE}"
    rrm_write_update_state "queued" "Queued online update for ${tag_value}." "${tag_value}" "online"

    send_ok "{\"ok\":true,\"message\":$(json_quote "Online update started."),\"latestVersion\":$(json_quote "${tag_value}"),\"assetName\":$(json_quote "${asset_name}")}"
}

start_local_update_action() {
    if rrm_is_update_running; then
        send_error 409 "An RR update is already running."
        return
    fi

    archive_path="$(get_param path)"
    case "${archive_path}" in
        /*.zip) ;;
        *)
            send_error 400 "Please provide an absolute path to a local update zip file."
            return
            ;;
    esac

    [ -f "${archive_path}" ] || {
        send_error 404 "The specified local archive was not found."
        return
    }

    : >"${UPDATE_LOG}"
    "${PKG_ROOT}/bin/rr-manager-job.sh" local "${archive_path}" >>"${UPDATE_LOG}" 2>&1 &
    echo "$!" >"${UPDATE_PID_FILE}"
    rrm_write_update_state "queued" "Queued local update from $(basename "${archive_path}")." "" "local"

    send_ok "{\"ok\":true,\"message\":$(json_quote "Local update started."),\"path\":$(json_quote "${archive_path}")}"
}

log_action() {
    log_tail="$(rrm_read_update_log_tail)"
    send_ok "{\"ok\":true,\"log\":$(json_quote "${log_tail}")}"
}

addons_action() {
    with_locked_mount
    case "$?" in
        10)
            send_error 409 "RR Manager is busy with another task."
            return
            ;;
        11)
            send_error 500 "Unable to mount /dev/synoboot1."
            return
            ;;
    esac

    config_path="$(rrm_managed_file_path user-config)"
    send_json_stream_start 200
    printf '{"ok":true,"items":'
    rrm_addons_json "${config_path}" 2>/dev/null || printf '[]'
    printf '}\n'
    release_locked_mount
}

save_addons_action() {
    items_value="$(get_param items)"

    with_locked_mount
    case "$?" in
        10)
            send_error 409 "RR Manager is busy with another task."
            return
            ;;
        11)
            send_error 500 "Unable to mount /dev/synoboot1."
            return
            ;;
    esac

    config_path="$(rrm_managed_file_path user-config)"
    entries_file="$(mktemp "${STATE_DIR}/addons.XXXXXX")" || {
        release_locked_mount
        send_error 500 "Unable to allocate a temporary addons file."
        return
    }

    csv_to_lines "${items_value}" | sort -u >"${entries_file}"
    if ! rrm_replace_yaml_map_section "addons" "${entries_file}" "${config_path}"; then
        rm -f "${entries_file}"
        release_locked_mount
        send_error 500 "Failed to save addons into user-config.yml."
        return
    fi

    rm -f "${entries_file}"
    release_locked_mount
    send_ok "{\"ok\":true,\"message\":$(json_quote "Addons selection saved successfully.")}"
}

modules_action() {
    with_locked_mount
    case "$?" in
        10)
            send_error 409 "RR Manager is busy with another task."
            return
            ;;
        11)
            send_error 500 "Unable to mount /dev/synoboot1."
            return
            ;;
    esac

    config_path="$(rrm_managed_file_path user-config)"
    send_json_stream_start 200
    printf '{"ok":true,"items":'
    rrm_modules_json "${config_path}" 2>/dev/null || printf '[]'
    printf '}\n'
    release_locked_mount
}

save_modules_action() {
    items_value="$(get_param items)"

    with_locked_mount
    case "$?" in
        10)
            send_error 409 "RR Manager is busy with another task."
            return
            ;;
        11)
            send_error 500 "Unable to mount /dev/synoboot1."
            return
            ;;
    esac

    config_path="$(rrm_managed_file_path user-config)"
    entries_file="$(mktemp "${STATE_DIR}/modules.XXXXXX")" || {
        release_locked_mount
        send_error 500 "Unable to allocate a temporary modules file."
        return
    }

    csv_to_lines "${items_value}" | sort -u >"${entries_file}"
    if ! rrm_replace_yaml_map_section "modules" "${entries_file}" "${config_path}"; then
        rm -f "${entries_file}"
        release_locked_mount
        send_error 500 "Failed to save modules into user-config.yml."
        return
    fi

    rm -f "${entries_file}"
    release_locked_mount
    send_ok "{\"ok\":true,\"message\":$(json_quote "Modules selection saved successfully.")}"
}

BODY="$(read_body)"
action="$(get_param action)"

case "${action}" in
    overview) collect_overview ;;
    read) read_file_action ;;
    write) write_file_action ;;
    addons) addons_action ;;
    save-addons) save_addons_action ;;
    modules) modules_action ;;
    save-modules) save_modules_action ;;
    release) release_action ;;
    start-update-online) start_online_update_action ;;
    start-update-local) start_local_update_action ;;
    log) log_action ;;
    *)
        send_error 400 "Unsupported action."
        ;;
esac
