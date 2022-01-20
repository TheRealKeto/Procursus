ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += aspell
ASPELL_VERSION  := 0.60.8
ASPELL_DATE     := 2020.12.07-0

DEB_ASPELL_EN_V ?= $(ASPELL_DATE)
DEB_ASPELL_V    ?= $(ASPELL_VERSION)

aspell-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftp.gnu.org/gnu/aspell/aspell-$(ASPELL_VERSION).tar.gz{,.sig}
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/aspell/dict/en/aspell6-en-$(ASPELL_DATE).tar.bz2{,.sig}
	$(call PGP_VERIFY,aspell-$(ASPELL_VERSION).tar.gz)
	$(call PGP_VERIFY,aspell6-en-$(ASPELL_DATE).tar.bz2)
	$(call EXTRACT_TAR,aspell6-en-$(ASPELL_DATE).tar.bz2,aspell6-en-$(aspell6),aspell-en)
	$(call EXTRACT_TAR,aspell-$(ASPELL_VERSION).tar.gz,aspell-$(ASPELL_VERSION),aspell)

ifneq ($(wildcard $(BUILD_WORK)/aspell/.build_complete),)
aspell:
	@echo "Using previously built aspell."
else
aspell: aspell-setup ncurses
	cd $(BUILD_WORK)/aspell-en && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/aspell-en
	+$(MAKE) -C $(BUILD_WORK)/aspell-en install \
		DESTDIR="$(BUILD_STAGE)/aspell-en"
	cd $(BUILD_WORK)/aspell && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--lang=en \
		--disable-rpath
	+$(MAKE) -C $(BUILD_WORK)/aspell
	+$(MAKE) -C $(BUILD_WORK)/aspell install \
		DESTDIR=$(BUILD_STAGE)/aspell
	$(call AFTER_BUILD,copy)
endif

aspell-package: aspell-stage
	# aspell.mk Package Structure
	rm -rf $(BUILD_DIST)/{aspell,libaspell-dev,libaspell15,libpspell-dev}
	mkdir -p $(BUILD_DIST)/aspell/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin \
		$(BUILD_DIST)/libaspell-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,include} \
		$(BUILD_DIST)/libaspell15/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/aspell-0.60} \
		$(BUILD_DIST)/libpspell-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,include/pspell,bin}

	# aspell.mk Prep aspell
	cp -a $(BUILD_STAGE)/aspell/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/!(pspell-config) \
		$(BUILD_DIST)/aspell/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# aspell.mk Prep aspell-dev
	cp -a $(BUILD_STAGE)/aspell/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/aspell.h \
		$(BUILD_DIST)/libaspell-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/aspell/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libaspell.la \
		$(BUILD_DIST)/libaspell-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# aspell.mk Prep libaspell15
	cp -a $(BUILD_STAGE)/aspell/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/aspell-0.60 \
		$(BUILD_DIST)/libaspell15/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/aspell-0.60
	cp -a $(BUILD_STAGE)/aspell/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libaspell.dylib,libaspell.15.dylib} \
		$(BUILD_DIST)/libaspell15/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# aspell.mk Prep libpspell-dev
	cp -a $(BUILD_STAGE)/aspell/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/pspell/pspell.h \
		$(BUILD_DIST)/libpspell-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/aspell/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pspell-config \
		$(BUILD_DIST)/libpspell-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/aspell/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libpspell.la,libpspell.dylib,libpspell.15.dylib} \
		$(BUILD_DIST)/libpspell-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# aspell Dictionary Prep
	rm -rf $(BUILD_DIST)/aspell-en
	cp -a $(BUILD_STAGE)/aspell-en $(BUILD_DIST)

	# aspell.mk Sign
	$(call SIGN,aspell,general.xml)
	$(call SIGN,libaspell-dev,general.xml)
	$(call SIGN,libaspell15,general.xml)
	$(call SIGN,libpspell-dev,general.xml)

	# aspell.mk Make .debs
	$(call PACK,aspell,DEB_ASPELL_V)
	$(call PACK,libaspell-dev,DEB_ASPELL_V)
	$(call PACK,libaspell15,DEB_ASPELL_V)
	$(call PACK,libpspell-dev,DEB_ASPELL_V)
	$(call PACK,aspell-en,DEB_ASPELL_EN_V)

	# aspell.mk Build cleanup
	rm -rf $(BUILD_DIST)/aspell-en
	rm -rf $(BUILD_DIST)/{aspell,libaspell-dev,libaspell15,libpspell-dev}

.PHONY: aspell aspell-package
