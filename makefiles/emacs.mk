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
	sed -e "71d" -i $(BUILD_WORK)/emacs/nextstep/Makefile.in
	sed -e "250s|/.*|/lisp:../lisp|" -i $(BUILD_WORK)/emacs/Makefile.in
	mkdir -p $(BUILD_WORK)/emacs/native-build

ifneq ($(wildcard $(BUILD_WORK)/emacs/.build_complete),)
emacs:
	@echo "Using previously built emacs."
else
emacs: emacs-setup jansson gnutls ncurses libxml2 libx11 libxau libxmu libxpm libpng16 libgif libtiff lcms2 xorgproto xxhash
	cd $(BUILD_WORK)/emacs/native-build && ../configure \
		$(BUILD_CONFIGURE_FLAGS) \
		--without-x \
		--without-ns \
		--without-dbus \
		--with-modules \
		--without-gnutls
	+$(MAKE) -C $(BUILD_WORK)/emacs/native-build
	sed -e "s|-lncurses|-lncursesw|g" -i $(BUILD_WORK)/emacs/configure
	sed -e "50s|/.*|/native-build/lib-src|" -i $(BUILD_WORK)/emacs/src/Makefile.in
	cd $(BUILD_WORK)/emacs && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-xpn \
		--with-png \
		--with-gif \
		--with-tiff \
		--with-json \
		--without-ns \
		--without-pop \
		--with-modules \
		--without-dbus \
		--without-jpeg \
		--without-rsvg \
		--with-pdumper \
		--without-cairo \
		--without-gnutls \
		--with-unexec=no \
		--with-dumping=none \
		--with-x-toolkit=no \
		--without-libsystemd \
		--without-compress-install \
		--x-libraries="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib" \
		--x-includes="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include" \
		LIBGNUTLS_LIBS="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libgnutls.dylib" \
		gl_cv_func_open_slash=no \
		gl_cv_func_working_utimes=yes \
		ac_cv_func_getgroups_works=yes \
		ac_cv_func_mmap_fixed_mapped=yes \
		fu_cv_sys_stat_statfs2_bsize=yes \
		gl_cv_func_gettimeofday_clobbe=no
	+$(MAKE) -C $(BUILD_WORK)/emacs
	+$(MAKE) -C $(BUILD_WORK)/emacs install \
		DESTDIR="$(BUILD_STAGE)/emacs"
	$(call AFTER_BUILD)
endif

emacs-package: emacs-stage
	# emacs.mk Package Structure
	rm -rf $(BUILD_DIST)/emacs{,-el,{,-bin}-common}
	mkdir -p $(BUILD_DIST)/emacs-bin-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		$(BUILD_DIST)/emacs-{el,common}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/emacs/$(EMACS_VERSION) \
		$(BUILD_DIST)/emacs-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include

	# emacs.mk Prep emacs-bin-common
	cp -a $(BUILD_STAGE)/emacs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,libexec} $(BUILD_DIST)/emacs-bin-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/

	# emacs.mk Prep emacs-common
	cp -a $(BUILD_STAGE)/emacs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/emacs-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/
	cp -a $(BUILD_STAGE)/emacs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{man,applications,icons,metainfo} $(BUILD_DIST)/emacs-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/
	cp -a $(BUILD_STAGE)/emacs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/emacs/$(EMACS_VERSION)/{etc,site-lisp} $(BUILD_DIST)/emacs-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/emacs/$(EMACS_VERSION)/
	$(LN_S) $(EMACS_VERSION)/site-lisp $(BUILD_DIST)/emacs-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/emacs/site-lisp

	# emacs.mk Prep emacs-el
	cp -a $(BUILD_STAGE)/emacs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/emacs/$(EMACS_VERSION)/lisp $(BUILD_DIST)/emacs-el/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/emacs/$(EMACS_VERSION)/

	# emacs.mk Sign
	$(call SIGN,emacs-bin-common,general.xml)

	# emacs.mk Make .debs
	$(call PACK,emacs,DEB_EMACS_V)
	$(call PACK,emacs-el,DEB_EMACS_V)
	$(call PACK,emacs-common,DEB_EMACS_V)
	$(call PACK,emacs-bin-common,DEB_EMACS_V)

	# emacs.mk Build cleanup
	rm -rf $(BUILD_DIST)/emacs{,-el,{,-bin}-common}

.PHONY: emacs emacs-package
