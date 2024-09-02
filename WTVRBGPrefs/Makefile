TARGET := iphone:clang:16.5:14.0
INSTALL_TARGET_PROCESSES := Preferences

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME := WTVRBGPrefs

WTVRBGPrefs_FILES += WTVRBGRootListController.m
WTVRBGPrefs_CFLAGS += -fobjc-arc

WTVRBGPrefs_FRAMEWORKS += UIKit
WTVRBGPrefs_PRIVATE_FRAMEWORKS += CoreServices
WTVRBGPrefs_PRIVATE_FRAMEWORKS += Preferences
WTVRBGPrefs_INSTALL_PATH += /Library/PreferenceBundles

include $(THEOS_MAKE_PATH)/bundle.mk