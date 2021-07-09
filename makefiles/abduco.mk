ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += abduco
ABDUCO_COMMIT  := fcac3b17edcb7cd7c22305bd5c519f9cd7e6c1de
ABDUCO_VERSION := 0.6.$(shell echo $(ABDUCO_COMMIT) | cut -c -7)
DEB_ABDUCO_V   ?= $(ABDUCO_VERSION)

abduco-setup: setup
	# Download commit that actually builds (maybe?)
	# Change this until (possible) next release tag
	$(call GITHUB_ARCHIVE,martanne,abduco,$(ABDUCO_COMMIT),$(ABDUCO_COMMIT))
	$(call EXTRACT_TAR,abduco-$(ABDUCO_COMMIT).tar.gz,abduco-$(ABDUCO_COMMIT),abduco)

ifneq ($(wildcard $(BUILD_WORK)/abduco/.build_complete),)
abduco:
	@echo "Using previously built abduco."
else
abduco: abduco-setup
	cd $(BUILD_WORK)/abduco && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/abduco
	+$(MAKE) -C $(BUILD_WORK)/abduco install \
		CC="$(CC)" \
		CFLAGS="$(CFLAGS)" \
		LDFLAGS="$(LDFLAGS)" \
		PREFIX="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		DESTDIR="$(BUILD_STAGE)/abduco"
	touch $(BUILD_WORK)/abduco/.build_complete
endif

abduco-package: abduco-stage
	# abduco.mk Package Structure
	cp -a $(BUILD_STAGE)/abduco $(BUILD_DIST)

	# abduco.mk Sign
	$(call SIGN,abduco,general.xml)

	# abduco.mk Make .debs
	$(call PACK,abduco,DEB_ABDUCO_V)

	# abduco.mk Build Cleanup
	rm -rf $(BUILD_DIST)/abduco

.PHONY: abduco abduco-package
