export TARGET := iphone:6.0:6.0
export ARCHS := armv7 armv7s
INSTALL_TARGET_PROCESSES := NewTerm

export THEOS_MAKE_PATH := $(THEOS)/makefiles

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME := NewTerm

# 自动识别当前目录所有 .m 文件
NewTerm_FILES := $(wildcard *.m)

NewTerm_FRAMEWORKS := UIKit Foundation CoreGraphics
NewTerm_CFLAGS := -fobjc-arc
NewTerm_CODESIGN_FLAGS := -S
NewTerm_RESOURCE_FILES := icon.png Icon.png Icon@2x.png Icon-72.png Icon-72@2x.png Info.plist

include $(THEOS_MAKE_PATH)/application.mk