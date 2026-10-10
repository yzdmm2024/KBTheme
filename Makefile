# KBTheme — rootless 越狱 tweak + 设置面板（iOS 16，Relaxin / RootHide）
# 构建：make package（macOS + theos）；CI 走 .github/workflows/build.yml
# 面板：设置 → 原生输入法增强

TARGET := iphone:clang:14.5:14.0
ARCHS = arm64 arm64e
THEOS_PACKAGE_SCHEME = rootless
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = KBTheme
KBTheme_FILES = src/Tweak.xm
KBTheme_CFLAGS = -fobjc-arc -fobjc-exceptions -Wno-deprecated-declarations -w
KBTheme_FRAMEWORKS = UIKit Foundation CoreGraphics

BUNDLE_NAME = KBThemePrefs
KBThemePrefs_FILES = Preferences/KBThemeCommon.m \
                     Preferences/KBThemeColorCell.m \
                     Preferences/KBThemeSettingsController.m \
                     Preferences/KBThemeLetterColors.m \
                     Preferences/KBThemePhotoController.m
KBThemePrefs_INSTALL_PATH = /Library/PreferenceBundles
KBThemePrefs_FRAMEWORKS = UIKit Foundation PhotosUI
KBThemePrefs_PRIVATE_FRAMEWORKS = Preferences
KBThemePrefs_LDFLAGS = -F$(TARGET_PRIVATE_FRAMEWORK_PATH)
KBThemePrefs_CFLAGS = -fobjc-arc -fobjc-exceptions -w

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/bundle.mk
