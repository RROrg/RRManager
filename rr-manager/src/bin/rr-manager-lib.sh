#!/bin/sh

PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH}"

PKG_NAME="${PKG_NAME:-rr-manager}"
PKG_ROOT="${PKG_ROOT:-/var/packages/${PKG_NAME}/target}"
STATE_DIR="${STATE_DIR:-${PKG_ROOT}/var}"
WORK_DIR="${WORK_DIR:-${STATE_DIR}/work}"
MOUNT_BASE="${MOUNT_BASE:-/mnt}"
LOCK_DIR="${LOCK_DIR:-${STATE_DIR}/bootloader.lock}"
LOCK_PID_FILE="${LOCK_PID_FILE:-${LOCK_DIR}/pid}"
MOUNTS_FILE="${MOUNTS_FILE:-${WORK_DIR}/mounts.list}"
UPDATE_STATE="${UPDATE_STATE:-${STATE_DIR}/update.state}"
UPDATE_LOG="${UPDATE_LOG:-${STATE_DIR}/update.log}"
UPDATE_PID_FILE="${UPDATE_PID_FILE:-${STATE_DIR}/update.pid}"
RELEASE_REPO_URL="${RELEASE_REPO_URL:-https://github.com/RROrg/rr}"
RELEASE_LATEST_URL="${RELEASE_LATEST_URL:-${RELEASE_REPO_URL}/releases/latest}"
RELEASE_TAGS_URL="${RELEASE_TAGS_URL:-${RELEASE_REPO_URL}/tags}"
RELEASE_DOWNLOAD_BASE_URL="${RELEASE_DOWNLOAD_BASE_URL:-${RELEASE_REPO_URL}/releases/download}"
PRERELEASE="${PRERELEASE:-false}"
RRMDO_BIN="${RRMDO_BIN:-/sbin/rrmdo}"

rrm_ensure_dirs() {
    mkdir -p "${STATE_DIR}" "${WORK_DIR}" "${MOUNT_BASE}"
}

rrm_do() {
    if [ "$(id -u)" = "0" ]; then
        "$@"
    elif [ -x "${RRMDO_BIN}" ]; then
        "${RRMDO_BIN}" "$@"
    else
        "$@"
    fi
}

rrm_now() {
    date -u '+%Y-%m-%dT%H:%M:%SZ'
}

rrm_json_escape() {
    printf '%s' "$1" | awk '
        BEGIN {
            first = 1
        }
        {
            line = $0
            gsub(/\\/,"\\\\", line)
            gsub(/"/,"\\\"", line)
            gsub(/\r/,"\\r", line)
            gsub(/\t/,"\\t", line)
            if (!first) {
                printf "\\n"
            }
            printf "%s", line
            first = 0
        }
    '
}

rrm_flatten_text() {
    printf '%s' "$1" | LC_ALL=C tr '\r\n' '  ' | LC_ALL=C tr -d '\000-\010\013\014\016-\037' | sed 's/[[:space:]]\+/ /g;s/^ //;s/ $//'
}

rrm_json_string() {
    printf '"%s"' "$(rrm_json_escape "$(rrm_flatten_text "$1")")"
}

rrm_is_mounted() {
    awk -v mount_point="$1" '$2 == mount_point { found = 1 } END { exit found ? 0 : 1 }' /proc/mounts
}

rrm_mount_source_is() {
    awk -v mount_point="$1" -v device="$2" '
        $1 == device && $2 == mount_point { found = 1 }
        END { exit found ? 0 : 1 }
    ' /proc/mounts
}

rrm_default_mount_point() {
    printf '%s/p%s\n' "${MOUNT_BASE}" "$1"
}

rrm_device_mount_point() {
    awk -v device="$1" '$1 == device { print $2; exit }' /proc/mounts
}

rrm_partition_mount_point() {
    partition="$1"
    device="/dev/synoboot${partition}"
    default_mount="$(rrm_default_mount_point "${partition}")"

    if rrm_mount_source_is "${default_mount}" "${device}"; then
        printf '%s\n' "${default_mount}"
        return 0
    fi

    mounted_path="$(rrm_device_mount_point "${device}" 2>/dev/null || true)"
    if [ -n "${mounted_path}" ]; then
        printf '%s\n' "${mounted_path}"
        return 0
    fi

    printf '%s\n' "${default_mount}"
}

rrm_partition_path() {
    partition="$1"
    path_suffix="$2"
    mount_point="$(rrm_partition_mount_point "${partition}")" || return 1

    if [ -n "${path_suffix}" ]; then
        printf '%s/%s\n' "${mount_point}" "${path_suffix}"
    else
        printf '%s\n' "${mount_point}"
    fi
}

rrm_relative_boot_path() {
    target_path="$1"

    case "${target_path}" in
        /mnt/p1) printf '%s\n' 'p1'; return 0 ;;
        /mnt/p2) printf '%s\n' 'p2'; return 0 ;;
        /mnt/p3) printf '%s\n' 'p3'; return 0 ;;
        /mnt/p1/*) printf 'p1/%s\n' "${target_path#/mnt/p1/}"; return 0 ;;
        /mnt/p2/*) printf 'p2/%s\n' "${target_path#/mnt/p2/}"; return 0 ;;
        /mnt/p3/*) printf 'p3/%s\n' "${target_path#/mnt/p3/}"; return 0 ;;
    esac

    for partition in 1 2 3; do
        mount_point="$(rrm_partition_mount_point "${partition}" 2>/dev/null || true)"
        [ -n "${mount_point}" ] || continue
        case "${target_path}" in
            "${mount_point}") printf 'p%s\n' "${partition}"; return 0 ;;
            "${mount_point}"/*) printf 'p%s/%s\n' "${partition}" "${target_path#${mount_point}/}"; return 0 ;;
        esac
    done

    return 1
}

rrm_mount_record_add() {
    touch "${MOUNTS_FILE}"
    grep -Fx "$1" "${MOUNTS_FILE}" >/dev/null 2>&1 || printf '%s\n' "$1" >>"${MOUNTS_FILE}"
}

rrm_cleanup_mounts() {
    if [ "${RRM_SKIP_MOUNT:-0}" = "1" ]; then
        return 0
    fi

    if [ -f "${MOUNTS_FILE}" ]; then
        for mount_point in "${MOUNT_BASE}/p3" "${MOUNT_BASE}/p2" "${MOUNT_BASE}/p1"; do
            grep -Fx "${mount_point}" "${MOUNTS_FILE}" >/dev/null 2>&1 || continue
            rrm_do umount "${mount_point}" >/dev/null 2>&1 || true
        done
        rm -f "${MOUNTS_FILE}"
    fi
}

rrm_acquire_lock() {
    rrm_ensure_dirs
    if mkdir "${LOCK_DIR}" >/dev/null 2>&1; then
        printf '%s\n' "$$" >"${LOCK_PID_FILE}" 2>/dev/null || {
            rm -f "${LOCK_PID_FILE}"
            rmdir "${LOCK_DIR}" >/dev/null 2>&1 || true
            return 1
        }
        return 0
    fi

    rrm_cleanup_stale_lock >/dev/null 2>&1 || true
    if mkdir "${LOCK_DIR}" >/dev/null 2>&1; then
        printf '%s\n' "$$" >"${LOCK_PID_FILE}" 2>/dev/null || {
            rm -f "${LOCK_PID_FILE}"
            rmdir "${LOCK_DIR}" >/dev/null 2>&1 || true
            return 1
        }
        return 0
    fi

    return 1
}

rrm_release_lock() {
    rm -f "${LOCK_PID_FILE}" >/dev/null 2>&1 || true
    rmdir "${LOCK_DIR}" >/dev/null 2>&1 || true
}

rrm_is_busy() {
    if [ ! -d "${LOCK_DIR}" ]; then
        return 1
    fi
    if rrm_lock_owner_alive; then
        return 0
    fi
    rrm_cleanup_stale_lock >/dev/null 2>&1 || true
    [ -d "${LOCK_DIR}" ]
}

rrm_lock_owner_pid() {
    [ -f "${LOCK_PID_FILE}" ] || return 1
    sed -n '1p' "${LOCK_PID_FILE}" 2>/dev/null
}

rrm_lock_owner_alive() {
    owner_pid="$(rrm_lock_owner_pid 2>/dev/null || true)"
    [ -n "${owner_pid}" ] || return 1
    kill -0 "${owner_pid}" >/dev/null 2>&1
}

rrm_cleanup_stale_lock() {
    [ -d "${LOCK_DIR}" ] || return 0
    if rrm_lock_owner_alive; then
        return 1
    fi
    rm -f "${LOCK_PID_FILE}" >/dev/null 2>&1 || true
    rmdir "${LOCK_DIR}" >/dev/null 2>&1 || true
    [ ! -d "${LOCK_DIR}" ]
}

rrm_set_install_flag() {
    if [ -w /proc/sys/kernel/syno_install_flag ]; then
        echo 1 >/proc/sys/kernel/syno_install_flag 2>/dev/null || true
    elif [ -e /proc/sys/kernel/syno_install_flag ]; then
        printf '1\n' | rrm_do tee /proc/sys/kernel/syno_install_flag >/dev/null 2>&1 || true
    fi
}

rrm_load_loader_modules() {
    rrm_do modprobe -q vfat >/dev/null 2>&1 || true
    rrm_do modprobe -q ext2 >/dev/null 2>&1 || true
    rrm_do modprobe -q ext4 >/dev/null 2>&1 || true
}

rrm_mount_partition() {
    partition="$1"
    filesystem="$2"
    device="/dev/synoboot${partition}"
    mount_point="$(rrm_default_mount_point "${partition}")"

    [ -b "${device}" ] || return 1
    rrm_do mkdir -p "${mount_point}" || return 1

    if rrm_mount_source_is "${mount_point}" "${device}"; then
        return 0
    fi

    existing_mount="$(rrm_device_mount_point "${device}" 2>/dev/null || true)"
    if [ -n "${existing_mount}" ]; then
        return 0
    fi

    if rrm_is_mounted "${mount_point}"; then
        rrm_do umount "${mount_point}" >/dev/null 2>&1 || return 1
    fi

    rrm_do mount -t "${filesystem}" "${device}" "${mount_point}" >/dev/null 2>&1 || return 1
    rrm_mount_record_add "${mount_point}"
    return 0
}

rrm_mount_synoboot() {
    rrm_ensure_dirs

    if [ "${RRM_SKIP_MOUNT:-0}" = "1" ] && [ -n "$(rrm_device_mount_point /dev/synoboot1 2>/dev/null || true)" ]; then
        return 0
    fi

    rrm_set_install_flag
    rrm_load_loader_modules

    [ -b /dev/synoboot ] || return 1
    [ -b /dev/synoboot1 ] || return 1
    [ -b /dev/synoboot2 ] || return 1
    [ -b /dev/synoboot3 ] || return 1

    rrm_mount_partition 1 vfat || {
        rrm_cleanup_mounts
        return 1
    }
    rrm_mount_partition 2 ext2 || {
        rrm_cleanup_mounts
        return 1
    }
    rrm_mount_partition 3 ext4 || {
        rrm_cleanup_mounts
        return 1
    }

    [ -n "$(rrm_device_mount_point /dev/synoboot1 2>/dev/null || true)" ] || return 1
    [ -n "$(rrm_device_mount_point /dev/synoboot2 2>/dev/null || true)" ] || return 1
    [ -n "$(rrm_device_mount_point /dev/synoboot3 2>/dev/null || true)" ]
}

rrm_current_version() {
    version_file="$(rrm_partition_path 1 RR_VERSION)"
    [ -f "${version_file}" ] || return 1

    version_value="$(sed -n '/[^[:space:]]/ { s/\r$//; p; q; }' "${version_file}" 2>/dev/null)"
    [ -n "${version_value}" ] || return 1
    printf '%s\n' "${version_value}"
}

rrm_read_first_line() {
    [ -f "$1" ] || return 1
    sed -n '/[^[:space:]]/ { s/\r$//; p; q; }' "$1" 2>/dev/null
}

rrm_dmi_value() {
    value="$(rrm_read_first_line "$1" 2>/dev/null || true)"
    [ -n "${value}" ] || return 1
    printf '%s\n' "${value}"
}

rrm_cpu_model() {
    cpu_model="$(
        sed -n 's/^model name[[:space:]]*:[[:space:]]*//p' /proc/cpuinfo 2>/dev/null | head -n 1
    )"
    if [ -z "${cpu_model}" ]; then
        cpu_model="$(
            sed -n 's/^Hardware[[:space:]]*:[[:space:]]*//p' /proc/cpuinfo 2>/dev/null | head -n 1
        )"
    fi
    [ -n "${cpu_model}" ] || cpu_model='unknown'
    printf '%s\n' "${cpu_model}"
}

rrm_cpu_cores() {
    core_count="$({ sed -n 's/^cpu cores[[:space:]]*:[[:space:]]*//p' /proc/cpuinfo 2>/dev/null | head -n 1; } || true)"
    if [ -z "${core_count}" ]; then
        core_count="$(grep -c '^processor' /proc/cpuinfo 2>/dev/null || true)"
    fi
    [ -n "${core_count}" ] && [ "${core_count}" -gt 0 ] 2>/dev/null || core_count='unknown'
    printf '%s\n' "${core_count}"
}

rrm_cpu_threads() {
    thread_count="$(grep -c '^processor' /proc/cpuinfo 2>/dev/null || true)"
    [ -n "${thread_count}" ] && [ "${thread_count}" -gt 0 ] 2>/dev/null || thread_count='unknown'
    printf '%s\n' "${thread_count}"
}

rrm_ram_total() {
    mem_kb="$(awk '/^MemTotal:/ { print $2; exit }' /proc/meminfo 2>/dev/null)"
    [ -n "${mem_kb}" ] || {
        printf '%s\n' 'unknown'
        return 0
    }

    mem_gib="$(awk -v kb="${mem_kb}" 'BEGIN { printf "%.1f GiB", kb / 1024 / 1024 }')"
    printf '%s\n' "${mem_gib}"
}

rrm_kernel_release() {
    uname -sr 2>/dev/null || printf '%s\n' 'unknown'
}

rrm_machine_arch() {
    uname -m 2>/dev/null || printf '%s\n' 'unknown'
}

rrm_firmware_mode() {
    if [ -d /sys/firmware/efi ]; then
        printf '%s\n' 'UEFI'
    else
        printf '%s\n' 'Legacy'
    fi
}

rrm_boot_access_method() {
    if [ "$(id -u)" = "0" ]; then
        printf '%s\n' 'internal /dev/synoboot* (root)'
    elif [ -x "${RRMDO_BIN}" ]; then
        printf '%s\n' "internal /dev/synoboot* via $(basename "${RRMDO_BIN}")"
    else
        printf '%s\n' 'internal /dev/synoboot*'
    fi
}

rrm_cmdline_value() {
    key_name="$1"
    value=''
    [ -n "${key_name}" ] || return 1

    value="$(tr ' ' '\n' </proc/cmdline 2>/dev/null | grep -m 1 "^${key_name}=" | sed "s/^${key_name}=//" | sed -n '/[^[:space:]]/ { s/\r$//; p; q; }')"

    [ -n "${value}" ] || return 1
    printf '%s\n' "${value}"
}

rrm_lspci_details() {
    command -v lspci >/dev/null 2>&1 || return 1

    lspci -nnk 2>/dev/null | sed 's/\r$//' | sed -n '/[^[:space:]]/p'
}

rrm_lspci_device_rows() {
    command -v lspci >/dev/null 2>&1 || return 1

    lspci -nnk 2>/dev/null | {
        current_path=''
        current_type=''
        current_device=''
        current_vidpid=''
        current_driver=''

        while IFS= read -r raw_line || [ -n "${raw_line}" ]; do
            line="$(printf '%s' "${raw_line}" | sed 's/\r$//')"

            case "${line}" in
                [0-9A-Fa-f][0-9A-Fa-f]:*)
                    if [ -n "${current_path}" ]; then
                        printf '%s\t%s\t%s\t%s\t%s\n' \
                            "${current_path}" \
                            "${current_type:-unknown}" \
                            "${current_device:-unknown}" \
                            "${current_vidpid:-unknown}" \
                            "${current_driver:--}"
                    fi

                    current_path="$(printf '%s\n' "${line}" | sed -n 's/^\([^[:space:]]*\)[[:space:]].*/\1/p')"
                    rest="${line#${current_path} }"
                    type_part="${rest%%: *}"
                    device_part="${rest#*: }"
                    current_type="$(printf '%s\n' "${type_part}" | sed 's/ (prog-if .*)$//')"
                    current_vidpid="$(printf '%s\n' "${device_part}" | sed -n 's/^.* \[\([0-9A-Fa-f]\{4\}:[0-9A-Fa-f]\{4\}\)\]\( (rev [^)]*)\)\{0,1\}$/\1/p')"
                    current_device="$(printf '%s\n' "${device_part}" | sed -n 's/^\(.*\) \[[0-9A-Fa-f]\{4\}:[0-9A-Fa-f]\{4\}\]\( (rev [^)]*)\)\{0,1\}$/\1/p')"
                    [ -n "${current_device}" ] || current_device="$(printf '%s\n' "${device_part}" | sed 's/ (rev [^)]*)$//')"
                    current_driver='-'
                    ;;
                *Kernel\ driver\ in\ use:*)
                    [ -n "${current_path}" ] || continue
                    current_driver="$(printf '%s\n' "${line#*: }" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
                    ;;
            esac
        done

        if [ -n "${current_path}" ]; then
            printf '%s\t%s\t%s\t%s\t%s\n' \
                "${current_path}" \
                "${current_type:-unknown}" \
                "${current_device:-unknown}" \
                "${current_vidpid:-unknown}" \
                "${current_driver:--}"
        fi
    }
}

rrm_read_sysfs_first_line() {
    target_file="$1"
    [ -n "${target_file}" ] || return 1
    cat "${target_file}" 2>/dev/null | sed -n '1{s/\r$//;p;q;}'
}

rrm_collect_usb_rows_internal() {
    usb_listing="$(rrm_do lsusb 2>/dev/null || true)"
    if [ -n "${usb_listing}" ]; then
        printf '%s\n' "${usb_listing}" | while IFS= read -r raw_line || [ -n "${raw_line}" ]; do
            line="$(printf '%s' "${raw_line}" | sed 's/\r$//')"
            [ -n "${line}" ] || continue

            bus_value="$(printf '%s\n' "${line}" | sed -n 's/^Bus \([0-9][0-9][0-9]\) Device \([0-9][0-9][0-9]\): ID \([0-9A-Fa-f]\{4\}:[0-9A-Fa-f]\{4\}\) \(.*\)$/\1/p')"
            device_value="$(printf '%s\n' "${line}" | sed -n 's/^Bus \([0-9][0-9][0-9]\) Device \([0-9][0-9][0-9]\): ID \([0-9A-Fa-f]\{4\}:[0-9A-Fa-f]\{4\}\) \(.*\)$/\2/p')"
            vidpid_value="$(printf '%s\n' "${line}" | sed -n 's/^Bus \([0-9][0-9][0-9]\) Device \([0-9][0-9][0-9]\): ID \([0-9A-Fa-f]\{4\}:[0-9A-Fa-f]\{4\}\) \(.*\)$/\3/p')"
            name_value="$(printf '%s\n' "${line}" | sed -n 's/^Bus \([0-9][0-9][0-9]\) Device \([0-9][0-9][0-9]\): ID \([0-9A-Fa-f]\{4\}:[0-9A-Fa-f]\{4\}\) \(.*\)$/\4/p')"

            [ -n "${bus_value}" ] || continue
            [ -n "${device_value}" ] || device_value='unknown'
            [ -n "${vidpid_value}" ] || vidpid_value='unknown'
            [ -n "${name_value}" ] || name_value='unknown'

            printf '%s\t%s\t%s\t%s\n' "${bus_value}" "${device_value}" "${vidpid_value}" "${name_value}"
        done
        return 0
    fi

    for device_dir in /sys/bus/usb/devices/*; do
        [ -d "${device_dir}" ] || continue

        case "$(basename "${device_dir}")" in
            usb*) continue ;;
        esac

        bus_value="$(rrm_read_sysfs_first_line "${device_dir}/busnum" 2>/dev/null || true)"
        device_value="$(rrm_read_sysfs_first_line "${device_dir}/devnum" 2>/dev/null || true)"
        vendor_value="$(rrm_read_sysfs_first_line "${device_dir}/idVendor" 2>/dev/null || true)"
        product_value="$(rrm_read_sysfs_first_line "${device_dir}/idProduct" 2>/dev/null || true)"
        manufacturer_value="$(rrm_read_sysfs_first_line "${device_dir}/manufacturer" 2>/dev/null || true)"
        name_value="$(rrm_read_sysfs_first_line "${device_dir}/product" 2>/dev/null || true)"

        [ -n "${vendor_value}" ] || continue

        if [ -n "${bus_value}" ] && [ "${bus_value}" -eq "${bus_value}" ] 2>/dev/null; then
            bus_value="$(printf '%03d' "${bus_value}")"
        else
            [ -n "${bus_value}" ] || bus_value='unknown'
        fi

        if [ -n "${device_value}" ] && [ "${device_value}" -eq "${device_value}" ] 2>/dev/null; then
            device_value="$(printf '%03d' "${device_value}")"
        else
            [ -n "${device_value}" ] || device_value='unknown'
        fi

        if [ -n "${vendor_value}" ] && [ -n "${product_value}" ]; then
            vidpid_value="${vendor_value}:${product_value}"
        else
            vidpid_value='unknown'
        fi

        if [ -n "${manufacturer_value}" ] && [ -n "${name_value}" ]; then
            name_value="${manufacturer_value} ${name_value}"
        elif [ -n "${manufacturer_value}" ]; then
            name_value="${manufacturer_value}"
        elif [ -n "${name_value}" ]; then
            name_value="${name_value}"
        else
            name_value="$(basename "${device_dir}")"
        fi

        printf '%s\t%s\t%s\t%s\n' "${bus_value}" "${device_value}" "${vidpid_value}" "${name_value}"
    done
}

rrm_lsusb_device_rows() {
    rrm_collect_usb_rows_internal
}

rrm_managed_file_label() {
    case "$1" in
        user-config) printf '%s\n' 'user-config.yml' ;;
        *) return 1 ;;
    esac
}

rrm_managed_file_path() {
    case "$1" in
        user-config) rrm_partition_path 1 user-config.yml ;;
        *) return 1 ;;
    esac
}

rrm_read_managed_file() {
    target_path="$(rrm_managed_file_path "$1")" || return 1
    [ -f "${target_path}" ] || return 1
    rrm_do cat "${target_path}"
}

rrm_backup_existing_path() {
    target_path="$1"
    backup_root="$2"
    [ -e "${target_path}" ] || return 0

    relative_path="$(rrm_relative_boot_path "${target_path}" 2>/dev/null || true)"
    [ -n "${relative_path}" ] || relative_path="$(basename "${target_path}")"
    backup_path="${backup_root}/${relative_path}"
    mkdir -p "$(dirname "${backup_path}")"

    if [ -d "${target_path}" ]; then
        rrm_do cp -Rp "${target_path}" "${backup_path}"
    else
        rrm_do cp -p "${target_path}" "${backup_path}"
    fi
}

rrm_write_managed_file() {
    file_id="$1"
    source_file="$2"
    target_path="$(rrm_managed_file_path "${file_id}")" || return 1
    timestamp="$(date '+%Y%m%d-%H%M%S')"
    backup_root="${STATE_DIR}/backups/manual-${timestamp}"
    temp_path="${target_path}.rrm.$$"

    case "${file_id}" in
        user-config)
            grep '[^[:space:]]' "${source_file}" >/dev/null 2>&1 || return 1
            rrm_validate_yaml_file "${source_file}" >/dev/null 2>&1 || return 1
            ;;
    esac

    rrm_do mkdir -p "$(dirname "${target_path}")" || return 1
    mkdir -p "${backup_root}" || return 1
    rrm_backup_existing_path "${target_path}" "${backup_root}"

    rrm_do cp "${source_file}" "${temp_path}" || return 1
    rrm_do mv "${temp_path}" "${target_path}" || return 1
    sync >/dev/null 2>&1 || true
}

rrm_trim() {
    printf '%s' "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

rrm_validate_yaml_file() {
    source_file="$1"
    rrm_ensure_dirs
    error_file="$(mktemp "${WORK_DIR}/yaml-validate.XXXXXX")" || return 1

    if command -v yq >/dev/null 2>&1; then
        yq eval '.' "${source_file}" >/dev/null 2>"${error_file}"
        status=$?
    elif command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1; then
        python3 -c 'import sys, yaml; yaml.safe_load(open(sys.argv[1], "r", encoding="utf-8").read())' "${source_file}" >/dev/null 2>"${error_file}"
        status=$?
    elif command -v python >/dev/null 2>&1 && python -c 'import yaml' >/dev/null 2>&1; then
        python -c 'import sys, yaml; yaml.safe_load(open(sys.argv[1], "r").read())' "${source_file}" >/dev/null 2>"${error_file}"
        status=$?
    else
        rm -f "${error_file}"
        return 0
    fi

    if [ "${status}" -ne 0 ]; then
        sed -n '/[^[:space:]]/ { s/\r$//; p; q; }' "${error_file}"
        rm -f "${error_file}"
        return 1
    fi

    rm -f "${error_file}"
    return 0
}

rrm_yaml_map_keys() {
    section_name="$1"
    target_file="$2"
    [ -f "${target_file}" ] || return 0

    awk -v section="${section_name}" '
        BEGIN { in_section = 0 }
        $0 ~ "^" section ":[[:space:]]*\\{\\}[[:space:]]*$" { exit }
        $0 ~ "^" section ":[[:space:]]*$" { in_section = 1; next }
        in_section && $0 ~ /^[^[:space:]]/ { exit }
        in_section {
            line = $0
            sub(/^[[:space:]]+/, "", line)
            sub(/:.*/, "", line)
            gsub(/^"/, "", line)
            gsub(/"$/, "", line)
            if (length(line) > 0) {
                print line
            }
        }
    ' "${target_file}"
}

rrm_yaml_scalar_value() {
    key_name="$1"
    target_file="$2"
    [ -f "${target_file}" ] || return 1

    awk -v key="${key_name}" '
        $0 ~ "^" key ":[[:space:]]*" {
            line = $0
            sub("^" key ":[[:space:]]*", "", line)
            sub(/[[:space:]]+#.*$/, "", line)
            gsub(/^"/, "", line)
            gsub(/"$/, "", line)
            if (line != "{}" && line != "[]" && line != "") {
                print line
                exit
            }
        }
    ' "${target_file}" | sed -n '1p'
}

rrm_yaml_map_has_key() {
    section_name="$1"
    map_key="$2"
    target_file="$3"

    rrm_yaml_map_keys "${section_name}" "${target_file}" | grep -Fx "${map_key}" >/dev/null 2>&1
}

rrm_render_yaml_map_section() {
    section_name="$1"
    entries_file="$2"

    if [ ! -s "${entries_file}" ]; then
        printf '%s: {}\n' "${section_name}"
        return 0
    fi

    printf '%s:\n' "${section_name}"
    while IFS= read -r entry; do
        entry="$(rrm_trim "${entry}")"
        [ -n "${entry}" ] || continue
        printf '  "%s": ""\n' "$(printf '%s' "${entry}" | sed 's/"/\\"/g')"
    done <"${entries_file}"
}

rrm_replace_yaml_map_section() {
    section_name="$1"
    entries_file="$2"
    target_file="$3"
    temp_file="$(mktemp "${WORK_DIR}/yaml-section.XXXXXX")" || return 1
    replacement_file="$(mktemp "${WORK_DIR}/section-${section_name}.XXXXXX")" || {
        rm -f "${temp_file}"
        return 1
    }

    rrm_render_yaml_map_section "${section_name}" "${entries_file}" >"${replacement_file}"

    awk -v section="${section_name}" -v replacement="${replacement_file}" '
        function emit_replacement(    line) {
            while ((getline line < replacement) > 0) {
                print line
            }
            close(replacement)
        }
        BEGIN {
            in_section = 0
            replaced = 0
            printed = 0
        }
        {
            if (in_section) {
                if ($0 ~ /^[^[:space:]]/ ) {
                    in_section = 0
                } else {
                    next
                }
            }

            if (!in_section && ($0 ~ "^" section ":[[:space:]]*$" || $0 ~ "^" section ":[[:space:]]*\\{\\}[[:space:]]*$")) {
                emit_replacement()
                replaced = 1
                in_section = 1
                next
            }

            print
            printed = 1
        }
        END {
            if (!replaced) {
                if (printed) {
                    print ""
                }
                emit_replacement()
            }
        }
    ' "${target_file}" >"${temp_file}" || {
        rm -f "${replacement_file}" "${temp_file}"
        return 1
    }

    if ! rrm_do cp -f "${temp_file}" "${target_file}"; then
        rm -f "${replacement_file}" "${temp_file}"
        return 1
    fi
    rm -f "${replacement_file}" "${temp_file}"
}

rrm_manifest_value() {
    manifest_file="$1"
    key_name="$2"
    [ -f "${manifest_file}" ] || return 1
    sed -n "s/^${key_name}:[[:space:]]*//p" "${manifest_file}" | head -n 1 | sed 's/^"//;s/"$//'
}

rrm_manifest_description() {
    manifest_file="$1"
    requested_locale="$(printf '%s' "${RRM_UI_LOCALE:-en_US}" | tr '-' '_' )"
    primary_locale="${requested_locale%%,*}"
    fallback_locale='en_US'
    zh_fallback_locale='zh_CN'
    [ -f "${manifest_file}" ] || return 1

    awk -v primary="${primary_locale}" -v fallback="${fallback_locale}" -v zhfallback="${zh_fallback_locale}" '
        BEGIN {
            in_description = 0
            lang_count = 0
        }
        /^description:[[:space:]]*($|#)/ { in_description = 1; next }
        in_description && /^[^[:space:]]/ { exit }
        in_description && /^[[:space:]]+[A-Za-z_]+:/ {
            line = $0
            key = $0
            sub(/:.*/, "", key)
            gsub(/^[[:space:]]+/, "", key)
            sub(/^[[:space:]]+[A-Za-z_]+:[[:space:]]*/, "", line)
            gsub(/^"/, "", line)
            gsub(/"$/, "", line)
            values[key] = line
            order[++lang_count] = key
        }
        END {
            if (values[primary] != "") {
                print values[primary]
            } else if (primary ~ /^zh_(HK|TW|MO)$/ && values[zhfallback] != "") {
                print values[zhfallback]
            } else if (values[fallback] != "") {
                print values[fallback]
            } else if (values[zhfallback] != "") {
                print values[zhfallback]
            } else if (lang_count > 0 && values[order[1]] != "") {
                print values[order[1]]
            }
        }
    ' "${manifest_file}" | head -n 1
}

rrm_addons_json() {
    config_file="$1"
    addons_root="$(rrm_partition_path 3 addons)"
    first=1

    [ -d "${addons_root}" ] || {
        printf '[]'
        return 0
    }

    printf '['
    for manifest_file in "${addons_root}"/*/manifest.yml; do
        [ -f "${manifest_file}" ] || continue
        addon_name="$(rrm_flatten_text "$(rrm_manifest_value "${manifest_file}" "name")")"
        [ -n "${addon_name}" ] || addon_name="$(basename "$(dirname "${manifest_file}")")"
        addon_system="$(rrm_flatten_text "$(rrm_manifest_value "${manifest_file}" "system")")"
        addon_description="$(rrm_flatten_text "$(rrm_manifest_description "${manifest_file}")")"
        installed='false'
        rrm_yaml_map_has_key "addons" "${addon_name}" "${config_file}" && installed='true'

        [ "${first}" -eq 1 ] || printf ','
        printf '{"name":%s,"system":%s,"description":%s,"installed":%s}' \
            "$(rrm_json_string "${addon_name}")" \
            "$(rrm_json_string "${addon_system}")" \
            "$(rrm_json_string "${addon_description}")" \
            "${installed}"
        first=0
    done

    printf ']'
}

rrm_module_source_label() {
    source_path="$1"
    source_name="$(basename "${source_path}")"
    case "${source_path}" in
        *.tgz|*.tar.gz)
            printf '%s\n' "${source_name}" | sed 's/\.tar\.gz$//;s/\.tgz$//'
            ;;
        *)
            printf '%s\n' "${source_name}"
            ;;
    esac
}

rrm_module_name_from_relative_path() {
    relative_path="$1"
    relative_path="$(printf '%s' "${relative_path}" | sed 's#^\./##;s#^\/*##;s#\.ko$##')"
    [ -n "${relative_path}" ] || return 1
    printf '%s\n' "${relative_path}"
}

rrm_module_entries_fallback() {
    source_path="$1"
    case "${source_path}" in
        *.tgz|*.tar.gz)
            tar -tf "${source_path}" 2>/dev/null | sed -n 's#^\./##;s#^\/*##;/\.ko$/ { s#\.ko$##; p; }' | awk 'NF { printf "%s\t%s\n", $0, $0 }'
            ;;
        *)
            find "${source_path}" -type f -name '*.ko' 2>/dev/null | while IFS= read -r module_file; do
                relative_path="${module_file#${source_path}/}"
                module_name="$(rrm_module_name_from_relative_path "${relative_path}" 2>/dev/null || basename "${module_file}" .ko)"
                printf '%s\t%s\n' "${module_name}" "${module_name}"
            done
            ;;
    esac
}

rrm_modinfo_bin() {
    for candidate in /sbin/modinfo /usr/sbin/modinfo /bin/modinfo /usr/bin/modinfo; do
        [ -x "${candidate}" ] || continue
        printf '%s\n' "${candidate}"
        return 0
    done

    if command -v modinfo >/dev/null 2>&1; then
        command -v modinfo
        return 0
    fi

    return 1
}

rrm_module_description_from_file() {
    module_file="$1"
    fallback_description="$2"
    modinfo_bin="$(rrm_modinfo_bin 2>/dev/null || true)"

    if [ -n "${modinfo_bin}" ]; then
        description_value="$("${modinfo_bin}" -F description "${module_file}" 2>/dev/null | sed -n '/[^[:space:]]/ { s/\r$//; p; q; }')"
        if [ -n "${description_value}" ]; then
            printf '%s\n' "${description_value}"
            return 0
        fi
    fi

    printf '%s\n' "${fallback_description}"
}

rrm_module_entries_from_path() {
    source_path="$1"
    temp_dir=''
    entries_tmp="$(mktemp "${WORK_DIR}/module-entry.XXXXXX")" || return 1

    case "${source_path}" in
        *.tgz|*.tar.gz)
            temp_dir="$(mktemp -d "${WORK_DIR}/moduleinfo.XXXXXX")" || return 1
            tar -xf "${source_path}" -C "${temp_dir}" >/dev/null 2>&1 || true
            find "${temp_dir}" -type f -name '*.ko' 2>/dev/null | while IFS= read -r module_file; do
                relative_path="${module_file#${temp_dir}/}"
                module_name="$(rrm_module_name_from_relative_path "${relative_path}" 2>/dev/null || basename "${module_file}" .ko)"
                module_description="$(rrm_flatten_text "$(rrm_module_description_from_file "${module_file}" "${module_name}" 2>/dev/null || printf '%s' "${module_name}")")"
                printf '%s\t%s\n' "${module_name}" "${module_description}" >>"${entries_tmp}"
            done
            rm -rf "${temp_dir}"
            ;;
        *)
            find "${source_path}" -type f -name '*.ko' 2>/dev/null | while IFS= read -r module_file; do
                relative_path="${module_file#${source_path}/}"
                module_name="$(rrm_module_name_from_relative_path "${relative_path}" 2>/dev/null || basename "${module_file}" .ko)"
                module_description="$(rrm_flatten_text "$(rrm_module_description_from_file "${module_file}" "${module_name}" 2>/dev/null || printf '%s' "${module_name}")")"
                printf '%s\t%s\n' "${module_name}" "${module_description}" >>"${entries_tmp}"
            done
            ;;
    esac

    if [ ! -s "${entries_tmp}" ]; then
        rrm_module_entries_fallback "${source_path}" >"${entries_tmp}" 2>/dev/null || true
    fi

    cat "${entries_tmp}"
    rm -f "${entries_tmp}"
}

rrm_modules_signature() {
    module_path="$1"
    selector_key="$2"

    if [ -z "${module_path}" ] || [ ! -e "${module_path}" ]; then
        printf '%s\n' 'missing'
        return 0
    fi

    {
        printf 'selector|%s\n' "${selector_key}"
        stat -c '%n|%Y|%s' "${module_path}" 2>/dev/null || ls -ldn "${module_path}" 2>/dev/null
    }
}

rrm_dsm_version_prefix() {
    if [ -x /bin/get_key_value ]; then
        majorversion="$(/bin/get_key_value /etc/VERSION majorversion 2>/dev/null)"
        minorversion="$(/bin/get_key_value /etc/VERSION minorversion 2>/dev/null)"
    else
        majorversion="$(sed -n 's/^majorversion=\"\([^\"]*\)\"$/\1/p' /etc/VERSION 2>/dev/null | head -n 1)"
        minorversion="$(sed -n 's/^minorversion=\"\([^\"]*\)\"$/\1/p' /etc/VERSION 2>/dev/null | head -n 1)"
    fi

    [ -n "${majorversion}" ] || return 1
    [ -n "${minorversion}" ] || return 1
    printf '%s.%s\n' "${majorversion}" "${minorversion}"
}

rrm_current_module_selector() {
    config_file="$1"
    platform="$(rrm_yaml_scalar_value "platform" "${config_file}" 2>/dev/null || true)"
    kver="$(rrm_yaml_scalar_value "kver" "${config_file}" 2>/dev/null || true)"
    kpre="$(rrm_yaml_scalar_value "kpre" "${config_file}" 2>/dev/null || true)"
    kernel_kind="$(rrm_yaml_scalar_value "kernel" "${config_file}" 2>/dev/null || true)"
    productver="$(rrm_yaml_scalar_value "productver" "${config_file}" 2>/dev/null || true)"

    [ -n "${platform}" ] || return 1

    if [ -z "${kver}" ] && [ -n "${productver}" ]; then
        release_value="$(uname -r 2>/dev/null | sed 's/[-+].*$//')"
        kver="$(printf '%s\n' "${release_value}" | cut -d'.' -f1-3)"
        if [ -n "${kver}" ]; then
            kernel_major="$(printf '%s\n' "${kver}" | cut -d'.' -f1)"
            if [ "${kernel_major:-4}" -lt 5 ] 2>/dev/null; then
                kpre=''
            else
                kpre="$(rrm_dsm_version_prefix 2>/dev/null || true)"
            fi
        fi
    fi

    [ -n "${kver}" ] || return 1
    pkver="${kpre:+${kpre}-}${kver}"
    printf '%s|%s|%s\n' "${kernel_kind}" "${platform}" "${pkver}"
}

rrm_current_module_path() {
    config_file="$1"
    selector="$(rrm_current_module_selector "${config_file}" 2>/dev/null || true)"
    [ -n "${selector}" ] || return 1

    kernel_kind="$(printf '%s' "${selector}" | cut -d'|' -f1)"
    platform="$(printf '%s' "${selector}" | cut -d'|' -f2)"
    pkver="$(printf '%s' "${selector}" | cut -d'|' -f3)"

    if [ "${kernel_kind}" = "custom" ]; then
        primary_path="$(rrm_partition_path 3 "cks/modules-${platform}-${pkver}.tgz")"
        fallback_path="$(rrm_partition_path 3 "modules/${platform}-${pkver}.tgz")"
    else
        primary_path="$(rrm_partition_path 3 "modules/${platform}-${pkver}.tgz")"
        fallback_path="$(rrm_partition_path 3 "cks/modules-${platform}-${pkver}.tgz")"
    fi

    if [ -f "${primary_path}" ]; then
        printf '%s\n' "${primary_path}"
        return 0
    fi
    if [ -f "${fallback_path}" ]; then
        printf '%s\n' "${fallback_path}"
        return 0
    fi

    return 1
}

rrm_modules_name_cache() {
    module_path="$1"
    selector_key="$2"
    cache_names="${WORK_DIR}/modules-meta.cache"
    cache_sig="${WORK_DIR}/modules-meta.sig"
    sig_tmp="$(mktemp "${WORK_DIR}/modules-sig.XXXXXX")" || return 1
    build_tmp="$(mktemp "${WORK_DIR}/modules-build.XXXXXX")" || {
        rm -f "${sig_tmp}"
        return 1
    }

    rrm_modules_signature "${module_path}" "${selector_key}" >"${sig_tmp}"

    if [ -f "${cache_names}" ] && [ -f "${cache_sig}" ] && cmp -s "${sig_tmp}" "${cache_sig}"; then
        rm -f "${sig_tmp}" "${build_tmp}"
        printf '%s\n' "${cache_names}"
        return 0
    fi

    : >"${build_tmp}"
    if [ -n "${module_path}" ] && [ -e "${module_path}" ]; then
        rrm_module_entries_from_path "${module_path}" >>"${build_tmp}"
    fi

    sort -u "${build_tmp}" | awk -F '\t' 'NF { if (!seen[$1]++) print $0 }' >"${cache_names}.tmp" || {
        rm -f "${sig_tmp}" "${build_tmp}" "${cache_names}.tmp"
        return 1
    }
    if [ ! -s "${cache_names}.tmp" ] && [ -f "${cache_names}" ]; then
        rm -f "${sig_tmp}" "${build_tmp}" "${cache_names}.tmp"
        printf '%s\n' "${cache_names}"
        return 0
    fi
    mv "${cache_names}.tmp" "${cache_names}" || {
        rm -f "${sig_tmp}" "${build_tmp}" "${cache_names}.tmp"
        return 1
    }
    mv "${sig_tmp}" "${cache_sig}" || {
        rm -f "${build_tmp}"
        return 1
    }
    rm -f "${build_tmp}"

    printf '%s\n' "${cache_names}"
}

rrm_modules_json() {
    config_file="$1"
    selected_entries="$(mktemp "${WORK_DIR}/modules-selected.XXXXXX")" || return 1
    selector_key="$(rrm_current_module_selector "${config_file}" 2>/dev/null || true)"
    module_path="$(rrm_current_module_path "${config_file}" 2>/dev/null || true)"

    if [ -z "${selector_key}" ] || [ -z "${module_path}" ] || [ ! -f "${module_path}" ]; then
        rm -f "${selected_entries}"
        printf '[]'
        return 0
    fi

    names_file="$(rrm_modules_name_cache "${module_path}" "${selector_key}" 2>/dev/null || true)"

    [ -n "${names_file}" ] && [ -f "${names_file}" ] || {
        rm -f "${selected_entries}"
        printf '[]'
        return 0
    }

    rrm_yaml_map_keys "modules" "${config_file}" | sort -u >"${selected_entries}"

    first=1
    printf '['
    while IFS="$(printf '\t')" read -r original description; do
        [ -n "${original}" ] || continue
        description="$(rrm_flatten_text "${description}")"
        installed='false'
        if grep -Fx "${original}" "${selected_entries}" >/dev/null 2>&1; then
            installed='true'
        fi
        [ "${first}" -eq 1 ] || printf ','
        printf '{"name":%s,"description":%s,"installed":%s}' \
            "$(rrm_json_string "${original}")" \
            "$(rrm_json_string "${description}")" \
            "${installed}"
        first=0
    done <"${names_file}"
    printf ']'

    rm -f "${selected_entries}"
}

rrm_http_get() {
    if command -v curl >/dev/null 2>&1; then
        curl -fskL --connect-timeout 10 "$1"
        return $?
    fi
    if command -v wget >/dev/null 2>&1; then
        wget --no-check-certificate -qO- "$1"
        return $?
    fi
    return 1
}

rrm_http_resolve_effective_url() {
    if command -v curl >/dev/null 2>&1; then
        curl -fskL --connect-timeout 10 -w '%{url_effective}' -o /dev/null "$1"
        return $?
    fi
    if command -v wget >/dev/null 2>&1; then
        wget --no-check-certificate --server-response --max-redirect=20 --spider "$1" 2>&1 |
            awk '/^[[:space:]]*Location: / { location = $2 } END { gsub(/\r/, "", location); if (location != "") print location; }'
        return $?
    fi
    return 1
}

rrm_http_exists() {
    if command -v curl >/dev/null 2>&1; then
        curl -fskIL --connect-timeout 10 "$1" >/dev/null 2>&1
        return $?
    fi
    if command -v wget >/dev/null 2>&1; then
        wget --no-check-certificate -q --spider "$1"
        return $?
    fi
    return 1
}

rrm_download_to() {
    url="$1"
    output_path="$2"
    mkdir -p "$(dirname "${output_path}")"

    if command -v curl >/dev/null 2>&1; then
        curl -fkL --retry 2 --connect-timeout 10 --output "${output_path}" "${url}"
        return $?
    fi
    if command -v wget >/dev/null 2>&1; then
        wget --no-check-certificate -O "${output_path}" "${url}"
        return $?
    fi
    return 1
}

rrm_release_normalize_tag() {
    printf '%s\n' "$1" | sed 's#/$##; s#.*/##; s/^[vV]//'
}

rrm_fetch_latest_release_tag() {
    if [ "${PRERELEASE}" = "true" ]; then
        rrm_http_get "${RELEASE_TAGS_URL}" |
            grep '/refs/tags/.*\.zip' |
            sed -E 's#.*\/refs\/tags\/(.*)\.zip.*#\1#' |
            sort -rV |
            head -n 1 |
            sed 's/^[vV]//'
        return $?
    fi

    latest_url="$(rrm_http_resolve_effective_url "${RELEASE_LATEST_URL}" 2>/dev/null | sed -n '1{s/\r$//;p;}')"
    [ -n "${latest_url}" ] || return 1
    rrm_release_normalize_tag "${latest_url}"
}

rrm_release_html_url() {
    tag_value="$1"
    printf '%s/releases/tag/%s\n' "${RELEASE_REPO_URL}" "${tag_value}"
}

rrm_release_published_at() {
    tag_value="$1"
    [ -n "${tag_value}" ] || return 1

    rrm_http_get "$(rrm_release_html_url "${tag_value}")" 2>/dev/null |
        grep -m 1 'relative-time[^>]*datetime=' |
        sed -n 's/.*datetime="\([^"]*\)".*/\1/p'
}

rrm_release_asset_info() {
    tag_value="$1"
    [ -n "${tag_value}" ] || return 1

    for asset_name in "updateall-${tag_value}.zip" "update-${tag_value}.zip"; do
        asset_url="${RELEASE_DOWNLOAD_BASE_URL}/${tag_value}/${asset_name}"
        if rrm_http_exists "${asset_url}"; then
            printf '%s\t%s\n' "${asset_name}" "${asset_url}"
            return 0
        fi
    done

    asset_name="updateall-${tag_value}.zip"
    asset_url="${RELEASE_DOWNLOAD_BASE_URL}/${tag_value}/${asset_name}"
    printf '%s\t%s\n' "${asset_name}" "${asset_url}"
}

rrm_write_update_state() {
    update_state_value="$1"
    update_message_value="$2"
    update_version_value="${3:-}"
    update_source_value="${4:-}"
    temp_state="${UPDATE_STATE}.tmp.$$"

    rrm_ensure_dirs
    {
        printf 'state\t%s\n' "${update_state_value}"
        printf 'message\t%s\n' "${update_message_value}"
        printf 'version\t%s\n' "${update_version_value}"
        printf 'source\t%s\n' "${update_source_value}"
        printf 'updated_at\t%s\n' "$(rrm_now)"
    } >"${temp_state}"
    mv "${temp_state}" "${UPDATE_STATE}"
}

rrm_clear_update_log() {
    rrm_ensure_dirs
    : >"${UPDATE_LOG}"
}

rrm_reset_update_tracking() {
    rrm_write_update_state "idle" "Ready." "" ""
    rrm_clear_update_log
}

rrm_build_flag_path() {
    rrm_partition_path 1 .build
}

rrm_upgraded_flag_path() {
    rrm_partition_path 1 .upgraded
}

rrm_mark_build_pending() {
    build_flag_path="$(rrm_build_flag_path 2>/dev/null || true)"
    [ -n "${build_flag_path}" ] || return 1
    rrm_do touch "${build_flag_path}"
}

rrm_mark_update_pending() {
    upgraded_flag_path="$(rrm_upgraded_flag_path 2>/dev/null || true)"
    [ -n "${upgraded_flag_path}" ] || return 1
    rrm_mark_build_pending || return 1
    rrm_do touch "${upgraded_flag_path}"
}

rrm_reboot_pending_kind() {
    upgraded_flag_path="$(rrm_upgraded_flag_path 2>/dev/null || true)"
    build_flag_path="$(rrm_build_flag_path 2>/dev/null || true)"

    if [ -n "${upgraded_flag_path}" ] && [ -f "${upgraded_flag_path}" ]; then
        printf '%s\n' 'update'
        return 0
    fi
    if [ -n "${build_flag_path}" ] && [ -f "${build_flag_path}" ]; then
        printf '%s\n' 'build'
        return 0
    fi
    return 1
}

rrm_reboot_pending_message() {
    case "$1" in
        update)
            printf '%s\n' 'RR update completed. Reboot DSM when you are ready.'
            ;;
        build)
            printf '%s\n' 'Configuration changes completed. Reboot DSM when you are ready.'
            ;;
        *)
            printf '%s\n' 'Reboot DSM when you are ready.'
            ;;
    esac
}

rrm_reset_update_tracking_if_reboot_cleared() {
    current_state="$1"

    rrm_is_update_running && return 1
    if rrm_reboot_pending_kind >/dev/null 2>&1; then
        return 1
    fi

    if [ -z "${current_state}" ]; then
        current_state="$(rrm_read_update_state_field state 2>/dev/null || true)"
    fi

    case "${current_state}" in
        success|pending-reboot|reboot-required)
            rrm_reset_update_tracking
            return 0
            ;;
    esac

    return 1
}

rrm_read_update_state_field() {
    [ -f "${UPDATE_STATE}" ] || return 1
    awk -F '\t' -v key="$1" '$1 == key { print substr($0, index($0, FS) + length(FS)); exit }' "${UPDATE_STATE}"
}

rrm_is_update_running() {
    [ -f "${UPDATE_PID_FILE}" ] || return 1
    update_pid="$(sed -n '1p' "${UPDATE_PID_FILE}" 2>/dev/null)"
    [ -n "${update_pid}" ] || return 1
    if kill -0 "${update_pid}" >/dev/null 2>&1; then
        return 0
    fi
    rm -f "${UPDATE_PID_FILE}"
    return 1
}

rrm_read_update_log_tail() {
    [ -f "${UPDATE_LOG}" ] || return 0
    tail -n 200 "${UPDATE_LOG}" | tr '\r' '\n' | sed '/^[[:space:]]*$/d'
}

rrm_translate_update_target() {
    case "$1" in
        /mnt/p1) rrm_partition_path 1 ;;
        /mnt/p2) rrm_partition_path 2 ;;
        /mnt/p3) rrm_partition_path 3 ;;
        /mnt/p1/*) rrm_partition_path 1 "${1#/mnt/p1/}" ;;
        /mnt/p2/*) rrm_partition_path 2 "${1#/mnt/p2/}" ;;
        /mnt/p3/*) rrm_partition_path 3 "${1#/mnt/p3/}" ;;
        *) return 1 ;;
    esac
}

rrm_resolve_update_payload_path() {
    update_root="$1"
    source_rel="$2"
    target_rel="$3"

    source_rel_clean="${source_rel#/}"
    target_rel_clean="${target_rel#/}"
    source_basename="$(basename "${source_rel_clean}")"
    target_basename="$(basename "${target_rel_clean}")"

    for candidate in \
        "${update_root}/${target_rel_clean}" \
        "${update_root}/${source_rel_clean}" \
        "${update_root}/files/${target_rel_clean}" \
        "${update_root}/${source_rel_clean#files/}" \
        "${update_root}/${source_basename}" \
        "${update_root}/${target_basename}"
    do
        [ -e "${candidate}" ] || continue
        printf '%s\n' "${candidate}"
        return 0
    done

    return 1
}

rrm_stage_update_payloads() {
    update_root="$1"
    update_list="$2"
    staged_root="$3"

    mkdir -p "${staged_root}" || return 1

    in_replace_section=0
    while IFS= read -r line; do
        case "${line}" in
            replace:*)
                in_replace_section=1
                continue
                ;;
            [![:space:]]*:*)
                [ "${line}" = "replace:" ] || in_replace_section=0
                ;;
        esac
        [ "${in_replace_section}" -eq 1 ] || continue

        replace_pair="$(printf '%s\n' "${line}" | sed -n 's/^[[:space:]]*"\([^"]*\)"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1|\2/p')"
        [ -n "${replace_pair}" ] || continue

        source_rel="${replace_pair%%|*}"
        target_rel="${replace_pair#*|}"
        source_rel_clean="${source_rel#/}"
        target_rel_clean="${target_rel#/}"
        staged_path="${staged_root}/${target_rel_clean}"

        case "${source_rel}" in
            */)
                payload_archive="${update_root}/$(basename "${source_rel%/}").tgz"
                [ -f "${payload_archive}" ] || payload_archive="${update_root}/$(basename "${target_rel_clean}").tgz"
                [ -f "${payload_archive}" ] || return 1
                rm -rf "${staged_path}"
                mkdir -p "${staged_path}" || return 1
                tar -zxf "${payload_archive}" -C "${staged_path}" >>"${UPDATE_LOG}" 2>&1 || return 1
                ;;
            *)
                payload_path="$(rrm_resolve_update_payload_path "${update_root}" "${source_rel}" "${target_rel}" 2>/dev/null || true)"
                [ -n "${payload_path}" ] && [ -e "${payload_path}" ] || return 1
                mkdir -p "$(dirname "${staged_path}")" || return 1
                cp -f "${payload_path}" "${staged_path}" >>"${UPDATE_LOG}" 2>&1 || return 1
                ;;
        esac
    done <"${update_list}"

    return 0
}

rrm_path_size_mb() {
    target_path="$1"
    [ -e "${target_path}" ] || {
        printf '%s\n' '0'
        return 0
    }

    size_value="$(rrm_do du -sm "${target_path}" 2>/dev/null | awk 'NR == 1 { print $1 }')"
    printf '%s\n' "${size_value:-0}"
}

rrm_check_update_space() {
    staged_root="$1"
    update_list="$2"
    total_new=0
    total_old=0

    in_replace_section=0
    while IFS= read -r line; do
        case "${line}" in
            replace:*)
                in_replace_section=1
                continue
                ;;
            [![:space:]]*:*)
                [ "${line}" = "replace:" ] || in_replace_section=0
                ;;
        esac
        [ "${in_replace_section}" -eq 1 ] || continue

        replace_pair="$(printf '%s\n' "${line}" | sed -n 's/^[[:space:]]*"\([^"]*\)"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1|\2/p')"
        [ -n "${replace_pair}" ] || continue

        target_rel="${replace_pair#*|}"
        target_rel_clean="${target_rel#/}"
        staged_path="${staged_root}/${target_rel_clean}"
        target_path="$(rrm_translate_update_target "${target_rel}")" || continue

        new_size="$(rrm_path_size_mb "${staged_path}")"
        old_size="$(rrm_path_size_mb "${target_path}")"
        total_new=$((total_new + ${new_size:-0}))
        total_old=$((total_old + ${old_size:-0}))
    done <"${update_list}"

    free_mb="$(rrm_do df -m "$(rrm_partition_path 3)" 2>/dev/null | awk 'NR == 2 { print $4 }')"
    free_mb="${free_mb:-0}"

    if [ "${total_new:-0}" -ge $(( ${total_old:-0} + ${free_mb:-0} )) ]; then
        echo "Not enough disk space. Need ${total_new:-0}MB, but only $(( ${total_old:-0} + ${free_mb:-0} ))MB available." >>"${UPDATE_LOG}"
        return 1
    fi

    return 0
}

rrm_refresh_modules_config_after_update() {
    modules_root="$1"
    config_path="$(rrm_managed_file_path user-config 2>/dev/null || true)"
    [ -n "${config_path}" ] && [ -f "${config_path}" ] || return 0
    [ -d "${modules_root}" ] || return 0

    selector_key="$(rrm_current_module_selector "${config_path}" 2>/dev/null || true)"
    module_path="$(rrm_current_module_path "${config_path}" 2>/dev/null || true)"
    [ -n "${selector_key}" ] && [ -n "${module_path}" ] && [ -f "${module_path}" ] || return 0

    names_file="$(rrm_modules_name_cache "${module_path}" "${selector_key}" 2>/dev/null || true)"
    [ -n "${names_file}" ] && [ -f "${names_file}" ] || return 0

    entries_file="$(mktemp "${WORK_DIR}/modules-refresh.XXXXXX")" || return 1
    awk -F '\t' 'NF { print $1 }' "${names_file}" >"${entries_file}"

    if ! rrm_replace_yaml_map_section "modules" "${entries_file}" "${config_path}"; then
        rm -f "${entries_file}"
        return 1
    fi

    rm -f "${entries_file}"
    return 0
}

rrm_apply_update_archive() {
    archive_path="$1"
    temp_dir="$(mktemp -d "${WORK_DIR}/update.XXXXXX")" || return 1
    expanded_dir="${temp_dir}/expanded"
    staged_dir="${temp_dir}/staged"
    update_list="${temp_dir}/update-list.yml"
    backup_root="${STATE_DIR}/backups/update-$(date '+%Y%m%d-%H%M%S')"

    mkdir -p "${expanded_dir}" "${staged_dir}" "${backup_root}"

    unzip -oq "${archive_path}" -d "${temp_dir}" >>"${UPDATE_LOG}" 2>&1 || {
        echo "Failed to extract ${archive_path}" >>"${UPDATE_LOG}"
        rm -rf "${temp_dir}"
        return 1
    }

    if [ -f "${temp_dir}/sha256sum" ]; then
        (
            cd "${temp_dir}" &&
            sha256sum --status -c sha256sum
        ) >>"${UPDATE_LOG}" 2>&1 || {
            echo "Checksum validation failed." >>"${UPDATE_LOG}"
            rm -rf "${temp_dir}"
            return 1
        }
    fi

    if [ -f "${temp_dir}/update-check.sh" ]; then
        chmod a+x "${temp_dir}/update-check.sh" >>"${UPDATE_LOG}" 2>&1 || true
        (
            cd "${temp_dir}" &&
            bash ./update-check.sh
        ) >>"${UPDATE_LOG}" 2>&1 || {
            echo "The update archive is not compatible with the current environment." >>"${UPDATE_LOG}"
            rm -rf "${temp_dir}"
            return 1
        }
    fi

    [ -f "${update_list}" ] || {
        echo "update-list.yml is missing from the archive." >>"${UPDATE_LOG}"
        rm -rf "${temp_dir}"
        return 1
    }

    if ! rrm_stage_update_payloads "${temp_dir}" "${update_list}" "${staged_dir}"; then
        echo "Failed to stage update payloads from update-list.yml." >>"${UPDATE_LOG}"
        rm -rf "${temp_dir}"
        return 1
    fi

    rrm_mount_synoboot || {
        echo "Unable to mount /dev/synoboot1-3." >>"${UPDATE_LOG}"
        rm -rf "${temp_dir}"
        return 1
    }

    if ! rrm_check_update_space "${staged_dir}" "${update_list}"; then
        rm -rf "${temp_dir}"
        return 1
    fi

    modules_target="$(cd "$(rrm_partition_path 3 modules)" 2>/dev/null && pwd)"

    in_remove_section=0
    while IFS= read -r line; do
        case "${line}" in
            remove:*)
                in_remove_section=1
                continue
                ;;
            replace:*)
                in_remove_section=0
                continue
                ;;
        esac
        [ "${in_remove_section}" -eq 1 ] || continue

        remove_target="$(printf '%s\n' "${line}" | sed -n 's/^[[:space:]]*-[[:space:]]*"\([^"]*\)".*/\1/p')"
        [ -n "${remove_target}" ] || continue
        target_path="$(rrm_translate_update_target "${remove_target}")" || continue
        rrm_backup_existing_path "${target_path}" "${backup_root}"
        rrm_do rm -rf "${target_path}" >>"${UPDATE_LOG}" 2>&1 || {
            echo "Failed to remove ${target_path}" >>"${UPDATE_LOG}"
            rm -rf "${temp_dir}"
            return 1
        }
    done <"${update_list}"

    in_replace_section=0
    while IFS= read -r line; do
        case "${line}" in
            replace:*)
                in_replace_section=1
                continue
                ;;
            [![:space:]]*:*)
                [ "${line}" = "replace:" ] || in_replace_section=0
                ;;
        esac
        [ "${in_replace_section}" -eq 1 ] || continue

        replace_pair="$(printf '%s\n' "${line}" | sed -n 's/^[[:space:]]*"\([^"]*\)"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1|\2/p')"
        [ -n "${replace_pair}" ] || continue

        target_rel="${replace_pair#*|}"
        target_rel_clean="${target_rel#/}"
        source_path="${staged_dir}/${target_rel_clean}"
        target_path="$(rrm_translate_update_target "${target_rel}")" || continue

        if [ ! -e "${source_path}" ]; then
            echo "Missing staged update payload ${target_rel}" >>"${UPDATE_LOG}"
            rm -rf "${temp_dir}"
            return 1
        fi

        rrm_backup_existing_path "${target_path}" "${backup_root}"
        if [ -d "${source_path}" ]; then
            rrm_do mkdir -p "${target_path}" >>"${UPDATE_LOG}" 2>&1 || {
                echo "Failed to create ${target_path}" >>"${UPDATE_LOG}"
                rm -rf "${temp_dir}"
                return 1
            }
            rrm_do cp -Rf "${source_path}/." "${target_path}/" >>"${UPDATE_LOG}" 2>&1 || {
                echo "Failed to copy ${source_path} to ${target_path}" >>"${UPDATE_LOG}"
                rm -rf "${temp_dir}"
                return 1
            }
        else
            rrm_do mkdir -p "$(dirname "${target_path}")" >>"${UPDATE_LOG}" 2>&1 || {
                echo "Failed to create $(dirname "${target_path}")" >>"${UPDATE_LOG}"
                rm -rf "${temp_dir}"
                return 1
            }
            rrm_do cp -f "${source_path}" "${target_path}" >>"${UPDATE_LOG}" 2>&1 || {
                echo "Failed to copy ${source_path} to ${target_path}" >>"${UPDATE_LOG}"
                rm -rf "${temp_dir}"
                return 1
            }
        fi

        if [ -d "${source_path}" ]; then
            target_realpath="$(cd "${target_path}" 2>/dev/null && pwd)"
            if [ -n "${modules_target}" ] && [ "${target_realpath}" = "${modules_target}" ]; then
                if ! rrm_refresh_modules_config_after_update "${modules_target}"; then
                    echo "Failed to refresh modules configuration after modules update." >>"${UPDATE_LOG}"
                    rm -rf "${temp_dir}"
                    return 1
                fi
            fi
        fi
    done <"${update_list}"

    rrm_mark_update_pending >>"${UPDATE_LOG}" 2>&1 || {
        echo "Failed to mark reboot required after update." >>"${UPDATE_LOG}"
        rm -rf "${temp_dir}"
        return 1
    }
    sync >/dev/null 2>&1 || true
    rm -rf "${temp_dir}"
    return 0
}
