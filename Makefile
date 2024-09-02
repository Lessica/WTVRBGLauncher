export PACKAGE_VERSION := 1.1

ARCHS := arm64 arm64e
TARGET := iphone:clang:16.5:14.0
INSTALL_TARGET_PROCESSES := SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := WTVRBGLauncher

WTVRBGLauncher_FILES += WTVRBGLauncher.x
WTVRBGLauncher_CFLAGS += -fobjc-arc
WTVRBGLauncher_CFLAGS += -Wno-unused-variable
WTVRBGLauncher_CFLAGS += -Wno-unused-function

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += WTVRBGPrefs

include $(THEOS_MAKE_PATH)/aggregate.mk