ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += radare2
RADARE2_VERSION := 5.8.2
RADARE2_API_V   := 5.8
DEB_RADARE2_V   ?= $(RADARE2_VERSION)-1

radare2-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://github.com/radareorg/radare2/releases/download/$(RADARE2_VERSION)/radare2-$(RADARE2_VERSION).tar.xz)
	$(call EXTRACT_TAR,radare2-$(RADARE2_VERSION).tar.xz,radare2-$(RADARE2_VERSION),radare2)
	$(call DO_PATCH,radare2,radare2,-p1)
#	Only God knows why this isn't in the original Makefile...
	sed -i "s|LDFLAGS+=\$$(SHLR)/grub/libgrubfs.a|LDFLAGS+=\$$(SHLR)/grub/libgrubfs.a -lzip|" $(BUILD_WORK)/radare2/libr/fs/Makefile

ifneq ($(wildcard $(BUILD_WORK)/radare2/.build_complete),)
radare2:
	@echo "Using previously built radare2."
else
radare2: radare2-setup capstone libuv1 libzip openssl xxhash lz4 file
	cd $(BUILD_WORK)/radare2 && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-ssl \
		--with-syszip \
		--with-syslz4 \
		--with-sysxxhash \
		--with-sysmagic \
		--with-syscapstone \
		--with-libuv \
		PKGCONFIG="$(BUILD_TOOLS)/cross-pkg-config"
	+$(MAKE) -C $(BUILD_WORK)/radare2 \
		HAVE_LIBVERSION=1
	+$(MAKE) -C $(BUILD_WORK)/radare2 install \
		DESTDIR="$(BUILD_STAGE)/radare2"
	rm -f $(BUILD_STAGE)/radare2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,share}/radare2/last
	$(call AFTER_BUILD,copy)
endif

radare2-package: .SHELLFLAGS=-O extglob -c
radare2-package: radare2-stage
	# radare2.mk Package Structure
	rm -rf $(BUILD_DIST)/{lib,}radare2{,-$(RADARE2_API_V),-common,-dev}
	mkdir -p $(BUILD_DIST)/radare2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share \
		$(BUILD_DIST)/libradare2-$(RADARE2_API_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libradare2-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,share} \
		$(BUILD_DIST)/libradare2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# radare2.mk Prep radare2
	cp -a $(BUILD_STAGE)/radare2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/radare2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/radare2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man $(BUILD_DIST)/radare2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# radare2.mk Prep libradare2-$(RADARE2_API_V)
	cp -a $(BUILD_STAGE)/radare2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/*$(RADARE2_API_V)*.dylib $(BUILD_DIST)/libradare2-$(RADARE2_API_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/radare2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/radare2 $(BUILD_DIST)/libradare2-$(RADARE2_API_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# radare2.mk Prep libradare2-common
	cp -a $(BUILD_STAGE)/radare2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/radare2 $(BUILD_DIST)/libradare2-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# radare2.mk Prep libradare2-dev
	cp -a $(BUILD_STAGE)/radare2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libradare2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/radare2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(*$(RADARE2_API_V)*|radare2) $(BUILD_DIST)/libradare2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# radare2.mk Sign
	$(call SIGN,radare2,general.xml)
	$(call SIGN,libradare2-$(RADARE2_API_V),general.xml)

	# radare2.mk Make .debs
	$(call PACK,radare2,DEB_RADARE2_V)
	$(call PACK,libradare2-$(RADARE2_API_V),DEB_RADARE2_V)
	$(call PACK,libradare2-common,DEB_RADARE2_V)
	$(call PACK,libradare2-dev,DEB_RADARE2_V)

	# radare2.mk Build cleanup
	rm -rf $(BUILD_DIST)/{lib,}radare2{,-$(RADARE2_API_V),-common,-dev}

.PHONY: radare2 radare2-package
