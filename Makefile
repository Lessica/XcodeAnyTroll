export PACKAGE_VERSION := 1.1.1

ARCHS := arm64 arm64e
ifeq ($(THEOS_PACKAGE_SCHEME),)
TARGET := iphone:clang:14.5:14.0
else
TARGET := iphone:clang:16.5:15.0
endif

ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
JBROOT_PREFIX := /var/jb
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := XcodeAnyTroll

XcodeAnyTroll_FILES += XcodeAnyTroll.xm

XcodeAnyTroll_CFLAGS += -fobjc-arc
XcodeAnyTroll_CFLAGS += -IHeaders
XcodeAnyTroll_CFLAGS += -FFrameworks

XcodeAnyTroll_LDFLAGS += -FFrameworks

XcodeAnyTroll_LIBRARIES += iconv
XcodeAnyTroll_LIBRARIES += SandyXpc

XcodeAnyTroll_FRAMEWORKS += Foundation
XcodeAnyTroll_FRAMEWORKS += SSZipArchive

XcodeAnyTroll_PRIVATE_FRAMEWORKS += MobileContainerManager
XcodeAnyTroll_PRIVATE_FRAMEWORKS += MobileCoreServices

include $(THEOS_MAKE_PATH)/tweak.mk

TOOL_NAME := trollinstalld

trollinstalld_ARCHS := arm64
trollinstalld_FILES := trollinstalld.mm

trollinstalld_CFLAGS += -fobjc-arc
trollinstalld_CFLAGS += -IHeaders

trollinstalld_CODESIGN_FLAGS += -Sentitlements.plist

trollinstalld_LIBRARIES += SandyXpc

trollinstalld_FRAMEWORKS += Foundation

trollinstalld_PRIVATE_FRAMEWORKS += MobileContainerManager
trollinstalld_PRIVATE_FRAMEWORKS += MobileCoreServices

include $(THEOS_MAKE_PATH)/tool.mk

before-package::
	$(ECHO_NOTHING)defaults write $(THEOS_STAGING_DIR)/Library/LaunchDaemons/com.82flex.trollinstalld.plist Program "$(JBROOT_PREFIX)/usr/bin/trollinstalld"$(ECHO_END)
	$(ECHO_NOTHING)plutil -convert xml1 $(THEOS_STAGING_DIR)/Library/LaunchDaemons/com.82flex.trollinstalld.plist$(ECHO_END)
