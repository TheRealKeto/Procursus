ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += pinentry
PINENTRY_VERSION := 1.1.1.1
DEB_PINENTRY_V   ?= $(PINENTRY_VERSION)

pinentry-setup: setup
	$(call GITHUB_ARCHIVE,GPGTools,pinentry,$(PINENTRY_VERSION),v$(PINENTRY_VERSION))
	$(call EXTRACT_TAR,pinentry-$(PINENTRY_VERSION).tar.gz,pinentry-$(PINENTRY_VERSION),pinentry)
	mkdir -p $(BUILD_STAGE)/pinentry/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/Applications

ifneq ($(wildcard $(BUILD_WORK)/pinentry/.build_complete),)
pinentry:
	@echo "Using previously built pinentry."
else
pinentry: pinentry-setup libgpg-error libassuan ncurses
	cd $(BUILD_WORK)/pinentry && autoreconf -fiv
	cd $(BUILD_WORK)/pinentry && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-libassuan-prefix=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--with-libgpg-error-prefix=$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--enable-pinentry-tty \
		--enable-pinentry-ncurses \
		--enable-maintainer-mode \
		NCURSES_CFLAGS="-DNCURSES_WIDECHAR"
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
	sed -i "421s|.*|pinentry_macosx = macosx|" $(BUILD_WORK)/pinentry/Makefile
endif
	+$(MAKE) -C $(BUILD_WORK)/pinentry
	+$(MAKE) -C $(BUILD_WORK)/pinentry install \
		DESTDIR="$(BUILD_STAGE)/pinentry"
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
	cp -a $(BUILD_WORK)/pinentry/macosx/pinentry-mac.app $(BUILD_STAGE)/pinentry/$(MEMO_PREFIX)/libexec/Applications
	$(INSTALL) -Dm755 $(BUILD_MISC)/pinentry/pinentry-mac $(BUILD_STAGE)/pinentry/$(MEMO_PREFIX)/bin
	sed -i "s|@MEMO_PREFIX@|$(MEMO_PREFIX)|g" $(BUILD_STAGE)/pinentry/$(MEMO_PREFIX)/bin/pinentry-mac
endif
	$(call AFTER_BUILD)
endif

pinentry-package: pinentry-stage
	# pinentry.mk Package Structure
	rm -rf $(BUILD_DIST)/pinentry

	# pinentry.mk Prep pinentry
	cp -a $(BUILD_STAGE)/pinentry $(BUILD_DIST)/

	# pinentry.mk Sign
	$(call SIGN,pinentry,general.xml)

	# pinentry.mk Make .debs
	$(call PACK,pinentry,DEB_PINENTRY_V)

	# pinentry.mk Build cleanup
	rm -rf $(BUILD_DIST)/pinentry

.PHONY: pinentry pinentry-package
