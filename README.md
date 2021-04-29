# SimpleExtJSApp
Simple ExtJS Application for DSM 7.0 :<br><br>
This part includes a test.cgi, which is verifying the authentication of the current user under DSM. <br> 
The CGI must be called via an Ajax request to the "/webman/3rdparty/simpleextjsapp/test.cgi" URL <br>

The package part can be generated in the spksrc repo in the simpleextjsapp branch. <br>

Application: <br>

![GUI1](https://user-images.githubusercontent.com/57635141/116535086-a38e8100-a8e3-11eb-9fb2-883a69d384ce.png) <br>
![GUI2](https://user-images.githubusercontent.com/57635141/116535121-ad17e900-a8e3-11eb-9293-7ed15f171059.png) <br>

Integrated docs: <br>
![docs](https://user-images.githubusercontent.com/57635141/116140367-871df900-a6d7-11eb-9ba5-602bd9f5e5ba.png)

This page is to be considered as a work in progress with more information to come : ) <br>

# Synology DSM 7.0
The Synology DSM 7.0 client part is based on ExtJS 3.4 library <br><br>

Synology JS lib location : /usr/syno/synoman/synoSDSjslib/sds.js <br>
ExtJS 3.4 location : /usr/syno/synoman/scripts/ext-3.4/ext-all.js <br>
Synology ExtJS additional UX widgets : /usr/syno/synoman/scripts/ext-3.4/ux/ux-all.js <br>

# ExtJS 3.4 framework docs
Available at : http://cdn.sencha.com/ext/gpl/3.4.1.1/release-notes.html<br>

# Documentation in progress :
| Widget | Documentation |
|----------|:-------------:|
| SYNO.ux.AriaComponent |  |
| SYNO.ux.BackNextBtnGroup (xtype: "syno_backnextbtngroup") |  |
| SYNO.ux.Button (xtype: "syno_button") | :ok: |
| SYNO.ux.Checkbox (xtype: "syno_checkbox") | :ok: |
| SYNO.ux.ColorField (xtype: "syno_colorfield") |  |
| SYNO.ux.ComboBox (xtype: "syno_combobox") |  |
| SYNO.ux.CompositeField (xtype: "syno_compositefield") |  |
| SYNO.ux.CoverPanel (xtype: "syno_coverpanel")|  |
| SYNO.ux.DDGridPanel (xtype: "syno_dd_gridpanel") |  |
| SYNO.ux.DataViewAnimation |  |
| SYNO.ux.DataViewMask |  |
| SYNO.ux.DateField (xtype: "syno_datefield") |  |
| SYNO.ux.DateMenu |  |
| SYNO.ux.DatePicker |  |
| SYNO.ux.DateTime.SubMenu (xtype: "syno_datetime_submenu") |  |
| SYNO.ux.DateTimeField (xtype: "syno_datetimefield") |  |
| SYNO.ux.DateTimeMenu |  |
| SYNO.ux.DateTimePicker (xtype: "syno_datetimepickerfield") |  |
| SYNO.ux.DisplayField (xtype: "syno_displayfield") | :ok: |
| SYNO.ux.EditorGridPanel (xtype: "syno_editorgrid") |  |
| SYNO.ux.EnableColumn |  |
| SYNO.ux.ExpandableListView |  |
| SYNO.ux.FieldSet (xtype: "syno_fieldset") |  |
| SYNO.ux.FileButton (xtype: "syno_filebutton") |  |
| SYNO.ux.FixColGrid (xtype: "syno_fixedcolumn_grid") |  |
| SYNO.ux.FleXcroll.ComboBox |  |
| SYNO.ux.FleXcroll.DataView (xtype: "syno_flexcroll_dataview") |  |
| SYNO.ux.FleXcroll.grid.BufferView |  |
| SYNO.ux.FleXcroll.grid.GridView |  |
| SYNO.ux.FleXcroll.grid.HorizontalGridView |  |
| SYNO.ux.FleXcroll.grid.TreeView |  |
| SYNO.ux.FloatLayout |  |
| SYNO.ux.FormPanel (xtype: "syno_formpanel") |  |
| SYNO.ux.GridPanel (xtype: "syno_gridpanel") |  |
| SYNO.ux.GroupingView |  |
| SYNO.ux.HistoryRecorder |  |
| SYNO.ux.HorizontalGridPanel (xtype: "syno_h_gridpanel") |  |
| SYNO.ux.InvalidQuickTip (xtype: "syno_invalidquicktip") |  |
| SYNO.ux.InverseFieldSet (xtype: "syno_inversefieldset") |  |
| SYNO.ux.MacTextField (xtype: "syno_mactextfield") |  |
| SYNO.ux.Menu (xtype: "syno_menu") |  |
| SYNO.ux.ModuleList (xtype: "syno_modulelist") |  |
| SYNO.ux.NumberField (xtype: "syno_numberfield") |  |
| SYNO.ux.OperatableListView |  |
| SYNO.ux.PageLessToolbar (xtype: "syno_pageless") |  |
| SYNO.ux.PagingToolbar (xtype: "syno_paging") |  |
| SYNO.ux.PagingToolbar (xtype: "syno_paging") |  |
| SYNO.ux.Panel (xtype: "syno_panel") |  |
| SYNO.ux.Radio (xtype: "syno_radio") |  |
| SYNO.ux.RadioGroup (xtype: "syno_radio") |  |
| SYNO.ux.ScheduleField (xtype: "syno_schedulefield") |  |
| SYNO.ux.ScheduleSelector |  |
| SYNO.ux.ScheduleTable |  |
| SYNO.ux.ScheduleTableField |  |
| SYNO.ux.SearchField (xtype: "syno_searchfield")  |  |
| SYNO.ux.SingleSlider (xtype: "syno_singleslider") |  |
| SYNO.ux.SliderField (xtype: "syno_sliderfield") |  |
| SYNO.ux.SplitButton (xtype: "syno_splitbutton") |  |
| SYNO.ux.SplitButton (xtype: "syno_splitbutton") |  |
| SYNO.ux.StateButtonGroup (xtype: "syno_statebuttongroup")|  |
| SYNO.ux.StateButtonGroup |  |
| SYNO.ux.StatusProxy |  |
| SYNO.ux.SuperBoxSelect (xtype: "syno_superboxselect") |  |
| SYNO.ux.SuperBoxSelectItem |  |
| SYNO.ux.Switch (xtype: "syno_switch") |  |
| SYNO.ux.SwitchColumn (xtype: "syno_swtichcolumn") |  |
| SYNO.ux.TabPanel (xtype: "syno_tabpanel") |  |
| SYNO.ux.TextArea (xtype: "syno_textarea") |  |
| SYNO.ux.TextField (xtype: "syno_textfield") |  |
| SYNO.ux.TextFilter (xtype: "syno_textfilter") |  |
| SYNO.ux.TimeField (xtype: "syno_timefield") |  |
| SYNO.ux.TimePickerField (xtype: "syno_timepickerfield") |  |
| SYNO.ux.Toolbar (xtype: "syno_toolbar") |  |
| SYNO.ux.TreePanel |  |
| SYNO.ux.TriModeCheckbox |  |
| SYNO.ux.WhiteQuickTip |  |
| SYNO.ux.WhiteTipIcon |  |
| SYNO.ux._ButtonARIA |  |
| SYNO.ux._CheckboxARIA |  |
| SYNO.ux._ComboboxARIA |  |
| SYNO.ux._ComponentARIA |  |
| SYNO.ux._DataViewARIA |  |
| SYNO.ux._GridPanelARIA |  |
| SYNO.ux._MenuARIA |  |
| SYNO.ux._SliderARIA |  |
| SYNO.ux._TabPanelARIA |  |
| SYNO.ux._TreePanelARIA |  |
| SYNO.ux.data.TreeReader |  |
| SYNO.ux.grid.GridView.SplitDragZone |  |
| SYNO.ux.plugin.GroupHeaderGrid |  |
| SYNO.ux.plugin.StyledGrid |  |




# Useful links

Usage of ExtJS in DSM : https://github.com/SynoCommunity/spksrc/tree/master/spk/debian-chroot/src <br>
Usage of ExtJS + API in DSM : https://github.com/Rutorai/syno-library/wiki <br>
Example for writing API : https://github.com/Rutorai/syno-library/tree/develop/package/ <br>
SimpleExtJSApp source : https://github.com/DigitalBox98/spksrc/tree/simpleextjsapp/spk/simpleextjsapp/src/app <br>
