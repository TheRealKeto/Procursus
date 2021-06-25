ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += sapling
SAPLING_VERSION := 0.1.0
DEB_SAPLING_V   ?= $(SAPLING_VERSION)

sapling-setup: setup
	$(call GITHUB_ARCHIVE,kneasle,sapling,$(SAPLING_VERSION),master)
	$(call EXTRACT_TAR,sapling-$(SAPLING_VERSION).tar.gz,sapling-master,sapling)

ifneq ($(wildcard $(BUILD_WORK)/sapling/.build_complete),)
sapling:
	@echo "Using previously built sapling."
else
sapling: sapling-setup
	cd $(BUILD_WORK)/sapling && $(DEFAULT_RUST_FLAGS) cargo build \
		--release \
		--target=$(RUST_TARGET)
	$(GINSTALL) -Dm755 $(BUILD_WORK)/sapling/target/$(RUST_TARGET)/release/sapling \
		$(BUILD_STAGE)/sapling/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/sapling
	touch $(BUILD_WORK)/sapling/.build_complete
endif

sapling-package: sapling-stage
	# sapling.mk Package Structure
	mkdir -p $(BUILD_DIST)/sapling
	cp -a $(BUILD_STAGE)/sapling $(BUILD_DIST)

	# sapling.mk Sign
	$(call SIGN,sapling,general.xml)

	# sapling.mk Make .debs
	$(call PACK,sapling,DEB_SAPLING_V)

	# sapling.mk Build Cleanup
	rm -rf $(BUILD_DIST)/sapling

.PHONY: sapling sapling-package
