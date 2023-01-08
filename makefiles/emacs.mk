ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += emacs
EMACS_VERSION := 28.2
DEB_EMACS_V   ?= $(EMACS_VERSION)

emacs-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://ftpmirror.gnu.org/emacs/emacs-$(EMACS_VERSION).tar.xz{$(comma).sig})
	$(call PGP_VERIFY,emacs-$(EMACS_VERSION).tar.xz)
	$(call EXTRACT_TAR,emacs-$(EMACS_VERSION).tar.xz,emacs-$(EMACS_VERSION),emacs)
	mkdir -p $(BUILD_WORK)/emacs/native-build

ifneq ($(wildcard $(BUILD_WORK)/emacs/.build_complete),)
emacs:
	@echo "Using previously built emacs."
else
emacs: emacs-setup libx11 libxau libxmu libxpm libpng16 libgif libtiff xorgproto xxhash
	cd $(BUILD_WORK)/emacs/native-build && ../configure \
		$(BUILD_CONFIGURE_FLAGS) \
		--without-x \
		--without-ns \
		--without-dbus \
		--with-modules \
		--without-gnutls
	+$(MAKE) -C $(BUILD_WORK)/emacs/native-build
	cd $(BUILD_WORK)/emacs && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--without-ns \
		--with-modules \
		--without-dbus \
		--with-xpn=yes \
		--with-png=yes \
		--with-gif=yes \
		--without-jpeg \
		--with-tiff=yes \
		--with-unexec=no \
		--without-gnutls \
		--without-makeinfo \
		--with-pdumper=yes \
		--with-dumping=none \
		--with-x-toolkit=no \
		--x-libraries="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib" \
		--x-includes="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include"
	+$(MAKE) -C $(BUILD_WORK)/emacs
	+$(MAKE) -C $(BUILD_WORK)/emacs install \
		DESTDIR="$(BUILD_STAGE)/emacs"
	$(call AFTER_BUILD)
endif

emacs-package: emacs-stage
	# emacs.mk Package Structure
	rm -rf $(BUILD_DIST)/emacs

	# emacs.mk Prep emacs
	cp -a $(BUILD_STAGE)/emacs $(BUILD_DIST)

	# emacs.mk Sign
	$(call SIGN,emacs,general.xml)

	# emacs.mk Make .debs
	$(call PACK,emacs,DEB_EMACS_V)

	# emacs.mk Build cleanup
	rm -rf $(BUILD_DIST)/emacs

.PHONY: emacs emacs-package
