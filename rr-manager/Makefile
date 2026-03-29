SPK_NAME = rr-manager
SPK_VERS = 4.0
SPK_REV = 1
SPK_ICON = src/rr-manager.png

override ARCH = noarch

MAINTAINER = RROrg
DESCRIPTION = Manage RR bootloader configuration and RR upgrades directly from DSM.
DISPLAY_NAME = RR Manager
HOMEPAGE = https://github.com/RROrg/rr
LICENSE = GPLv3

DSM_UI_DIR = app
DSM_UI_CONFIG = src/ui/config
DSM_APP_NAME = RROrg.RRManager.Application

CONF_DIR = src/conf
SYSTEM_GROUP = http
SERVICE_SETUP = src/service-setup.sh
SSS_SCRIPT = src/start-stop-status.sh
STARTABLE = no
COPY_TARGET = nop
POST_STRIP_TARGET = rr_manager_extra_install

include ../../mk/spksrc.common.mk
include ../../mk/spksrc.spk.mk

.PHONY: rr_manager_extra_install
rr_manager_extra_install:
	install -m 755 -d $(STAGING_DIR)/app
	for lang in enu ara ger spn fre jpn krn rus tha trk ukr vit chs cht en_US ar_SA de_DE es_ES fr_FR ja_JP ko_KR ru_RU th_TH tr_TR uk_UA vi_VN zh_CN zh_HK zh_TW; do \
		install -m 755 -d $(STAGING_DIR)/app/help/$$lang; \
		install -m 755 -d $(STAGING_DIR)/app/texts/$$lang; \
	done
	install -m 755 -d $(STAGING_DIR)/app/images
	install -m 755 -d $(STAGING_DIR)/bin
	install -m 755 -d $(STAGING_DIR)/var

	install -m 644 src/ui/config $(STAGING_DIR)/app/config
	install -m 644 src/ui/application.cfg $(STAGING_DIR)/app/application.cfg
	install -m 644 src/ui/index.conf $(STAGING_DIR)/app/index.conf
	install -m 644 src/ui/helptoc.conf $(STAGING_DIR)/app/helptoc.conf
	install -m 755 -d $(STAGING_DIR)/app/scripts
	install -m 644 src/ui/style.css $(STAGING_DIR)/app/style.css
	install -m 644 src/ui/app.js $(STAGING_DIR)/app/app.js
	install -m 644 src/ui/rr-manager.js $(STAGING_DIR)/app/rr-manager.js
	install -m 644 src/ui/index.html $(STAGING_DIR)/app/index.html
	install -m 644 src/ui/overview.html $(STAGING_DIR)/app/overview.html
	install -m 644 src/ui/update.html $(STAGING_DIR)/app/update.html
	install -m 644 src/ui/addons.html $(STAGING_DIR)/app/addons.html
	install -m 644 src/ui/modules.html $(STAGING_DIR)/app/modules.html
	install -m 644 src/ui/config.html $(STAGING_DIR)/app/config.html
	install -m 755 src/ui/scripts/api.cgi $(STAGING_DIR)/app/scripts/api.cgi
	for lang in enu en_US; do \
		install -m 644 src/ui/help/enu/index.html $(STAGING_DIR)/app/help/$$lang/index.html; \
		install -m 644 src/ui/texts/enu/strings $(STAGING_DIR)/app/texts/$$lang/strings; \
		install -m 644 src/ui/texts/enu/ui.json $(STAGING_DIR)/app/texts/$$lang/ui.json; \
	done
	for item in "ara:ar_SA" "ger:de_DE" "spn:es_ES" "fre:fr_FR" "jpn:ja_JP" "krn:ko_KR" "rus:ru_RU" "tha:th_TH" "trk:tr_TR" "ukr:uk_UA" "vit:vi_VN"; do \
		short_lang=$${item%%:*}; \
		full_lang=$${item##*:}; \
		install -m 644 src/ui/help/enu/index.html $(STAGING_DIR)/app/help/$$short_lang/index.html; \
		install -m 644 src/ui/texts/$$short_lang/strings $(STAGING_DIR)/app/texts/$$short_lang/strings; \
		install -m 644 src/ui/texts/$$short_lang/ui.json $(STAGING_DIR)/app/texts/$$short_lang/ui.json; \
		install -m 644 src/ui/help/enu/index.html $(STAGING_DIR)/app/help/$$full_lang/index.html; \
		install -m 644 src/ui/texts/$$short_lang/strings $(STAGING_DIR)/app/texts/$$full_lang/strings; \
		install -m 644 src/ui/texts/$$short_lang/ui.json $(STAGING_DIR)/app/texts/$$full_lang/ui.json; \
	done
	for lang in chs zh_CN; do \
		install -m 644 src/ui/help/chs/index.html $(STAGING_DIR)/app/help/$$lang/index.html; \
		install -m 644 src/ui/texts/chs/strings $(STAGING_DIR)/app/texts/$$lang/strings; \
		install -m 644 src/ui/texts/chs/ui.json $(STAGING_DIR)/app/texts/$$lang/ui.json; \
	done
	for lang in cht zh_HK zh_TW; do \
		install -m 644 src/ui/help/cht/index.html $(STAGING_DIR)/app/help/$$lang/index.html; \
		install -m 644 src/ui/texts/cht/strings $(STAGING_DIR)/app/texts/$$lang/strings; \
		install -m 644 src/ui/texts/cht/ui.json $(STAGING_DIR)/app/texts/$$lang/ui.json; \
	done
	install -m 644 src/ui/images/*.png $(STAGING_DIR)/app/images/

	install -m 755 src/bin/rr-manager-lib.sh $(STAGING_DIR)/bin/rr-manager-lib.sh
	install -m 755 src/bin/rr-manager-job.sh $(STAGING_DIR)/bin/rr-manager-job.sh
