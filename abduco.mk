ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += abduco
ABDUCO_VERSION := 0.6
DEB_ABDUCO_V   ?= $(ABDUCO_VERSION)

abduco-setup: setup
	$(call GITHUB_ARCHIVE,martanne,abduco,$(ABDUCO_VERSION),master)
	$(call EXTRACT_TAR,abduco-$(ABDUCO_VERSION).tar.gz,abduco-master,abduco)

ifneq ($(wildcard $(BUILD_WORK)/abduco/.build_complete),)
abduco:
	@echo "Using previously built abduco."
else
abduco: abduco-setup
	# Patch configure script options
	$(SED) -i "211,212d" $(BUILD_WORK)/abduco/configure
	cd $(BUILD_WORK)/abduco && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/abduco
	+$(MAKE) -C $(BUILD_WORK)/abduco install \
		CC=$(CC) \
		CFLAGS=$(CFLAGS) \
		LDFLAGS=$(LDFLAGS) \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		DESTDIR=$(BUILD_STAGE)/abduco
	touch $(BUILD_WORK)/abduco/.build_complete
endif

abduco-package: abduco-stage
	# abduco.mk Package Structure
	mkdir -p $(BUILD_DIST)/abduco
	cp -a $(BUILD_STAGE)/abduco $(BUILD_DIST)

	# abduco.mk Sign
	$(call SIGN,abduco,general.xml)

	# abduco.mk Make .debs
	$(call PACK,abduco,DEB_ABDUCO_V)

	# abduco.mk Build Cleanup
	rm -rf $(BUILD_DIST)/abduco

.PHONY: abduco abduco-package
