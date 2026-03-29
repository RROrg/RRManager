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
RELEASE_API_URL="${RELEASE_API_URL:-https://api.github.com/repos/RROrg/rr/releases/latest}"
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
    mount_point="${MOUNT_BASE}/p${partition}"

    [ -b "${device}" ] || return 1
    rrm_do mkdir -p "${mount_point}" || return 1

    if rrm_mount_source_is "${mount_point}" "${device}"; then
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

    if [ "${RRM_SKIP_MOUNT:-0}" = "1" ] && [ -d "${MOUNT_BASE}/p1" ]; then
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

    rrm_mount_source_is "${MOUNT_BASE}/p1" /dev/synoboot1
}

rrm_current_version() {
    version_file="${MOUNT_BASE}/p1/RR_VERSION"
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
    core_count="$(grep -c '^processor' /proc/cpuinfo 2>/dev/null || true)"
    [ -n "${core_count}" ] && [ "${core_count}" -gt 0 ] 2>/dev/null || core_count='unknown'
    printf '%s\n' "${core_count}"
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

rrm_boot_access_method() {
    if [ "$(id -u)" = "0" ]; then
        printf '%s\n' 'internal /dev/synoboot* (root)'
    elif [ -x "${RRMDO_BIN}" ]; then
        printf '%s\n' "internal /dev/synoboot* via $(basename "${RRMDO_BIN}")"
    else
        printf '%s\n' 'internal /dev/synoboot*'
    fi
}

rrm_managed_file_label() {
    case "$1" in
        user-config) printf '%s\n' 'user-config.yml' ;;
        *) return 1 ;;
    esac
}

rrm_managed_file_path() {
    case "$1" in
        user-config) printf '%s\n' "${MOUNT_BASE}/p1/user-config.yml" ;;
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

    relative_path="${target_path#${MOUNT_BASE}/}"
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
    addons_root="${MOUNT_BASE}/p3/addons"
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
        primary_path="${MOUNT_BASE}/p3/cks/modules-${platform}-${pkver}.tgz"
        fallback_path="${MOUNT_BASE}/p3/modules/${platform}-${pkver}.tgz"
    else
        primary_path="${MOUNT_BASE}/p3/modules/${platform}-${pkver}.tgz"
        fallback_path="${MOUNT_BASE}/p3/cks/modules-${platform}-${pkver}.tgz"
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
        curl -fsSL "$1"
        return $?
    fi
    if command -v wget >/dev/null 2>&1; then
        wget -qO- "$1"
        return $?
    fi
    return 1
}

rrm_download_to() {
    url="$1"
    output_path="$2"
    mkdir -p "$(dirname "${output_path}")"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL --retry 2 --output "${output_path}" "${url}"
        return $?
    fi
    if command -v wget >/dev/null 2>&1; then
        wget -q -O "${output_path}" "${url}"
        return $?
    fi
    return 1
}

rrm_fetch_latest_release_json() {
    rrm_http_get "${RELEASE_API_URL}" | tr -d '\r\n\t '
}

rrm_release_tag_from_json() {
    printf '%s' "$1" | sed -n 's/.*"tag_name":"\([^"]*\)".*/\1/p'
}

rrm_release_published_from_json() {
    printf '%s' "$1" | sed -n 's/.*"published_at":"\([^"]*\)".*/\1/p'
}

rrm_release_asset_line_from_json() {
    json_payload="$1"
    asset_line="$(printf '%s' "${json_payload}" | sed 's/},{/}\n{/g' | grep '"name":"updateall-[^"]*\.zip"' | head -n 1)"
    if [ -n "${asset_line}" ]; then
        printf '%s\n' "${asset_line}"
        return 0
    fi
    printf '%s' "${json_payload}" | sed 's/},{/}\n{/g' | grep '"name":"update-[^"]*\.zip"' | head -n 1
}

rrm_release_asset_name_from_line() {
    printf '%s' "$1" | sed -n 's/.*"name":"\([^"]*\)".*/\1/p'
}

rrm_release_asset_url_from_line() {
    printf '%s' "$1" | sed -n 's/.*"browser_download_url":"\([^"]*\)".*/\1/p'
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

rrm_read_update_state_field() {
    [ -f "${UPDATE_STATE}" ] || return 1
    awk -F '\t' -v key="$1" '$1 == key { $1 = ""; sub(/^\t/, "", $0); print; exit }' "${UPDATE_STATE}"
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
    tail -n 200 "${UPDATE_LOG}"
}

rrm_translate_update_target() {
    case "$1" in
        /mnt/p1) printf '%s\n' "${MOUNT_BASE}/p1" ;;
        /mnt/p2) printf '%s\n' "${MOUNT_BASE}/p2" ;;
        /mnt/p3) printf '%s\n' "${MOUNT_BASE}/p3" ;;
        /mnt/p1/*) printf '%s/%s\n' "${MOUNT_BASE}/p1" "${1#/mnt/p1/}" ;;
        /mnt/p2/*) printf '%s/%s\n' "${MOUNT_BASE}/p2" "${1#/mnt/p2/}" ;;
        /mnt/p3/*) printf '%s/%s\n' "${MOUNT_BASE}/p3" "${1#/mnt/p3/}" ;;
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

    free_mb="$(rrm_do df -m "${MOUNT_BASE}/p3" 2>/dev/null | awk 'NR == 2 { print $4 }')"
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

    modules_target="$(cd "${MOUNT_BASE}/p3/modules" 2>/dev/null && pwd)"

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

    rrm_do touch "${MOUNT_BASE}/p1/.upgraded" >>"${UPDATE_LOG}" 2>&1 || true
    rrm_do touch "${MOUNT_BASE}/p1/.build" >>"${UPDATE_LOG}" 2>&1 || true
    sync >/dev/null 2>&1 || true
    rm -rf "${temp_dir}"
    return 0
}
