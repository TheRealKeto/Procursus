ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += procs
PROCS_VERSION := 0.11.9
DEB_PROCS_V   ?= $(PROCS_VERSION)

procs-setup: setup
	$(call GITHUB_ARCHIVE,dalance,procs,$(PROCS_VERSION),v$(PROCS_VERSION))
	$(call EXTRACT_TAR,procs-$(PROCS_VERSION).tar.gz,procs-$(PROCS_VERSION),procs)

ifneq ($(wildcard $(BUILD_WORK)/procs/.build_complete),)
procs:
	@echo "Using previously built procs."
else
procs: procs-setup
	cd $(BUILD_WORK)/procs; $(DEFAULT_RUST_FLAGS) cargo build \
		--release \
		--target=$(RUST_TARGET)
	$(INSTALL) -Dm755 $(BUILD_WORK)/procs/target/$(RUST_TARGET)/release/procs \
		$(BUILD_STAGE)/procs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/procs
	touch $(BUILD_WORK)/procs/.build_complete
endif

procs-package: procs-stage
	# procs.mk Package Structure
	rm -rf $(BUILD_DIST)/procs
	cp -a $(BUILD_STAGE)/procs $(BUILD_DIST)

	# procs.mk Sign
	$(call SIGN,procs,general.xml)

	# procs.mk Make .debs
	$(call PACK,procs,DEB_PROCS_V)

	# procs.mk Build Cleanup
	rm -rf $(BUILD_DIST)/procs

.PHONY: procs procs-package
