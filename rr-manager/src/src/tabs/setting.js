export default Ext.define('SYNOCOMMUNITY.RRManager.Setting.Main', {
  extend: 'SYNO.SDS.Utils.TabPanel',
  helper: SYNOCOMMUNITY.RRManager.Helper,
  constructor: function (e) {
    (this.appWin = e.appWin), (this.owner = e.owner), this.callParent([this.fillConfig(e)]);
  },
  fillConfig: function (e) {
    this.generalTab = new SYNOCOMMUNITY.RRManager.Setting.GeneralTab({
      appWin: this.appWin,
      owner: this,
      itemId: 'GeneralTab',
    });

    this.rrConfigTab = new SYNOCOMMUNITY.RRManager.Setting.RRConfigTab({
      appWin: this.appWin,
      owner: this,
      itemId: 'RRConfigTab',
    });

    this.synoInfoTab = new SYNOCOMMUNITY.RRManager.Setting.SynoInfoTab({
      appWin: this.appWin,
      owner: this,
      itemId: 'SynoInfoTab',
    });

    this.rrManagerConfigTab = new SYNOCOMMUNITY.RRManager.Setting.RrManagerConfigTab({
      appWin: this.appWin,
      owner: this,
      itemId: 'RrManagerConfigTab',
    });

    const tabs = [this.generalTab, this.rrConfigTab, this.synoInfoTab, this.rrManagerConfigTab];

    const settingsConfig = {
      title: 'Settings',
      autoScroll: true,
      useDefaultBtn: true,
      labelWidth: 200,
      fieldWidth: 240,
      activeTab: 0,
      deferredRender: false,
      items: tabs,
      listeners: {
        activate: this.updateAllForm,
        scope: this,
      },
    };

    return Ext.apply(settingsConfig, e);
  },
  loadAllForms: function (config) {
    const user_config = config.user_config;
    const rrm_config = config.rrm_config;
    this.items.each(t => {
      if (t && Ext.isFunction(t.loadForm)) {
        if (t.itemId === 'SynoInfoTab') {
          t.loadForm(user_config.synoinfo);
        }
        if (t.itemId === 'RrManagerConfigTab') {
          t.loadForm(rrm_config);
        } else {
          t.loadForm(user_config);
        }
      }
    });
  },
  updateEnv: function (e) {},
  updateAllForm: async function () {
    this.setStatusBusy();
    try {
      const e = await this.getConf();
      this.loadAllForms(e), this.updateEnv(e);
    } catch (e) {
      SYNO.Debug(e);
    }
    this.clearStatusBusy();
  },
  applyHandler: function () {
    this.confirmApply() && this.doApply().catch(error => alert('Error', error));
  },
  doApply: async function () {
    this.setStatusBusy();
    try {
      await this.setConf();
      await this.updateAllForm();
      this.clearStatusBusy();
      this.setStatusOK();
    } catch (e) {
      SYNO.Debug(e);
      this.clearStatusBusy();
      this.appWin.getMsgBox().alert(this.title, this.API.getErrorString(e));
    }
  },
  getParams: function () {
    const generalTab = this.generalTab.getForm().getValues();
    const rrConfigTab = this.rrConfigTab.getForm().getValues();
    const rrManagerConfigTab = this.rrManagerConfigTab.getForm().getValues();
    localStorage.setItem('rrManagerConfig', JSON.stringify(rrManagerConfigTab));

    const synoInfoTab = this.synoInfoTab.getForm().getValues();
    const synoInfoTabFixed = {
      synoinfo: synoInfoTab,
    };

    var rrConfigJson = localStorage.getItem('rrConfig');
    var rrConfig = JSON.parse(rrConfigJson);
    return Object.assign(rrConfig?.user_config, generalTab, rrConfigTab, synoInfoTabFixed);
  },
  getConf: function () {
    var rrConfigJson = localStorage.getItem('rrConfig');
    var rrConfig = JSON.parse(rrConfigJson);
    var appConfig = this.appWin.appInstance.initialConfig || {};
    var rrManagerConfig = appConfig.taskButton?.jsConfig || appConfig;

    return {
      user_config: rrConfig?.user_config,
      rrm_config: rrManagerConfig,
    };
  },
  setConf: function () {
    var user_config = this.getParams();
    var rrConfigJson = localStorage.getItem('rrConfig');
    var rrConfigOrig = JSON.parse(rrConfigJson);
    var rrManagerConfigJson = localStorage.getItem('rrManagerConfig');
    var rrManagerConfigOrig = JSON.parse(rrManagerConfigJson);
    rrConfigOrig.user_config = user_config;
    localStorage.setItem('rrConfig', JSON.stringify(rrConfigOrig));

    return this.appWin.handleFileUpload(user_config, rrManagerConfigOrig);
  },
  confirmApply: function () {
    if (!this.isAnyFormDirty()) {
      return (
        this.setStatusError({
          text: this.helper.V('ui', 'frm_validation_no_change'),
          clear: !0,
        }),
        !1
      );
    }
    const e = this.getAllForms().find(e => !e.isValid());
    return (
      !e ||
      (this.setActiveTab(e.itemId),
      this.setStatusError({
        text: this.helper.V('ui', 'frm_validation_fill_required_fields'),
      }),
      !1)
    );
  },
  onPageConfirmLostChangeSave: function () {
    return this.confirmApply() ? this.doApply() : Promise.reject();
  },
});
