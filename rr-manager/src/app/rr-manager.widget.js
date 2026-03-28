// Namespace definition
Ext.ns('SYNOCOMMUNITY.RRManager');

Ext.define('SYNOCOMMUNITY.RRManager.Widget', {
  // Translator
  _V: function (category, element) {
    return _TT('SYNOCOMMUNITY.RRManager.Widget', category, element);
  },
  extend: 'Ext.Panel',
  minimizable: true,
  taskButton: undefined,
  versionInfo: {
    rr_version: '--',
    rr_manager_version: '--',
    rr_update_version: '--',
  },
  constructor: function constructor(a) {
    this.initializeSouthTable();
    var b = Ext.apply(this.getConfig(), a);
    SYNOCOMMUNITY.RRManager.Widget.superclass.constructor.call(this, b);
    this.westIcon = this.getIconComponent();
    this.centerContent = this.getContentComponent();
    this.isActive = false;
    this.timestamp = null;
    this.uptime = null;
    this.appSetting = {
      appInstance: 'SYNOCOMMUNITY.RRManager.AppInstance',
      launchParam: 'SYNOCOMMUNITY.RRManager.Overview.Main',
    };
  },
  loadInfo: async function () {
    if (this.isActive) {
      this.mask(_T('common', 'loading'));
      await this.startPolling();
    }
  },
  startPolling: async function () {
    const self = this;
    window.test_rr = self;
    const rrRR = await this.checkRRVersion();
    const rrConf = await this.getRRConf();
    let rr_health_status = rrConf.rr_health === 'healthy' ? this.TYPE_NORMAL : this.TYPE_ATTENTION;
    self.setInfo({
      title: self.getTitle(rr_health_status),
      message: self.getStatusMessage(rr_health_status),
      type: rr_health_status,
    });
    self.packages = await self.getPackagesList();
    const rrManagerPackage = self?.packages?.packages?.find(
      packageItem => packageItem.id === 'rr-manager'
    );
    self.versionInfo = {
      rr_loader_version: rrConf?.rr_version.LOADERVERSION,
      rr_manager_version: rrManagerPackage?.version,
      rr_update_version: rrRR.tag,
      rr_update_url: rrRR.url,
    };
    this.southTable.add(self.renderVersionInfo(self.versionInfo));
    this.southTable.doLayout();
  },
  getTitle: function (t) {
    switch (t) {
      case this.TYPE_DANGER:
        return this._V('widget', 'danger_status');
      case this.TYPE_ATTENTION:
        return this._V('widget', 'attention_status');
      case this.TYPE_NORMAL:
      default:
        return this._V('widget', 'good_status');
    }
  },
  getStatusMessage: function (t) {
    switch (t) {
      case this.TYPE_DANGER:
        return this._V('widget', 'danger_status_message');
      case this.TYPE_ATTENTION:
        return this._V('widget', 'attention_status_message');
      case this.TYPE_NORMAL:
      default:
        return this._V('widget', 'good_status_message');
    }
  },
  setInfo: function (status) {
    // If the component is destroyed, we don't need to do anything
    if (this.isDestroyed) {
      return;
    }
    // Remove any loading mask
    this.unmask();
    this.setStatus(status);
  },
  setStatus: function (rule) {
    this.currentRule = rule;

    let contentComponent = this.getContentComponent();

    // if (this.getTaskButton()) {
    //   this.getTaskButton().setStatus(rule);
    // }

    if (this.rendered) {
      this.getIconComponent().update(this.getIcon(rule));
      contentComponent.update(this.formatContent(rule));

      let northPanel = this.getComponent('layoutPanel').getComponent('northPanel');
      northPanel.doLayout();
    }
  },
  formatContent: function (t) {
    const e = this.getContent(t.type);
    return (
      '<div class="syno-sysinfo-system-health-content-wrap">' +
      String.format(
        '<div class = "syno-sysinfo-system-health-summary {0}" ext:qtip="{1}">{1}</div>',
        e,
        t.title
      ) +
      String.format(
        '<div class = "syno-sysinfo-system-health-content" ext:qtip="{0}">{0}</div>',
        t.message
      ) +
      '</div>'
    );
  },
  getContent: function (t) {
    switch (t) {
      case this.TYPE_DANGER:
        return 'syno-sysinfo-system-health-content-header-emergency red-status';
      case this.TYPE_ATTENTION:
        return 'syno-sysinfo-system-health-content-header-warning';
      case this.TYPE_NORMAL:
      default:
        return 'syno-sysinfo-system-health-content-header-normal';
    }
  },
  getPackagesList: function () {
    var that = this;
    return new Promise((resolve, reject) => {
      let params = {
        additional: [
          'description',
          'description_enu',
          'dependent_packages',
          'beta',
          'distributor',
          'distributor_url',
        ], //, "maintainer", "maintainer_url", "dsm_apps", "dsm_app_page", "dsm_app_launch_name","report_beta_url", "support_center", "startable", "installed_info", "support_url", "is_uninstall_pages", "install_type", "autoupdate", "silent_upgrade"], //, "installing_progress", "ctl_uninstall", "updated_at", "status", "url", "available_operation", "install_type"
        ignore_hidden: false,
      };
      let args = {
        api: 'SYNO.Core.Package',
        method: 'list',
        version: 2,
        params: params,
        callback: function (success, message) {
          success ? resolve(message) : reject('Unable to get packages!');
        },
      };
      that.sendWebAPI(args);
    });
  },
  _prefix: '/webman/3rdparty/rr-manager/scripts/',
  callCustomScript: function (scriptName) {
    return new Promise((resolve, reject) => {
      Ext.Ajax.request({
        url: `${this._prefix}${scriptName}`,
        method: 'GET',
        timeout: 60000,
        headers: {
          'Content-Type': 'text/html',
        },
        success: function (response) {
          // if response text is string need to decode it
          if (typeof response?.responseText === 'string') {
            resolve(Ext.decode(response?.responseText));
          } else {
            resolve(response?.responseText);
          }
        },
        failure: function (result) {
          if (
            typeof result?.responseText === 'string' &&
            result?.responseText &&
            !result?.responseText.startsWith('<')
          ) {
            var response = Ext.decode(result?.responseText);
            reject(response?.error);
          } else {
            reject('Failed with status: ' + result?.status);
          }
        },
      });
    });
  },
  TYPE_DANGER: 0,
  TYPE_ATTENTION: 1,
  TYPE_NORMAL: 2,
  _getIcon: function (t) {
    switch (t) {
      case this.TYPE_DANGER:
        return 'syno-sysinfo-system-health-west-emergency';
      case this.TYPE_ATTENTION:
        return 'syno-sysinfo-system-health-west-warning';
      case this.TYPE_NORMAL:
      default:
        return 'syno-sysinfo-system-health-west-normal';
    }
  },
  getIcon: function (t) {
    return `<div class = "${this._getIcon(t.type)}"></div>`;
  },
  getRRConf: function () {
    return this.callCustomScript('getConfig.cgi');
  },
  checkRRVersion: function () {
    return this.callCustomScript('getRrReleaseInfo.cgi');
  },
  getConfig: function getConfig() {
    return {
      layout: 'fit',
      border: false,
      defaults: {
        border: false,
      },
      items: [this.getViewConfig()],
      listeners: { scope: this, render: { fn: this.loadInfo, single: !0 } },
    };
  },
  getViewConfig: function getViewConfig() {
    return {
      itemId: 'layoutPanel',
      layout: 'vbox',
      height: '100%',
      border: false,
      padding: '0px 11px 5px 11px',
      cls: 'syno-sysinfo-system-health',
      defaults: {
        border: false,
      },
      items: [
        {
          xtype: 'container',
          itemId: 'northPanel',
          height: 80,
          width: 296,
          cls: 'syno-sysinfo-system-health-status',
          items: [
            {
              xtype: 'box',
              itemId: 'westIcon',
            },
            {
              xtype: 'box',
              itemId: 'centerContent',
              region: 'center',
            },
          ],
        },
        {
          region: 'south',
          height: 84,
          width: 296,
          items: this.southTable,
        },
      ],
    };
  },
  doCollapse: function doCollapse() {
    this.getEl().setHeight(84);
    this.doLayout();
  },
  doExpand: function doExpand() {
    this.getEl().setHeight(172);
    this.doLayout();
  },
  setApp: function setApp(a) {
    this.appSetting = a;
  },

  getIconComponent: function getIconComponent() {
    return this.getComponent('layoutPanel').getComponent('northPanel').getComponent('westIcon');
  },
  getContentComponent: function getContentComponent() {
    return this.getComponent('layoutPanel')
      .getComponent('northPanel')
      .getComponent('centerContent');
  },
  onClickTitle: function onClickTitle() {
    SYNO.SDS.AppLaunch(this.appSetting.appInstance, this.appSetting.launchParam);
  },
  onActivate: function onActivate() {
    this.isActive = true;
    (async () => {
      await this.loadInfo();
    })();
  },
  onDeactivate: function onDeactivate() {
    this.isActive = false;
    this.unmask();
  },
  mask: Ext.emptyFn,
  unmask: Ext.emptyFn,
  placeHolder: '--',
  initializeSouthTable: function initializeSouthTable() {
    var self = this;
    var b = Ext.util.Format.htmlEncode(this._V('widget', 'message'));
    var c = Ext.util.Format.htmlEncode(_S('hostname'));
    this.southTable = new Ext.Panel({
      layout: 'table',
      itemId: 'southTable',
      cls: 'sys-info-south-table',
      margins: 0,
      height: 84,
      layoutConfig: {
        columns: 2,
        cellCls: 'sys-info-row',
      },
      items: [],
    });
  },
  renderVersionInfo: function (versionInfo) {
    let labels = [
      {
        xtype: 'box',
        html: String.format(
          '<p ext:qtip="{1}" class="syno-sysinfo-system-health-south-title">{0}</p>',
          '💊RR:',
          Ext.util.Format.htmlEncode('💊RR:')
        ),
      },
      {
        name: 'rrVerison',
        id: 'rrVerison',
        xtype: 'box',
        html: String.format(
          '<p ext:qtip="{1}" class="syno-sysinfo-system-health-south-data">{0}</p>',
          versionInfo.rr_loader_version,
          Ext.util.Format.htmlEncode(versionInfo.rr_loader_version)
        ),
      },
      {
        xtype: 'box',
        html: String.format(
          '<p ext:qtip="{1}" class="syno-sysinfo-system-health-south-title">{0}</p>',
          '🛡️RR Manager:',
          Ext.util.Format.htmlEncode('🛡️RR Manager:')
        ),
      },
      {
        name: 'rrMVersion',
        id: 'rrMVersion',
        xtype: 'box',
        html: String.format(
          '<p ext:qtip="{1}" class="syno-sysinfo-system-health-south-data">{0}</p>',
          versionInfo.rr_manager_version,
          Ext.util.Format.htmlEncode(versionInfo.rr_manager_version)
        ),
      },
    ];
    if (versionInfo.rr_loader_version !== versionInfo.rr_update_version) {
      labels.push({
        xtype: 'box',
        html: String.format(
          '<p ext:qtip="{1}" class="syno-sysinfo-system-health-south-title">{0}</p>',
          'RR update available!',
          Ext.util.Format.htmlEncode('RR update available!')
        ),
      });
      labels.push({
        xtype: 'box',
        id: 'rrUpdateVersionAvailable',
        html: String.format(
          '<a ext:qtip="{0}" href="{1}" class="syno-sysinfo-system-health-south-data">{0}</a>',
          versionInfo.rr_update_version,
          Ext.util.Format.htmlEncode(versionInfo.rr_update_url)
        ),
      });
    }
    return labels;
  },
  destroy: function destroy() {
    var a = this;
    a.onDeactivate();
    if (a.taskButton) {
      Ext.destroy(a.taskButton);
    }
    if (a.southGrid && a.southGrid.getStore()) {
      a.southGrid.getStore().destroy();
    }
    SYNOCOMMUNITY.RRManager.Widget.superclass.destroy.call(this);
  },
});
