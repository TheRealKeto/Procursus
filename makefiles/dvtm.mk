ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += dvtm
DVTM_VERSION := 0.15
DEB_DVTM_V   ?= $(DVTM_VERSION)

dvtm-setup: setup
	$(call GITHUB_ARCHIVE,martanne,dvtm,$(DVTM_VERSION),v$(DVTM_VERSION))
	$(call EXTRACT_TAR,dvtm-$(DVTM_VERSION).tar.gz,dvtm-$(DVTM_VERSION),dvtm)

ifneq ($(wildcard $(BUILD_WORK)/dvtm/.build_complete),)
dvtm:
	@echo "Using previously built dvtm."
else
dvtm: dvtm-setup ncurses
	+$(MAKE) -C $(BUILD_WORK)/dvtm install \
		CC=$(CC) \
		CFLAGS="$(CFLAGS) -DVERSION=\'$(DVTM_VERSION)\'" \
		MAMPREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		DESTDIR=$(BUILD_STAGE)/dvtm
	touch $(BUILD_WORK)/dvtm/.build_complete
endif

dvtm-package: dvtm-stage
	# dvtm.mk Package Structure
	rm -rf $(BUILD_DIST)/dvtm
	cp -a $(BUILD_STAGE)/dvtm $(BUILD_DIST)

	# dvtm.mk Sign
	$(call SIGN,dvtm,general.xml)

	# dvtm.mk Make .debs
	$(call PACK,dvtm,DEB_DVTM_V)

	# dvtm.mk Build Cleanup
	rm -rf $(BUILD_DIST)/dvtm

.PHONY: dvtm dvtm-package
