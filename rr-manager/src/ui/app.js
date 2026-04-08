(function () {
    var page = document.body.getAttribute('data-page');
    var state = {
        updateReleases: {
            rr: null,
            rrm: null
        },
        shellSummary: null,
        updateRunning: false,
        lastUpdateRunning: false,
        lastUpdateState: '',
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
    var UPDATE_VARIANTS = {
        rr: {
            releaseAction: 'release',
            retryKey: 'release',
            loadingKey: 'update.rrLoadingRelease',
            releaseBoxId: 'releaseBox',
            checkButtonId: 'checkRelease',
            onlineButtonId: 'startOnlineUpdate',
            localButtonId: 'startLocalUpdate',
            localInputId: 'localArchivePath',
            localPathErrorKey: 'update.rrEnterLocalPath',
            onlineAction: 'start-update-online',
            localAction: 'start-update-local',
            onlineSuccessKey: 'update.rrOnlineStarted',
            localSuccessKey: 'update.rrLocalStarted',
            silentLogRefresh: false
        },
        rrm: {
            releaseAction: 'rrm-release',
            retryKey: 'rrm-release',
            loadingKey: 'update.loadingRrmRelease',
            releaseBoxId: 'rrmReleaseBox',
            checkButtonId: 'checkRrmRelease',
            onlineButtonId: 'startRrmOnlineUpdate',
            localButtonId: 'startRrmLocalUpdate',
            localInputId: 'rrmLocalPackagePath',
            localPathErrorKey: 'update.enterRrmLocalPath',
            onlineAction: 'start-rrm-update-online',
            localAction: 'start-rrm-update-local',
            onlineSuccessKey: 'update.rrmOnlineStarted',
            localSuccessKey: 'update.rrmLocalStarted',
            silentLogRefresh: true
        }
    };

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

    function updateVariantConfig(kind) {
        return UPDATE_VARIANTS[kind] || UPDATE_VARIANTS.rr;
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

    function decodeUtf8Response(response) {
        return response.arrayBuffer().then(function (buffer) {
            if (typeof TextDecoder === 'function') {
                return new TextDecoder('utf-8').decode(buffer);
            }
            return String.fromCharCode.apply(null, new Uint8Array(buffer));
        });
    }

    function fetchMessages(dir) {
        return fetch('/webman/3rdparty/rr-manager/texts/' + dir + '/ui.json', {
            credentials: 'same-origin',
            cache: 'no-store'
        }).then(function (response) {
            if (!response.ok) {
                throw new Error('Failed to load locale bundle.');
            }
            return decodeUtf8Response(response).then(function (text) {
                return JSON.parse(text);
            });
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
        return {};
    }

    function t(key, vars) {
        var value = currentDictionary()[key];
        var name;

        if (value == null && state.baseMessages) {
            value = state.baseMessages[key];
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

    function showRebootBannerNow(message) {
        syncRebootBanner({
            updateState: 'pending-reboot',
            updateMessage: message || t('common.rebootRequiredHint')
        });
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

        return bootKernel + ' [' + systemKernel + ']';
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

    function isBootloaderUnavailable(data) {
        return !!(data && data.boot && data.boot.mountStatus === 'unavailable');
    }

    function isUnsupportedBootloader(data) {
        return !!(data && data.boot && data.boot.mountStatus === 'unsupported');
    }

    function upgradeBlockContent(data) {
        if (isUnsupportedBootloader(data)) {
            return {
                eyebrow: t('common.boot'),
                title: t('boot.unsupportedTitle'),
                body: t('boot.unsupportedBody'),
                statusItems: [
                    [t('common.state'), t('boot.unsupportedTitle')],
                    [t('update.jobMessage'), (data.boot && data.boot.mountMessage) || t('boot.unsupportedHint')]
                ]
            };
        }

        if (isBootloaderUnavailable(data)) {
            return {
                eyebrow: t('common.boot'),
                title: t('boot.unavailableTitle'),
                body: t('boot.unavailableBody'),
                statusItems: [
                    [t('common.state'), t('boot.unavailableTitle')],
                    [t('update.jobMessage'), (data.boot && data.boot.mountMessage) || t('boot.unavailableHint')]
                ]
            };
        }

        return {
            eyebrow: t('update.stateEyebrow'),
            title: t('update.unavailableTitle'),
            body: t('update.unavailableBody'),
            statusItems: [
                [t('update.updateStateStat'), (data && data.updateState) || t('common.running')],
                [t('update.jobMessage'), (data && data.updateMessage) || t('update.unavailableHint')]
            ]
        };
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
        var content;
        var mask;

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
        content = upgradeBlockContent(data);

        $('upgradeBlockEyebrow').textContent = content.eyebrow;
        $('upgradeBlockTitle').textContent = content.title;
        $('upgradeBlockBody').textContent = content.body;
        $('upgradeBlockStatus').innerHTML = renderStatusLines(content.statusItems);
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

        if (isUnsupportedBootloader(data)) {
            return setUpgradeBlocked(true, data);
        }

        if (isBootloaderUnavailable(data)) {
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
                return decodeUtf8Response(response).then(function (text) {
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

    function requestWithPageLoading(action, options, onSuccess) {
        var key;
        var requestOptions = {};
        var silent;

        options = options || {};
        silent = !!options.silent;

        for (key in options) {
            if (Object.prototype.hasOwnProperty.call(options, key)) {
                requestOptions[key] = options[key];
            }
        }
        requestOptions.silent = true;

        if (!silent) {
            beginLoading(options.loadingMessage || t('common.loading'));
        }

        return request(action, requestOptions).then(function (data) {
            return Promise.resolve(onSuccess ? onSuccess(data) : data).then(function (result) {
                if (!silent) {
                    return waitForNextPaint().then(function () {
                        endLoading();
                        return result;
                    });
                }
                return result;
            });
        }, function (error) {
            if (!silent) {
                endLoading();
            }
            throw error;
        });
    }

    function waitForNextPaint() {
        return new Promise(function (resolve) {
            if (typeof requestAnimationFrame !== 'function') {
                setTimeout(resolve, 0);
                return;
            }
            requestAnimationFrame(function () {
                requestAnimationFrame(resolve);
            });
        });
    }

    function isBusyError(error) {
        return !!(error && (error.busy || error.status === 409 || /busy/i.test(error.message || '')));
    }

    function isRetryBusyResult(data) {
        return !!(data && data.busy && data.retry);
    }

    function hasResolvedBootIdentity(boot) {
        if (!boot) {
            return false;
        }

        return [boot.model, boot.version, boot.lkm, boot.mev, boot.sn, boot.mac1, boot.mac2].some(function (value) {
            return value && value !== 'unknown';
        });
    }

    function shouldHoldOverviewLoading(data) {
        var boot;

        if (page !== 'overview' && page !== 'hardware') {
            return false;
        }

        if (!data || data.updateRunning || isUnsupportedBootloader(data) || isBootloaderUnavailable(data)) {
            return false;
        }

        boot = data.boot || {};
        if (boot.mountStatus && boot.mountStatus !== 'ready') {
            return false;
        }

        return !hasResolvedBootIdentity(boot);
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
                setLocale(localeSelect.value, { reloadFrame: true }).then(function () {
                    renderShellSummary(state.shellSummary);
                });
            });
        }

        renderShellSummary(null);
        loadShellSummary({ silent: true });
    }

    function renderShellSummary(data) {
        var target = $('shellVersionSummary');
        var rrmVersion;
        var rrVersion;

        if (!target) {
            return;
        }

        rrmVersion = (data && data.currentPackageVersion) || 'X';
        rrVersion = (data && data.currentVersion) || 'X';
        target.textContent = '[RRM v' + rrmVersion + '] [RR v' + rrVersion + ']';
    }

    function loadShellSummary(options) {
        return requestWithPageLoading('overview', options, function (data) {
            state.shellSummary = data || null;
            renderShellSummary(state.shellSummary);
            return data;
        }).catch(function (error) {
            renderShellSummary(state.shellSummary);
            if (isBusyError(error)) {
                return;
            }
            setToast(error.message, 'error');
        });
    }

    function renderOverview(data) {
        var hardware;
        var boot;
        var dmiSummary;
        var wasUpdateRunning = state.updateRunning;
        var nextUpdateRunning = !!data.updateRunning;
        var nextUpdateState = (data && data.updateState) || '';

        state.lastUpdateRunning = wasUpdateRunning;
        state.lastUpdateState = nextUpdateState;
        state.updateRunning = nextUpdateRunning;
        syncRebootBanner(data);

        if (page === 'update' && wasUpdateRunning && !nextUpdateRunning && isRebootPendingState(nextUpdateState)) {
            showRebootBannerNow(data.updateMessage || t('common.rebootRequiredHint'));
            setToast(withRebootHint(data.updateMessage || t('common.saved')), 'success');
        }

        if (syncUpgradeBlocked(data)) {
            if (page === 'update') {
                if ($('startRrmLocalUpdate')) {
                    $('startRrmLocalUpdate').disabled = true;
                }
                if ($('startRrmOnlineUpdate')) {
                    $('startRrmOnlineUpdate').disabled = true;
                }
                if ($('checkRrmRelease')) {
                    $('checkRrmRelease').disabled = true;
                }
                if ($('startLocalUpdate')) {
                    $('startLocalUpdate').disabled = true;
                }
                if ($('startOnlineUpdate')) {
                    $('startOnlineUpdate').disabled = true;
                }
                if ($('checkRelease')) {
                    $('checkRelease').disabled = true;
                }
            }
            return;
        }

        if (page === 'update') {
            $('overviewStats').innerHTML = renderStats([
                [t('update.jobMessage'), data.updateMessage || t('common.ready')],
                [t('update.backgroundJob'), data.updateRunning ? t('common.running') : t('common.idle')],
                [t('update.updateStateStat'), data.updateState || t('common.idle')]
            ]);

            if (data.updateRunning) {
                clearBusyRetry(updateVariantConfig('rr').retryKey);
                clearBusyRetry(updateVariantConfig('rrm').retryKey);
            }

            syncUpdateVariantButtons('rrm', data.updateRunning);
            syncUpdateVariantButtons('rr', data.updateRunning);
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

    function updateReleaseState(kind, data) {
        state.updateReleases[kind] = data || null;
    }

    function currentReleaseState(kind) {
        return state.updateReleases[kind] || null;
    }

    function renderUpdateRelease(kind, data) {
        var cfg = updateVariantConfig(kind);

        updateReleaseState(kind, data);
        renderReleaseBox(cfg.releaseBoxId, data);
        syncUpdateVariantButtons(kind, state.updateRunning);
    }

    function syncUpdateVariantButtons(kind, isUpdateRunning) {
        var cfg = updateVariantConfig(kind);
        var releaseData = currentReleaseState(kind);
        var checkButton = $(cfg.checkButtonId);
        var onlineButton = $(cfg.onlineButtonId);
        var localButton = $(cfg.localButtonId);

        if (checkButton) {
            checkButton.disabled = !!isUpdateRunning;
        }
        if (onlineButton) {
            onlineButton.disabled = !!isUpdateRunning || !releaseData || !releaseData.assetUrl;
        }
        if (localButton) {
            localButton.disabled = !!isUpdateRunning;
        }
    }

    function renderReleaseBox(elementId, data) {
        var target = $(elementId);

        if (!target) {
            return;
        }

        target.innerHTML =
            '<div class="stat"><span class="statLabel">' + escapeHtml(t('update.currentVersionRelease')) + '</span><span class="statValue">' + escapeHtml(displayValue(data.currentVersion)) + '</span></div>' +
            '<div class="stat"><span class="statLabel">' + escapeHtml(t('update.latestVersionRelease')) + '</span><span class="statValue">' + escapeHtml(displayValue(data.latestVersion)) + '</span></div>' +
            '<div class="stat"><span class="statLabel">' + escapeHtml(t('update.publishedAt')) + '</span><span class="statValue">' + escapeHtml(displayValue(data.publishedAt)) + '</span></div>' +
            '<div class="stat"><span class="statLabel">' + escapeHtml(t('update.asset')) + '</span><span class="statValue">' + escapeHtml(data.assetName || t('update.noAsset')) + '</span></div>' +
            '<div class="stat hint"><span class="statLabel">' + escapeHtml(t('update.github')) + '</span><span class="statValue"><a href="' + escapeHtml(data.htmlUrl || '#') + '" target="_blank" rel="noreferrer">' + escapeHtml(data.htmlUrl || '') + '</a></span></div>';
    }

    function loadOverview(options) {
        return requestWithPageLoading('overview', options, function (data) {
            if (shouldHoldOverviewLoading(data)) {
                freezeLoading(t('update.loadingBoot'), 2200);
                scheduleBusyRetry('overview-ready', function () {
                    loadOverview({ silent: true });
                });
                return data;
            }
            clearBusyRetry('overview-ready');
            renderOverview(data);
            return data;
        }).catch(function (error) {
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

    function loadUpdateReleaseByKind(kind, options) {
        var cfg = updateVariantConfig(kind);

        return loadUpdateRelease(cfg.releaseAction, cfg.loadingKey, options, function (data) {
            renderUpdateRelease(kind, data);
        });
    }

    function loadUpdateRelease(action, loadingKey, options, onLoad) {
        if (state.updateRunning || state.upgradeBlocked) {
            clearBusyRetry(action);
            return Promise.resolve();
        }

        return requestWithPageLoading(action, options, function (data) {
            if (isRetryBusyResult(data)) {
                if (state.updateRunning) {
                    clearBusyRetry(action);
                    return data;
                }
                setBusyLoading(t(loadingKey));
                scheduleBusyRetry(action, function () {
                    loadUpdateRelease(action, loadingKey, { silent: true }, onLoad);
                });
                return data;
            }
            onLoad(data);
            return data;
        }).catch(function (error) {
            if (isBusyError(error)) {
                if (state.updateRunning) {
                    clearBusyRetry(action);
                    return;
                }
                setBusyLoading(t(loadingKey));
                scheduleBusyRetry(action, function () {
                    loadUpdateRelease(action, loadingKey, { silent: true }, onLoad);
                });
                return;
            }
            setToast(error.message, 'error');
        });
    }

    function refreshLog(options) {
        return requestWithPageLoading('log', options, function (data) {
            $('logView').textContent = data.log || t('update.noLog');
            return data;
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

    function startUpdateOnline(kind) {
        var cfg = updateVariantConfig(kind);

        startUpdateAction(cfg.onlineAction, null, cfg.onlineSuccessKey, cfg.silentLogRefresh);
    }

    function startUpdateLocal(kind) {
        var cfg = updateVariantConfig(kind);
        var input = $(cfg.localInputId);
        var path = input ? input.value.trim() : '';

        if (!path) {
            setToast(t(cfg.localPathErrorKey), 'error');
            return;
        }
        startUpdateAction(cfg.localAction, { path: path }, cfg.localSuccessKey, cfg.silentLogRefresh);
    }

    function startUpdateAction(action, data, successKey, silentLogRefresh) {
        var requestOptions = { method: 'POST' };

        if (data) {
            requestOptions.data = data;
        }

        request(action, requestOptions).then(function (response) {
            setToast(response.message || t(successKey), 'success');
            loadOverview();
            refreshLog(silentLogRefresh ? { silent: true } : undefined);
        }).catch(function (error) {
            if (isBusyError(error)) {
                setBusyLoading(t('update.loadingState'));
                return;
            }
            setToast(error.message, 'error');
        });
    }

    function initOverview() {
        setBusyLoading(t('update.loadingBoot'));
        $('refreshOverview').addEventListener('click', function () {
            loadOverview();
        });
        loadOverview();
        (function pollOverview() {
            loadOverview({ silent: true });
            setTimeout(pollOverview, state.updateRunning ? 1000 : 12000);
        })();
    }

    function initUpdate() {
        setBusyLoading(t('update.loadingState'));
        $('refreshOverview').addEventListener('click', function () {
            loadOverview();
        });
        $(updateVariantConfig('rrm').checkButtonId).addEventListener('click', function () {
            loadUpdateReleaseByKind('rrm');
        });
        $(updateVariantConfig('rr').checkButtonId).addEventListener('click', function () {
            loadUpdateReleaseByKind('rr');
        });
        $('refreshLog').addEventListener('click', function () {
            refreshLog();
        });
        $(updateVariantConfig('rrm').onlineButtonId).addEventListener('click', function () {
            startUpdateOnline('rrm');
        });
        $(updateVariantConfig('rrm').localButtonId).addEventListener('click', function () {
            startUpdateLocal('rrm');
        });
        $(updateVariantConfig('rr').onlineButtonId).addEventListener('click', function () {
            startUpdateOnline('rr');
        });
        $(updateVariantConfig('rr').localButtonId).addEventListener('click', function () {
            startUpdateLocal('rr');
        });

        loadOverview().then(function () {
            if (!state.upgradeBlocked) {
                loadUpdateReleaseByKind('rrm', { silent: true });
                loadUpdateReleaseByKind('rr', { silent: true });
            }
        });
        refreshLog({ silent: true });

        (function pollUpdate() {
            loadOverview({ silent: true });
            refreshLog({ silent: true });
            setTimeout(pollUpdate, state.updateRunning ? 1000 : 12000);
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
        return requestWithPageLoading(cfg.loadAction, options, function (data) {
            if (isRetryBusyResult(data)) {
                setBusyLoading(t('common.loading'));
                scheduleBusyRetry('items', function () {
                    loadItems({ silent: true });
                });
                return data;
            }
            state.items = data.items || [];
            renderItems();
            return data;
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
            showRebootBannerNow(data.message || t('common.saved'));
            setToast(withRebootHint(data.message || t('common.saved')), 'success');
            loadOverview({ silent: true });
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
            request('overview', { silent: true }).then(function (data) {
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
        var requestOptions;
        var key;

        state.configLoaded = false;
        if ($('saveFile')) {
            $('saveFile').disabled = true;
        }
        options = options || {};
        requestOptions = {};
        for (key in options) {
            if (Object.prototype.hasOwnProperty.call(options, key)) {
                requestOptions[key] = options[key];
            }
        }
        requestOptions.data = { file: state.currentFile };
        return requestWithPageLoading('read', requestOptions, function (data) {
            if (isRetryBusyResult(data)) {
                setBusyLoading(t('common.loading'));
                scheduleBusyRetry('file', function () {
                    loadFile({ silent: true });
                });
                return data;
            }
            state.configLoaded = true;
            if ($('saveFile')) {
                $('saveFile').disabled = false;
            }
            $('editor').value = data.content || '';
            updateEditorLineNumbers();
            return data;
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
            showRebootBannerNow(data.message || t('common.saved'));
            setToast(withRebootHint(data.message || t('common.saved')), 'success');
            loadOverview({ silent: true });
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
            request('overview', { silent: true }).then(function (data) {
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
