ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += mesu
MESU_LIBS       := -framework CoreFoundation
MESU_COMMIT     := 016dc9af86726171c5415cea0907d77a762879521

# Don't change the version, just date and git hash
MESU_VERSION    := 1.0+git20210409.$(shell echo $(MESU_COMIT) | cut -c -7)
DEB_MESU_V      ?= $(MESU_VERSION)

mesu-setup: setup
	wget -q -P $(BUILD_SOURCE) https://github.com/Siguza/misc/raw/$(MESU_COMMIT)/mesu.c
	mv $(BUILD_SOURCE)/mesu.c $(BUILD_SOURCE)/mesu-$(MESU_COMMIT).c

	mkdir -p $(BUILD_WORK)/mesu
	cp $(BUILD_SOURCE)/mesu-$(MESU_COMMIT).c $(BUILD_WORK)/mesu
	mv $(BUILD_WORK)/mesu/mesu-$(MESU_COMMIT).c $(BUILD_WORK)/mesu/mesu.c

ifneq ($(wildcard $(BUILD_WORK)/mesu/.build_complete),)
mesu:
	@echo "Using previously built mesu."
else
mesu: mesu-setup
	mkdir -p $(BUILD_STAGE)/mesu/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	# Actually compile mesu
	$(CC) $(CFLAGS) \
		$(BUILD_WORK)/mesu/mesu.c \
		-o $(BUILD_STAGE)/mesu/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/mesu $(LDFLAGS) $(MESU_LIBS)
	
	chmod +x $(BUILD_STAGE)/mesu/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/mesu
	touch $(BUILD_WORK)/mesu/.build_complete 
endif

mesu-package: mesu-stage
	# mesu.mk Package Structure and Prep
	rm -rf $(BUILD_DIST)/mesu
	cp -a $(BUILD_STAGE)/mesu $(BUILD_DIST)

	# mesu.mk Sign
	$(call SIGN,mesu,general.xml)

	# mesu.mk Make .debs
	$(call PACK,mesu,DEB_MESU_V)

	# mesu.mk Build cleanup
	rm -rf $(BUILD_DIST)/mesu

.PHONY: mesu mesu-package
