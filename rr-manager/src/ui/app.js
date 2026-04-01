(function () {
    var page = document.body.getAttribute('data-page');
    var I18N = {
        en: {
            'title.shell': 'RR Manager',
            'title.overview': 'Overview - RR Manager',
            'title.hardware': 'Hardware - RR Manager',
            'title.config': 'Config - RR Manager',
            'title.addons': 'addons - RR Manager',
            'title.modules': 'Modules - RR Manager',
            'title.update': 'Update - RR Manager',
            'common.appName': 'RR Manager',
            'common.loading': 'Loading...',
            'common.refresh': 'Refresh',
            'common.reload': 'Reload',
            'common.save': 'Save',
            'common.saved': 'Saved successfully.',
            'common.rebootPending': 'pending reboot',
            'common.rebootRequiredHint': 'Reboot DSM when you are ready.',
            'common.unknown': 'unknown',
            'common.idle': 'idle',
            'common.running': 'running',
            'common.busy': 'busy',
            'common.ready': 'Ready.',
            'common.present': 'present',
            'common.yes': 'yes',
            'common.no': 'no',
            'common.state': 'State',
            'common.hardware': 'Hardware',
            'common.boot': 'Boot',
            'common.loader': 'Loader',
            'common.pleaseWait': 'Please wait',
            'common.noItems': 'No items found.',
            'common.noLog': 'No log output yet.',
            'common.readFailed': 'Read failed.',
            'nav.overview': 'Overview',
            'nav.hardware': 'Hardware',
            'nav.config': 'Config',
            'nav.addons': 'addons',
            'nav.modules': 'Modules',
            'nav.update': 'Update',
            'shell.eyebrow': 'DSM Bootloader Control',
            'shell.lead': 'Bootloader manager for RR.',
            'shell.logoAria': 'RR Logo',
            'shell.logoAlt': 'RR Logo',
            'shell.contentTitle': 'RR Manager Content',
            'shell.languageAria': 'Language',
            'overview.deviceEyebrow': 'Hardware',
            'overview.deviceTitle': 'Device Info',
            'overview.bootEyebrow': 'Bootloader',
            'overview.bootTitle': 'Boot Info',
            'overview.dmi': 'DMI',
            'overview.deviceType': 'Type',
            'overview.cpu': 'CPU',
            'overview.memory': 'Memory',
            'overview.dmiVendor': 'DMI Vendor',
            'overview.product': 'Product',
            'overview.productVersion': 'Product Version',
            'overview.bios': 'BIOS',
            'overview.cpuCores': 'CPU Cores',
            'overview.currentVersion': 'Current RR Version',
            'overview.diskType': 'Disk Type',
            'overview.bootModel': 'Model',
            'overview.bootVersion': 'Version',
            'overview.bootKernel': 'Kernel',
            'overview.bootLkm': 'LKM',
            'overview.bootMev': 'MEV',
            'overview.bootAuth': 'Auth',
            'hardware.pciEyebrow': 'PCI Hardware',
            'hardware.pciTitle': 'PCI Devices / Drivers',
            'hardware.pciPath': 'PCI Path',
            'hardware.pciType': 'Type',
            'hardware.pciDevice': 'Device',
            'hardware.pciVidPid': 'VID:PID',
            'hardware.pciDriver': 'Driver',
            'hardware.pciEmpty': 'No PCI device data found.',
            'hardware.usbEyebrow': 'USB Hardware',
            'hardware.usbTitle': 'USB Devices',
            'hardware.usbBus': 'Bus',
            'hardware.usbDevice': 'Device',
            'hardware.usbVidPid': 'VID:PID',
            'hardware.usbName': 'Name',
            'hardware.usbEmpty': 'No USB device data found.',
            'addons.eyebrow': 'addons',
            'addons.save': 'Save addons',
            'addons.filter': 'Filter',
            'addons.searchPlaceholder': 'Search addons by name or description',
            'modules.eyebrow': 'Kernel',
            'modules.save': 'Save Modules',
            'modules.filter': 'Filter',
            'modules.searchPlaceholder': 'Search module name or description',
            'config.eyebrow': 'Editor',
            'config.title': 'user-config.yml',
            'config.preparing': 'Preparing editor...',
            'config.save': 'Save To Bootloader',
            'config.loadingFile': 'Loading {file} ...',
            'update.stateEyebrow': 'Status',
            'update.overviewTitle': 'Update Overview',
            'update.releaseEyebrow': 'Release',
            'update.upgradeTitle': 'Upgrade RR',
            'update.checkRelease': 'Check Release',
            'update.noReleaseData': 'No release data loaded.',
            'update.upgradeOnline': 'Upgrade Online',
            'update.localPath': 'Local ZIP Path',
            'update.localPathPlaceholder': '/volume1/public/updateall-xx.zip',
            'update.upgradeLocal': 'Upgrade Local',
            'update.logEyebrow': 'Job Log',
            'update.logTitle': 'Update Log',
            'update.refreshLog': 'Refresh Log',
            'update.noLog': 'No log output yet.',
            'update.currentVersion': 'Current RR version',
            'update.updateState': 'Update state',
            'update.backgroundJob': 'Background job',
            'update.currentVersionStat': 'Current RR Version',
            'update.updateStateStat': 'Update State',
            'update.lockStat': 'RR Manager Lock',
            'update.jobMessage': 'Job Message',
            'update.currentVersionRelease': 'Current Version',
            'update.latestVersionRelease': 'Latest Version',
            'update.publishedAt': 'Published At',
            'update.asset': 'Asset',
            'update.github': 'GitHub',
            'update.noAsset': 'no update asset found',
            'update.loadingBoot': 'Loading boot information...',
            'update.loadingRelease': 'Loading release information...',
            'update.loadingLog': 'Loading job log...',
            'update.loadingState': 'Loading update state...',
            'update.unavailableTitle': 'Upgrade in progress',
            'update.unavailableBody': 'This page is unavailable while RR is upgrading.',
            'update.unavailableHint': 'Open the Update page to view progress and logs.',
            'update.onlineStarted': 'Online update started.',
            'update.localStarted': 'Local update started.',
            'update.enterLocalPath': 'Enter a local update zip path first.',
            'table.name': 'Name',
            'table.description': 'Description',
            'table.system': 'System',
            'table.enable': 'Enable',
            'error.badJsonPrefix': 'API did not return JSON. First bytes: {text}',
            'error.requestFailed': 'Request failed.'
        },
        'zh-CN': {
            'title.shell': 'RR Manager',
            'title.overview': '概览 - RR Manager',
            'title.hardware': '硬件 - RR Manager',
            'title.config': '配置 - RR Manager',
            'title.addons': '插件 - RR Manager',
            'title.modules': '驱动 - RR Manager',
            'title.update': '更新 - RR Manager',
            'common.appName': 'RR Manager',
            'common.loading': '加载中...',
            'common.refresh': '刷新',
            'common.reload': '重新载入',
            'common.save': '保存',
            'common.saved': '保存成功。',
            'common.rebootPending': '待重启',
            'common.rebootRequiredHint': '可在方便时重启 DSM。',
            'common.unknown': '未知',
            'common.idle': '空闲',
            'common.running': '运行中',
            'common.busy': '忙碌',
            'common.ready': '就绪。',
            'common.present': '存在',
            'common.yes': '是',
            'common.no': '否',
            'common.state': '状态',
            'common.hardware': '硬件',
            'common.boot': '引导',
            'common.loader': '加载器',
            'common.pleaseWait': '请稍候',
            'common.noItems': '没有可显示的项目。',
            'common.noLog': '暂无日志输出。',
            'common.readFailed': '读取失败。',
            'nav.overview': '概览',
            'nav.hardware': '硬件',
            'nav.config': '配置',
            'nav.addons': '插件',
            'nav.modules': '驱动',
            'nav.update': '更新',
            'shell.eyebrow': 'DSM 引导管理',
            'shell.lead': '在 DSM 中管理 RR 引导器。',
            'shell.logoAria': 'RR 标志',
            'shell.logoAlt': 'RR 标志',
            'shell.contentTitle': 'RR Manager 内容',
            'shell.languageAria': '语言',
            'overview.deviceEyebrow': '硬件',
            'overview.deviceTitle': '设备信息',
            'overview.bootEyebrow': '引导器',
            'overview.bootTitle': '引导信息',
            'overview.dmi': 'DMI',
            'overview.deviceType': '类型',
            'overview.cpu': 'CPU',
            'overview.memory': '内存',
            'overview.dmiVendor': 'DMI 厂商',
            'overview.product': '设备型号',
            'overview.productVersion': '设备版本',
            'overview.bios': 'BIOS',
            'overview.cpuCores': 'CPU 核心数',
            'overview.currentVersion': '当前 RR 版本',
            'overview.diskType': '磁盘类型',
            'overview.bootModel': '机型',
            'overview.bootVersion': '版本',
            'overview.bootKernel': '内核',
            'overview.bootLkm': 'LKM',
            'overview.bootMev': 'MEV',
            'overview.bootAuth': '鉴权信息',
            'hardware.pciEyebrow': 'PCI 硬件',
            'hardware.pciTitle': 'PCI 设备',
            'hardware.pciPath': 'PCI 路径',
            'hardware.pciType': '类型',
            'hardware.pciDevice': '设备',
            'hardware.pciVidPid': 'VID:PID',
            'hardware.pciDriver': '驱动',
            'hardware.pciEmpty': '未获取到 PCI 设备信息。',
            'hardware.usbEyebrow': 'USB 硬件',
            'hardware.usbTitle': 'USB 设备',
            'hardware.usbBus': '总线',
            'hardware.usbDevice': '设备',
            'hardware.usbVidPid': 'VID:PID',
            'hardware.usbName': '名称',
            'hardware.usbEmpty': '未获取到 USB 设备信息。',
            'addons.eyebrow': '插件',
            'addons.save': '保存插件',
            'addons.filter': '筛选',
            'addons.searchPlaceholder': '搜索插件名称或描述',
            'modules.eyebrow': '内核',
            'modules.save': '保存驱动',
            'modules.filter': '筛选',
            'modules.searchPlaceholder': '搜索驱动名称或描述',
            'config.eyebrow': '编辑器',
            'config.title': 'user-config.yml',
            'config.preparing': '正在准备编辑器...',
            'config.save': '保存到引导器',
            'config.loadingFile': '正在加载 {file} ...',
            'update.stateEyebrow': '状态',
            'update.overviewTitle': '更新概览',
            'update.releaseEyebrow': '发行版本',
            'update.upgradeTitle': '升级 RR',
            'update.checkRelease': '检查版本',
            'update.noReleaseData': '尚未加载版本信息。',
            'update.upgradeOnline': '在线升级',
            'update.localPath': '本地 ZIP 路径',
            'update.localPathPlaceholder': '/volume1/public/updateall-xx.zip',
            'update.upgradeLocal': '本地升级',
            'update.logEyebrow': '任务日志',
            'update.logTitle': '更新日志',
            'update.refreshLog': '刷新日志',
            'update.noLog': '暂无日志输出。',
            'update.currentVersion': '当前 RR 版本',
            'update.updateState': '更新状态',
            'update.backgroundJob': '后台任务',
            'update.currentVersionStat': '当前 RR 版本',
            'update.updateStateStat': '更新状态',
            'update.lockStat': 'RR Manager 锁',
            'update.jobMessage': '任务消息',
            'update.currentVersionRelease': '当前版本',
            'update.latestVersionRelease': '最新版本',
            'update.publishedAt': '发布时间',
            'update.asset': '资源文件',
            'update.github': 'GitHub',
            'update.noAsset': '未找到更新资源',
            'update.loadingBoot': '正在加载引导信息...',
            'update.loadingRelease': '正在加载版本信息...',
            'update.loadingLog': '正在加载任务日志...',
            'update.loadingState': '正在加载更新状态...',
            'update.unavailableTitle': '升级进行中',
            'update.unavailableBody': '升级期间，当前页面暂不可用。',
            'update.unavailableHint': '请切换到更新页查看进度和日志。',
            'update.onlineStarted': '已启动在线升级。',
            'update.localStarted': '已启动本地升级。',
            'update.enterLocalPath': '请先输入本地更新 ZIP 路径。',
            'table.name': '名称',
            'table.description': '描述',
            'table.system': '系统',
            'table.enable': '启用',
            'error.badJsonPrefix': 'API 未返回 JSON，前几个字符: {text}',
            'error.requestFailed': '请求失败。'
        }
    };
    var state = {
        release: null,
        updateRunning: false,
        upgradeBlocked: false,
        currentFile: 'user-config',
        configLoaded: false,
        items: [],
        retryTimers: {},
        locale: 'en',
        baseMessages: null,
        messages: null,
        loading: {
            pending: 0,
            visible: false,
            timer: null,
            holdTimer: null,
            freezeUntil: 0,
            failSafeTimer: null
        }
    };
    var LOCALE_DIRS = {
        'en-US': 'enu',
        'ar-SA': 'ara',
        'de-DE': 'ger',
        'es-ES': 'spn',
        'fr-FR': 'fre',
        'ja-JP': 'jpn',
        'ko-KR': 'krn',
        'ru-RU': 'rus',
        'th-TH': 'tha',
        'tr-TR': 'trk',
        'uk-UA': 'ukr',
        'vi-VN': 'vit',
        'zh-CN': 'chs',
        'zh-HK': 'cht',
        'zh-TW': 'cht'
    };
    I18N['en-US'] = I18N.en;
    I18N['ar-SA'] = I18N.en;
    I18N['de-DE'] = I18N.en;
    I18N['es-ES'] = I18N.en;
    I18N['fr-FR'] = I18N.en;
    I18N['ja-JP'] = I18N.en;
    I18N['ko-KR'] = I18N.en;
    I18N['ru-RU'] = I18N.en;
    I18N['th-TH'] = I18N.en;
    I18N['tr-TR'] = I18N.en;
    I18N['uk-UA'] = I18N.en;
    I18N['vi-VN'] = I18N.en;
    I18N['zh-TW'] = I18N['zh-CN'];
    I18N['zh-HK'] = I18N['zh-CN'];

    function $(id) {
        return document.getElementById(id);
    }

    function normalizeLocale(locale) {
        locale = (locale || '').replace(/_/g, '-');
        if (/^enu$/i.test(locale)) {
            return 'en-US';
        }
        if (/^ara$/i.test(locale)) {
            return 'ar-SA';
        }
        if (/^ger$/i.test(locale)) {
            return 'de-DE';
        }
        if (/^spn$/i.test(locale)) {
            return 'es-ES';
        }
        if (/^fre$/i.test(locale)) {
            return 'fr-FR';
        }
        if (/^jpn$/i.test(locale)) {
            return 'ja-JP';
        }
        if (/^krn$/i.test(locale)) {
            return 'ko-KR';
        }
        if (/^rus$/i.test(locale)) {
            return 'ru-RU';
        }
        if (/^tha$/i.test(locale)) {
            return 'th-TH';
        }
        if (/^trk$/i.test(locale)) {
            return 'tr-TR';
        }
        if (/^ukr$/i.test(locale)) {
            return 'uk-UA';
        }
        if (/^vit$/i.test(locale)) {
            return 'vi-VN';
        }
        if (/^chs$/i.test(locale)) {
            return 'zh-CN';
        }
        if (/^cht$/i.test(locale)) {
            return 'zh-TW';
        }
        if (/^zh-(tw|hk|mo)\b/i.test(locale)) {
            return /^zh-hk\b/i.test(locale) ? 'zh-HK' : 'zh-TW';
        }
        if (/^zh\b/i.test(locale)) {
            return 'zh-CN';
        }
        if (/^ar-sa\b/i.test(locale)) {
            return 'ar-SA';
        }
        if (/^de-de\b/i.test(locale)) {
            return 'de-DE';
        }
        if (/^es-es\b/i.test(locale)) {
            return 'es-ES';
        }
        if (/^fr-fr\b/i.test(locale)) {
            return 'fr-FR';
        }
        if (/^ja-jp\b/i.test(locale)) {
            return 'ja-JP';
        }
        if (/^ko-kr\b/i.test(locale)) {
            return 'ko-KR';
        }
        if (/^ru-ru\b/i.test(locale)) {
            return 'ru-RU';
        }
        if (/^th-th\b/i.test(locale)) {
            return 'th-TH';
        }
        if (/^tr-tr\b/i.test(locale)) {
            return 'tr-TR';
        }
        if (/^uk-ua\b/i.test(locale)) {
            return 'uk-UA';
        }
        if (/^vi-vn\b/i.test(locale)) {
            return 'vi-VN';
        }
        return 'en-US';
    }

    function localeResourceDir(locale) {
        return LOCALE_DIRS[locale] || 'enu';
    }

    function mergeMessages(base, extra) {
        var merged = {};
        var key;

        for (key in base) {
            if (Object.prototype.hasOwnProperty.call(base, key)) {
                merged[key] = base[key];
            }
        }
        for (key in extra) {
            if (Object.prototype.hasOwnProperty.call(extra, key)) {
                merged[key] = extra[key];
            }
        }
        return merged;
    }

    function fetchMessages(dir) {
        return fetch('/webman/3rdparty/rr-manager/texts/' + dir + '/ui.json', {
            credentials: 'same-origin',
            cache: 'no-store'
        }).then(function (response) {
            if (!response.ok) {
                throw new Error('Failed to load locale bundle.');
            }
            return response.json();
        });
    }

    function loadLocaleMessages(locale) {
        var dir = localeResourceDir(locale);
        return fetchMessages('enu').then(function (base) {
            state.baseMessages = base || {};
            if (dir === 'enu') {
                state.messages = state.baseMessages;
                return state.messages;
            }
            return fetchMessages(dir).then(function (extra) {
                state.messages = mergeMessages(state.baseMessages, extra || {});
                return state.messages;
            }, function () {
                state.messages = state.baseMessages;
                return state.messages;
            });
        }, function () {
            state.baseMessages = null;
            state.messages = null;
            return null;
        });
    }

    function currentDictionary() {
        if (state.messages) {
            return state.messages;
        }
        if (state.baseMessages) {
            return state.baseMessages;
        }
        return I18N[state.locale] || I18N['en-US'] || I18N.en;
    }

    function t(key, vars) {
        var value = currentDictionary()[key];
        var name;

        if (value == null) {
            value = I18N['en-US'][key] || I18N.en[key];
        }
        if (value == null) {
            value = key;
        }

        if (!vars) {
            return value;
        }

        for (name in vars) {
            if (Object.prototype.hasOwnProperty.call(vars, name)) {
                value = value.replace(new RegExp('\\{' + name + '\\}', 'g'), vars[name]);
            }
        }

        return value;
    }

    function escapeHtml(value) {
        return String(value == null ? '' : value)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    function displayValue(value, fallbackKey) {
        var normalized;

        if (value == null || value === '') {
            return t(fallbackKey || 'common.unknown');
        }

        if (typeof value !== 'string') {
            return String(value);
        }

        normalized = value.toLowerCase();
        if (normalized === 'unknown') {
            return t('common.unknown');
        }
        if (normalized === 'idle') {
            return t('common.idle');
        }
        if (normalized === 'running') {
            return t('common.running');
        }
        if (normalized === 'busy') {
            return t('common.busy');
        }
        if (normalized === 'ready' || normalized === 'ready.') {
            return t('common.ready');
        }
        if (normalized === 'present') {
            return t('common.present');
        }
        if (normalized === 'pending-reboot' || normalized === 'reboot-required') {
            return t('common.rebootPending');
        }
        return value;
    }

    function withRebootHint(message) {
        var hint = t('common.rebootRequiredHint');

        if (!message) {
            return hint;
        }
        if (message.indexOf(hint) !== -1) {
            return message;
        }
        return message + ' ' + hint;
    }

    function isRebootPendingState(value) {
        var normalized;

        if (typeof value !== 'string') {
            return false;
        }

        normalized = value.toLowerCase();
        return normalized === 'pending-reboot' || normalized === 'reboot-required';
    }

    function rebootBannerMessage(data) {
        return withRebootHint((data && data.updateMessage) || '');
    }

    function ensureRebootBanner() {
        var banner = $('rebootBanner');
        var container;
        var main;

        if (page === 'shell') {
            return null;
        }

        if (banner) {
            return banner;
        }

        main = document.querySelector('main');
        container = document.body;
        if (!container || !main) {
            return null;
        }

        banner = document.createElement('section');
        banner.id = 'rebootBanner';
        banner.className = 'rebootBanner';
        banner.hidden = true;
        banner.innerHTML =
            '<div class="rebootBannerBody">' +
            '<span class="rebootBannerBadge">' + escapeHtml(t('common.rebootPending')) + '</span>' +
            '<div class="rebootBannerCopy">' +
            '<strong id="rebootBannerTitle">' + escapeHtml(t('common.rebootPending')) + '</strong>' +
            '<p id="rebootBannerText">' + escapeHtml(t('common.rebootRequiredHint')) + '</p>' +
            '</div>' +
            '</div>';
        container.insertBefore(banner, main);
        return banner;
    }

    function syncRebootBanner(data) {
        var banner = ensureRebootBanner();
        var visible = !!(data && isRebootPendingState(data.updateState));
        var title = $('rebootBannerTitle');
        var text = $('rebootBannerText');

        if (!banner) {
            return;
        }

        if (!visible) {
            banner.hidden = true;
            return;
        }

        if (title) {
            title.textContent = t('common.rebootPending');
        }
        if (text) {
            text.textContent = rebootBannerMessage(data);
        }

        banner.hidden = false;
    }

    function renderStats(items) {
        return items.map(function (item) {
            return '<div class="stat"><span class="statLabel">' + escapeHtml(item[0]) +
                '</span><span class="statValue">' + escapeHtml(displayValue(item[1])) +
                '</span></div>';
        }).join('');
    }

    function renderStatusLines(items) {
        return items.map(function (item) {
            return '<div class="statusLine"><span class="statusLabel">' + escapeHtml(item[0]) +
                '</span><span class="statusValue">' + escapeHtml(displayValue(item[1])) + '</span></div>';
        }).join('');
    }

    function formatBootAuth(boot) {
        var values = [];

        if (boot.sn && boot.sn !== 'unknown') {
            values.push('SN: ' + boot.sn);
        }
        if (boot.mac1 && boot.mac1 !== 'unknown') {
            values.push('MAC1: ' + boot.mac1);
        }
        if (boot.mac2 && boot.mac2 !== 'unknown') {
            values.push('MAC2: ' + boot.mac2);
        }

        return values.length ? values.join(' | ') : t('common.unknown');
    }

    function formatCpuCt(hardware) {
        var cores = hardware.cpuCores || t('common.unknown');
        var threads = hardware.cpuThreads || t('common.unknown');

        return String(cores) + ' / ' + String(threads);
    }

    function formatBootKernel(boot, hardware) {
        var bootKernel = boot.kernel || '';
        var systemKernel = hardware.kernel || '';

        if (!bootKernel && !systemKernel) {
            return t('common.unknown');
        }
        if (!bootKernel) {
            return systemKernel;
        }
        if (!systemKernel) {
            return bootKernel;
        }
        if (bootKernel === systemKernel) {
            return bootKernel;
        }

        return bootKernel + ' + ' + systemKernel;
    }

    function renderPciTable(items, emptyText) {
        if (!items || !items.length) {
            return '<tr><td colspan="5" class="emptyCell">' + escapeHtml(emptyText || t('hardware.pciEmpty')) + '</td></tr>';
        }

        return items.map(function (item) {
            return '<tr>' +
                '<td>' + escapeHtml(displayValue(item.path || t('common.unknown'))) + '</td>' +
                '<td>' + escapeHtml(displayValue(item.type || t('common.unknown'))) + '</td>' +
                '<td>' + escapeHtml(displayValue(item.device || t('common.unknown'))) + '</td>' +
                '<td>' + escapeHtml(displayValue(item.vidpid || t('common.unknown'))) + '</td>' +
                '<td>' + escapeHtml(displayValue(item.driver || '-')) + '</td>' +
                '</tr>';
        }).join('');
    }

    function updatePciTable(items, emptyText) {
        var tableBody = $('pciTableBody');

        if (!tableBody) {
            return;
        }

        tableBody.innerHTML = renderPciTable(items, emptyText);
    }

    function renderUsbTable(items, emptyText) {
        if (!items || !items.length) {
            return '<tr><td colspan="4" class="emptyCell">' + escapeHtml(emptyText || t('hardware.usbEmpty')) + '</td></tr>';
        }

        return items.map(function (item) {
            return '<tr>' +
                '<td>' + escapeHtml(displayValue(item.bus || t('common.unknown'))) + '</td>' +
                '<td>' + escapeHtml(displayValue(item.device || t('common.unknown'))) + '</td>' +
                '<td>' + escapeHtml(displayValue(item.vidpid || t('common.unknown'))) + '</td>' +
                '<td>' + escapeHtml(displayValue(item.name || t('common.unknown'))) + '</td>' +
                '</tr>';
        }).join('');
    }

    function updateUsbTable(items, emptyText) {
        var tableBody = $('usbTableBody');

        if (!tableBody) {
            return;
        }

        tableBody.innerHTML = renderUsbTable(items, emptyText);
    }

    function getQueryLocale() {
        var match = window.location.search.match(/[?&]lang=([^&#]+)/);
        return match ? decodeURIComponent(match[1]) : '';
    }

    function detectLocale() {
        var locale = getQueryLocale();

        if (!locale) {
            try {
                locale = window.localStorage.getItem('rrm.locale') || '';
            } catch (error) {
                locale = '';
            }
        }

        if (!locale) {
            locale = navigator.language || navigator.userLanguage || 'en';
        }

        return normalizeLocale(locale);
    }

    function updateLocaleControl() {
        var select = $('localeSelect');
        if (select) {
            select.value = state.locale;
        }
    }

    function applyI18n(root) {
        root = root || document;
        document.documentElement.lang = state.locale;

        Array.prototype.forEach.call(root.querySelectorAll('[data-i18n]'), function (node) {
            node.textContent = t(node.getAttribute('data-i18n'));
        });

        Array.prototype.forEach.call(root.querySelectorAll('[data-i18n-placeholder]'), function (node) {
            node.setAttribute('placeholder', t(node.getAttribute('data-i18n-placeholder')));
        });

        Array.prototype.forEach.call(root.querySelectorAll('[data-i18n-title]'), function (node) {
            node.setAttribute('title', t(node.getAttribute('data-i18n-title')));
        });

        Array.prototype.forEach.call(root.querySelectorAll('[data-i18n-aria-label]'), function (node) {
            node.setAttribute('aria-label', t(node.getAttribute('data-i18n-aria-label')));
        });

        Array.prototype.forEach.call(root.querySelectorAll('[data-i18n-alt]'), function (node) {
            node.setAttribute('alt', t(node.getAttribute('data-i18n-alt')));
        });

        document.title = t('title.' + page);
        updateLocaleControl();
    }

    function setLocale(locale, options) {
        var frame;

        options = options || {};
        state.locale = normalizeLocale(locale);
        try {
            window.localStorage.setItem('rrm.locale', state.locale);
        } catch (error) {
            /* ignore localStorage errors */
        }

        return loadLocaleMessages(state.locale).then(function () {
            applyI18n(document);

            if (page === 'shell' && options.reloadFrame) {
                frame = $('contentFrame');
                if (frame) {
                    frame.src = frame.getAttribute('src');
                }
            }
        }, function () {
            applyI18n(document);
        });
    }

    function setToast(message, kind) {
        var toast = $('toast');
        if (!toast) {
            return;
        }
        toast.hidden = false;
        toast.className = 'toast ' + (kind || '');
        toast.textContent = message;
        clearTimeout(setToast.timer);
        setToast.timer = setTimeout(function () {
            toast.hidden = true;
        }, 3200);
    }

    function encode(data) {
        return new URLSearchParams(data).toString();
    }

    function ensureLoadingMask() {
        var mask = $('loadingMask');
        if (mask) {
            return mask;
        }

        mask = document.createElement('div');
        mask.id = 'loadingMask';
        mask.className = 'loadingMask';
        mask.hidden = true;
        mask.innerHTML =
            '<div class="loadingCard">' +
            '<div class="loadingSpinner" aria-hidden="true"></div>' +
            '<div class="loadingText" id="loadingText">' + escapeHtml(t('common.loading')) + '</div>' +
            '</div>';
        document.body.appendChild(mask);
        return mask;
    }

    function setLoadingVisible(visible, message) {
        var mask = ensureLoadingMask();
        var text = $('loadingText');

        if (text) {
            text.textContent = message || t('common.loading');
        }

        mask.hidden = !visible;
        mask.style.display = visible ? 'flex' : 'none';
        document.body.classList.toggle('isLoading', visible);
        state.loading.visible = visible;
    }

    function clearLoadingNow() {
        state.loading.pending = 0;
        state.loading.freezeUntil = 0;
        clearTimeout(state.loading.timer);
        clearTimeout(state.loading.holdTimer);
        clearTimeout(state.loading.failSafeTimer);
        setLoadingVisible(false, t('common.loading'));
    }

    function scheduleLoadingHide() {
        clearTimeout(state.loading.holdTimer);

        if (state.loading.pending > 0) {
            return;
        }

        if (state.loading.freezeUntil > Date.now()) {
            state.loading.holdTimer = setTimeout(function () {
                scheduleLoadingHide();
            }, state.loading.freezeUntil - Date.now());
            return;
        }

        state.loading.freezeUntil = 0;
        setLoadingVisible(false, t('common.loading'));
    }

    function beginLoading(message) {
        state.loading.pending += 1;
        clearTimeout(state.loading.timer);
        clearTimeout(state.loading.holdTimer);
        clearTimeout(state.loading.failSafeTimer);

        state.loading.failSafeTimer = setTimeout(function () {
            clearLoadingNow();
        }, 5000);

        if (state.loading.visible) {
            setLoadingVisible(true, message || t('common.loading'));
            return;
        }

        state.loading.timer = setTimeout(function () {
            if (state.loading.pending > 0) {
                setLoadingVisible(true, message || t('common.loading'));
            }
        }, 160);
    }

    function endLoading() {
        if (state.loading.pending > 0) {
            state.loading.pending -= 1;
        }

        clearTimeout(state.loading.timer);
        if (state.loading.pending === 0) {
            clearTimeout(state.loading.failSafeTimer);
        }
        scheduleLoadingHide();
    }

    function freezeLoading(message, duration) {
        state.loading.freezeUntil = Date.now() + (duration || 1200);
        clearTimeout(state.loading.timer);
        clearTimeout(state.loading.failSafeTimer);
        state.loading.failSafeTimer = setTimeout(function () {
            clearLoadingNow();
        }, (duration || 1200) + 2000);
        setLoadingVisible(true, message || t('common.loading'));
        scheduleLoadingHide();
    }

    function pageUsesUpgradeBlock() {
        return page !== 'shell' && page !== 'update';
    }

    function ensureUpgradeBlockMask() {
        var mask = $('upgradeBlockMask');

        if (mask) {
            return mask;
        }

        mask = document.createElement('div');
        mask.id = 'upgradeBlockMask';
        mask.className = 'upgradeBlockMask';
        mask.hidden = true;
        mask.innerHTML =
            '<div class="upgradeBlockCard">' +
            '<p class="sectionEyebrow" id="upgradeBlockEyebrow"></p>' +
            '<h2 id="upgradeBlockTitle"></h2>' +
            '<p class="upgradeBlockBody" id="upgradeBlockBody"></p>' +
            '<div class="heroStatus inlineHeroStatus" id="upgradeBlockStatus"></div>' +
            '</div>';
        document.body.appendChild(mask);
        return mask;
    }

    function setUpgradeBlocked(visible, data) {
        var mask;
        var message;
        var statusItems;

        if (!pageUsesUpgradeBlock()) {
            return false;
        }

        mask = ensureUpgradeBlockMask();
        state.upgradeBlocked = !!visible;
        document.body.classList.toggle('isUpgradeBlocked', !!visible);

        if (!visible) {
            mask.hidden = true;
            mask.style.display = 'none';
            return false;
        }

        clearLoadingNow();
        message = (data && data.updateMessage) || t('update.unavailableHint');
        statusItems = [
            [t('update.updateStateStat'), (data && data.updateState) || t('common.running')],
            [t('update.jobMessage'), message]
        ];

        $('upgradeBlockEyebrow').textContent = t('update.stateEyebrow');
        $('upgradeBlockTitle').textContent = t('update.unavailableTitle');
        $('upgradeBlockBody').textContent = t('update.unavailableBody');
        $('upgradeBlockStatus').innerHTML = renderStatusLines(statusItems);
        mask.hidden = false;
        mask.style.display = 'flex';
        return true;
    }

    function syncUpgradeBlocked(data) {
        state.updateRunning = !!(data && data.updateRunning);

        if (!pageUsesUpgradeBlock()) {
            return false;
        }

        if (state.updateRunning) {
            return setUpgradeBlocked(true, data);
        }

        if (state.upgradeBlocked) {
            setUpgradeBlocked(false);
        }
        return false;
    }

    function request(action, options) {
        options = options || {};
        var method = options.method || 'GET';
        var url = '/webman/3rdparty/rr-manager/scripts/api.cgi?action=' + encodeURIComponent(action);
        var fetchOptions = {
            method: method,
            credentials: 'same-origin',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
            }
        };

        if (method === 'POST') {
            fetchOptions.body = encode(options.data || {}) + '&lang=' + encodeURIComponent(state.locale);
        } else if (options.data) {
            url += '&' + encode(options.data) + '&lang=' + encodeURIComponent(state.locale);
        } else {
            url += '&lang=' + encodeURIComponent(state.locale);
        }

        if (!options.silent) {
            beginLoading(options.loadingMessage || t('common.loading'));
        }

        return fetch(url, fetchOptions)
            .then(function (response) {
                return response.text().then(function (text) {
                    var json;
                    try {
                        json = JSON.parse(text);
                    } catch (parseError) {
                        var parseWrappedError = new Error(t('error.badJsonPrefix', {
                            text: text.slice(0, 120)
                        }));
                        parseWrappedError.status = response.status;
                        throw parseWrappedError;
                    }
                    if (!response.ok || !json.ok) {
                        var wrappedError = new Error((json && json.error) || t('error.requestFailed'));
                        wrappedError.status = response.status;
                        wrappedError.busy = response.status === 409 || /busy/i.test(wrappedError.message);
                        throw wrappedError;
                    }
                    return json;
                });
            })
            .then(function (result) {
                if (!options.silent) {
                    endLoading();
                }
                return result;
            }, function (error) {
                if (!options.silent) {
                    endLoading();
                }
                throw error;
            });
    }

    function isBusyError(error) {
        return !!(error && (error.busy || error.status === 409 || /busy/i.test(error.message || '')));
    }

    function isRetryBusyResult(data) {
        return !!(data && data.busy && data.retry);
    }

    function renderLoadingStats(items) {
        return items.map(function (item) {
            return '<div class="stat"><span class="statLabel">' + escapeHtml(item[0]) +
                '</span><span class="statValue">' + escapeHtml(item[1]) + '</span></div>';
        }).join('');
    }

    function scheduleBusyRetry(key, action) {
        clearTimeout(state.retryTimers[key]);
        state.retryTimers[key] = setTimeout(function () {
            delete state.retryTimers[key];
            action();
        }, 1600);
    }

    function clearBusyRetry(key) {
        clearTimeout(state.retryTimers[key]);
        delete state.retryTimers[key];
    }

    function setBusyLoading(message) {
        var loadingMessage = message || t('common.loading');
        var heroStatus = $('heroStatus');
        var overviewStats = $('overviewStats');
        var bootStats = $('bootStats');
        var authStats = $('authStats');
        if (heroStatus) {
            heroStatus.textContent = loadingMessage;
        }

        if (overviewStats) {
            overviewStats.innerHTML = renderLoadingStats([
                [t('common.state'), t('common.loading')],
                [t('common.hardware'), t('common.pleaseWait')]
            ]);
        }

        if (bootStats) {
            bootStats.innerHTML = renderLoadingStats([
                [t('common.boot'), t('common.loading')],
                [t('common.loader'), t('common.pleaseWait')]
            ]);
        }

        if (authStats) {
            authStats.innerHTML = renderLoadingStats([
                [t('overview.sn'), t('common.loading')],
                [t('overview.mac1'), t('common.loading')],
                [t('overview.mac2'), t('common.loading')]
            ]);
        }

        updatePciTable(null, loadingMessage);
        updateUsbTable(null, loadingMessage);

        freezeLoading(loadingMessage, 1500);
    }

    function initShell() {
        var frame = $('contentFrame');
        var buttons = document.querySelectorAll('#subnav button[data-page-target]');
        var localeSelect = $('localeSelect');

        Array.prototype.forEach.call(buttons, function (button) {
            button.addEventListener('click', function () {
                Array.prototype.forEach.call(buttons, function (item) {
                    item.classList.remove('active');
                });
                button.classList.add('active');
                frame.src = '/webman/3rdparty/rr-manager/' + button.getAttribute('data-page-target') + '.html';
            });
        });

        if (localeSelect) {
            localeSelect.addEventListener('change', function () {
                setLocale(localeSelect.value, { reloadFrame: true });
            });
        }
    }

    function renderOverview(data) {
        var hardware;
        var boot;
        var dmiSummary;
        var updateSummary;

        clearLoadingNow();
        state.updateRunning = !!data.updateRunning;
        syncRebootBanner(data);

        if (page === 'update') {
            updateSummary = data.updateMessage || t('common.ready');
            $('overviewStats').innerHTML = renderStats([
                [t('update.jobMessage'), updateSummary],
                [t('update.backgroundJob'), data.updateRunning ? t('common.running') : t('common.idle')],
                [t('update.updateStateStat'), data.updateState || t('common.idle')]
            ]);

            if (data.updateRunning) {
                clearBusyRetry('release');
            }

            if ($('startLocalUpdate')) {
                $('startLocalUpdate').disabled = data.updateRunning;
            }
            if ($('startOnlineUpdate')) {
                $('startOnlineUpdate').disabled = !state.release || data.updateRunning;
            }
            if ($('checkRelease')) {
                $('checkRelease').disabled = data.updateRunning;
            }
            return;
        }

        if (syncUpgradeBlocked(data)) {
            return;
        }

        hardware = data.hardware || {};
        boot = data.boot || {};
        dmiSummary = [hardware.dmiVendor, hardware.dmiProduct, hardware.dmiVersion].filter(function (value) {
            return value && value !== 'unknown';
        }).join(' / ');

        if ($('overviewStats')) {
            $('overviewStats').innerHTML = renderStats([
                [t('overview.dmi'), dmiSummary || t('common.unknown')],
                [t('overview.bios'), hardware.biosVersion || t('common.unknown')],
                [t('overview.deviceType'), hardware.firmwareMode || t('common.unknown')],
                [t('overview.cpu'), hardware.cpuModel || t('common.unknown')],
                [t('overview.cpuCt'), formatCpuCt(hardware)],
                [t('overview.memory'), hardware.ramTotal || t('common.unknown')]
            ]);
        }

        if ($('bootStats')) {
            $('bootStats').innerHTML = renderStats([
                [t('overview.bootModel'), boot.model || t('common.unknown')],
                [t('overview.bootVersion'), boot.version || t('common.unknown')],
                [t('overview.bootKernel'), formatBootKernel(boot, hardware)],
                [t('overview.bootLkm'), boot.lkm || t('common.unknown')],
                [t('overview.bootMev'), boot.mev || t('common.unknown')],
                [t('overview.diskType'), boot.bootType || t('common.unknown')]
            ]);
        }

        if ($('authStats')) {
            $('authStats').innerHTML = renderStats([
                [t('overview.sn'), boot.sn || t('common.unknown')],
                [t('overview.mac1'), boot.mac1 || t('common.unknown')],
                [t('overview.mac2'), boot.mac2 || t('common.unknown')]
            ]);
        }

        updatePciTable(hardware.pciDevices || [], t('hardware.pciEmpty'));
        updateUsbTable(hardware.usbDevices || [], t('hardware.usbEmpty'));
    }

    function renderRelease(data) {
        clearLoadingNow();
        state.release = data;
        $('releaseBox').innerHTML =
            '<div class="stat"><span class="statLabel">' + escapeHtml(t('update.currentVersionRelease')) + '</span><span class="statValue">' + escapeHtml(displayValue(data.currentVersion)) + '</span></div>' +
            '<div class="stat"><span class="statLabel">' + escapeHtml(t('update.latestVersionRelease')) + '</span><span class="statValue">' + escapeHtml(displayValue(data.latestVersion)) + '</span></div>' +
            '<div class="stat"><span class="statLabel">' + escapeHtml(t('update.publishedAt')) + '</span><span class="statValue">' + escapeHtml(displayValue(data.publishedAt)) + '</span></div>' +
            '<div class="stat"><span class="statLabel">' + escapeHtml(t('update.asset')) + '</span><span class="statValue">' + escapeHtml(data.assetName || t('update.noAsset')) + '</span></div>' +
            '<div class="stat hint"><span class="statLabel">' + escapeHtml(t('update.github')) + '</span><span class="statValue"><a href="' + escapeHtml(data.htmlUrl || '#') + '" target="_blank" rel="noreferrer">' + escapeHtml(data.htmlUrl || '') + '</a></span></div>';
        if ($('startOnlineUpdate')) {
            $('startOnlineUpdate').disabled = !data.assetUrl || state.updateRunning;
        }
    }

    function loadOverview(options) {
        return request('overview', options).then(renderOverview).catch(function (error) {
            if (isBusyError(error)) {
                setBusyLoading(t(page === 'update' ? 'update.loadingState' : 'update.loadingBoot'));
                scheduleBusyRetry('overview', function () {
                    loadOverview({ silent: true });
                });
                return;
            }
            setToast(error.message, 'error');
        });
    }

    function loadRelease(options) {
        if (state.updateRunning) {
            clearBusyRetry('release');
            return Promise.resolve();
        }

        return request('release', options).then(function (data) {
            if (isRetryBusyResult(data)) {
                if (state.updateRunning) {
                    clearBusyRetry('release');
                    return;
                }
                setBusyLoading(t('update.loadingRelease'));
                scheduleBusyRetry('release', function () {
                    loadRelease({ silent: true });
                });
                return;
            }
            renderRelease(data);
        }).catch(function (error) {
            if (isBusyError(error)) {
                if (state.updateRunning) {
                    clearBusyRetry('release');
                    return;
                }
                setBusyLoading(t('update.loadingRelease'));
                scheduleBusyRetry('release', function () {
                    loadRelease({ silent: true });
                });
                return;
            }
            setToast(error.message, 'error');
        });
    }

    function refreshLog(options) {
        request('log', options).then(function (data) {
            clearLoadingNow();
            $('logView').textContent = data.log || t('update.noLog');
        }).catch(function (error) {
            if (isBusyError(error)) {
                setBusyLoading(t('update.loadingLog'));
                scheduleBusyRetry('log', function () {
                    refreshLog({ silent: true });
                });
                return;
            }
            setToast(error.message, 'error');
        });
    }

    function startOnlineUpdate() {
        request('start-update-online', { method: 'POST' }).then(function (data) {
            setToast(data.message || t('update.onlineStarted'), 'success');
            loadOverview();
            refreshLog();
        }).catch(function (error) {
            if (isBusyError(error)) {
                setBusyLoading(t('update.loadingState'));
                return;
            }
            setToast(error.message, 'error');
        });
    }

    function startLocalUpdate() {
        var path = $('localArchivePath').value.trim();
        if (!path) {
            setToast(t('update.enterLocalPath'), 'error');
            return;
        }
        request('start-update-local', {
            method: 'POST',
            data: { path: path }
        }).then(function (data) {
            setToast(data.message || t('update.localStarted'), 'success');
            loadOverview();
            refreshLog();
        }).catch(function (error) {
            if (isBusyError(error)) {
                setBusyLoading(t('update.loadingState'));
                return;
            }
            setToast(error.message, 'error');
        });
    }

    function initOverview() {
        $('refreshOverview').addEventListener('click', function () {
            loadOverview();
        });
        loadOverview();
        (function pollOverview() {
            loadOverview({ silent: true });
            setTimeout(pollOverview, state.updateRunning ? 4000 : 12000);
        })();
    }

    function initUpdate() {
        $('refreshOverview').addEventListener('click', function () {
            loadOverview();
        });
        $('checkRelease').addEventListener('click', function () {
            loadRelease();
        });
        $('refreshLog').addEventListener('click', function () {
            refreshLog();
        });
        $('startOnlineUpdate').addEventListener('click', startOnlineUpdate);
        $('startLocalUpdate').addEventListener('click', startLocalUpdate);

        loadOverview();
        loadRelease();
        refreshLog();

        (function pollUpdate() {
            loadOverview({ silent: true });
            refreshLog({ silent: true });
            setTimeout(pollUpdate, state.updateRunning ? 4000 : 12000);
        })();
    }

    function itemPageConfig() {
        if (page === 'addons') {
            return {
                loadAction: 'addons',
                saveAction: 'save-addons'
            };
        }
        return {
            loadAction: 'modules',
            saveAction: 'save-modules'
        };
    }

    function renderItems() {
        var body = $('itemsBody');
        var filter = $('searchInput').value.trim().toLowerCase();
        var rows = state.items.filter(function (item) {
            var haystack = [item.name, item.description, item.system].join(' ').toLowerCase();
            return !filter || haystack.indexOf(filter) !== -1;
        });
        var colSpan = page === 'addons' ? 4 : 3;

        if (!rows.length) {
            body.innerHTML = '<tr><td colspan="' + colSpan + '">' + escapeHtml(t('common.noItems')) + '</td></tr>';
            return;
        }

        body.innerHTML = rows.map(function (item) {
            var isSystem = (item.system || 'false') === 'true';
            var descriptionCell = '<td>' + escapeHtml(item.description || '') + '</td>';
            var systemCell = page === 'addons' ? '<td>' + escapeHtml(isSystem ? t('common.yes') : t('common.no')) + '</td>' : '';
            var enableCell = '<td><input class="rowToggle" data-name="' + escapeHtml(item.name) + '" type="checkbox" ' +
                ((item.installed || isSystem) ? 'checked ' : '') +
                (isSystem ? 'disabled ' : '') +
                '></td>';
            return '<tr>' +
                '<td>' + escapeHtml(item.name) + '</td>' +
                descriptionCell +
                (page === 'addons' ? systemCell : '') +
                enableCell +
                '</tr>';
        }).join('');
    }

    function loadItems(options) {
        var cfg = itemPageConfig();
        request(cfg.loadAction, options).then(function (data) {
            if (isRetryBusyResult(data)) {
                setBusyLoading(t('common.loading'));
                scheduleBusyRetry('items', function () {
                    loadItems({ silent: true });
                });
                return;
            }
            clearLoadingNow();
            state.items = data.items || [];
            renderItems();
        }).catch(function (error) {
            if (isBusyError(error)) {
                setBusyLoading(t('common.loading'));
                scheduleBusyRetry('items', function () {
                    loadItems({ silent: true });
                });
                return;
            }
            setToast(error.message, 'error');
        });
    }

    function saveItems() {
        var cfg = itemPageConfig();
        var selected;

        if (page === 'addons') {
            var toggles = Array.prototype.slice.call(document.querySelectorAll('.rowToggle'));
            selected = state.items.filter(function (item) {
                var checkbox = null;
                var index;
                var isSystem = (item.system || 'false') === 'true';
                if (isSystem) {
                    return true;
                }
                for (index = 0; index < toggles.length; index += 1) {
                    if (toggles[index].getAttribute('data-name') === item.name) {
                        checkbox = toggles[index];
                        break;
                    }
                }
                return checkbox && checkbox.checked;
            }).map(function (item) {
                return item.name;
            });
        } else {
            selected = Array.prototype.slice.call(document.querySelectorAll('.rowToggle:checked')).map(function (node) {
                return node.getAttribute('data-name');
            });
        }

        request(cfg.saveAction, {
            method: 'POST',
            data: { items: selected.join(',') }
        }).then(function (data) {
            setToast(withRebootHint(data.message || t('common.saved')), 'success');
            loadItems();
        }).catch(function (error) {
            if (isBusyError(error)) {
                setBusyLoading(t('common.loading'));
                return;
            }
            setToast(error.message, 'error');
        });
    }

    function editorLineCount(value) {
        if (!value) {
            return 1;
        }

        return value.split('\n').length;
    }

    function syncEditorLineNumberScroll() {
        var editor = $('editor');
        var lineNumbers = $('editorLineNumbers');

        if (!editor || !lineNumbers) {
            return;
        }

        lineNumbers.style.transform = 'translateY(' + (-editor.scrollTop) + 'px)';
    }

    function updateEditorLineNumbers() {
        var editor = $('editor');
        var lineNumbers = $('editorLineNumbers');
        var count;
        var lines;
        var index;

        if (!editor || !lineNumbers) {
            return;
        }

        count = editorLineCount(editor.value);
        lines = [];
        for (index = 1; index <= count; index += 1) {
            lines.push(String(index));
        }

        lineNumbers.textContent = lines.join('\n');
        syncEditorLineNumberScroll();
    }

    function initEditorLineNumbers() {
        var editor = $('editor');

        if (!editor) {
            return;
        }

        editor.addEventListener('input', updateEditorLineNumbers);
        editor.addEventListener('scroll', syncEditorLineNumberScroll);
        updateEditorLineNumbers();
    }

    function initItemsPage() {
        $('refreshItems').addEventListener('click', function () {
            loadItems();
        });
        $('saveItems').addEventListener('click', saveItems);
        $('searchInput').addEventListener('input', renderItems);

        (function watchAvailability(initialized) {
            request('overview', initialized ? { silent: true } : undefined).then(function (data) {
                var wasBlocked = state.upgradeBlocked;
                syncRebootBanner(data);
                var blocked = syncUpgradeBlocked(data);

                if (!blocked && (!initialized || wasBlocked)) {
                    loadItems(wasBlocked ? { silent: true } : undefined);
                }

                setTimeout(function () {
                    watchAvailability(true);
                }, blocked ? 4000 : 12000);
            }).catch(function (error) {
                if (isBusyError(error)) {
                    setBusyLoading(t('update.loadingState'));
                    scheduleBusyRetry('items-availability', function () {
                        watchAvailability(true);
                    });
                    return;
                }
                setToast(error.message, 'error');
                setTimeout(function () {
                    watchAvailability(true);
                }, 12000);
            });
        })(false);
    }

    function loadFile(options) {
        state.configLoaded = false;
        if ($('saveFile')) {
            $('saveFile').disabled = true;
        }
        options = options || {};
        options.data = { file: state.currentFile };
        return request('read', options).then(function (data) {
            if (isRetryBusyResult(data)) {
                setBusyLoading(t('common.loading'));
                scheduleBusyRetry('file', function () {
                    loadFile({ silent: true });
                });
                return;
            }
            clearLoadingNow();
            state.configLoaded = true;
            if ($('saveFile')) {
                $('saveFile').disabled = false;
            }
            $('editor').value = data.content || '';
            updateEditorLineNumbers();
        }).catch(function (error) {
            if (isBusyError(error)) {
                setBusyLoading(t('common.loading'));
                scheduleBusyRetry('file', function () {
                    loadFile({ silent: true });
                });
                return;
            }
            state.configLoaded = false;
            if ($('saveFile')) {
                $('saveFile').disabled = true;
            }
            $('editor').value = '';
            updateEditorLineNumbers();
            setToast(error.message, 'error');
        });
    }

    function saveFile() {
        if (!state.configLoaded) {
            setToast(t('common.readFailed'), 'error');
            return;
        }
        request('write', {
            method: 'POST',
            data: {
                file: state.currentFile,
                content: $('editor').value
            }
        }).then(function (data) {
            setToast(withRebootHint(data.message || t('common.saved')), 'success');
            loadFile();
        }).catch(function (error) {
            if (isBusyError(error)) {
                setBusyLoading(t('common.loading'));
                return;
            }
            setToast(error.message, 'error');
        });
    }

    function initConfig() {
        state.currentFile = 'user-config';
        state.configLoaded = false;
        $('saveFile').disabled = true;
        initEditorLineNumbers();
        $('reloadFile').addEventListener('click', function () {
            loadFile();
        });
        $('saveFile').addEventListener('click', saveFile);

        (function watchAvailability(initialized) {
            request('overview', initialized ? { silent: true } : undefined).then(function (data) {
                var wasBlocked = state.upgradeBlocked;
                syncRebootBanner(data);
                var blocked = syncUpgradeBlocked(data);

                if (!blocked && (!initialized || wasBlocked)) {
                    loadFile(wasBlocked ? { silent: true } : undefined);
                }

                setTimeout(function () {
                    watchAvailability(true);
                }, blocked ? 4000 : 12000);
            }).catch(function (error) {
                if (isBusyError(error)) {
                    setBusyLoading(t('update.loadingState'));
                    scheduleBusyRetry('config-availability', function () {
                        watchAvailability(true);
                    });
                    return;
                }
                setToast(error.message, 'error');
                setTimeout(function () {
                    watchAvailability(true);
                }, 12000);
            });
        })(false);
    }

    function startPage() {
        applyI18n(document);

        if (page === 'shell') {
            initShell();
        } else if (page === 'overview' || page === 'hardware') {
            initOverview();
        } else if (page === 'update') {
            initUpdate();
        } else if (page === 'addons' || page === 'modules') {
            initItemsPage();
        } else if (page === 'config') {
            initConfig();
        }
    }

    state.locale = detectLocale();
    loadLocaleMessages(state.locale).then(startPage, startPage);
})();
