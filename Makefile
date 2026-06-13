export TARGET := iphone:6.0:6.0
export ARCHS := armv7 armv7s
INSTALL_TARGET_PROCESSES := NewTerm

export THEOS_MAKE_PATH := $(THEOS)/makefiles

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME := NewTerm

NewTerm_FILES := \
  main.m \
  NewTermAppDelegate.m \
  TermViewController.m \
  TermView.m \
  SessionManager.m \
  VT100Parser.m \
  PtySession.m

NewTerm_FRAMEWORKS := UIKit Foundation CoreGraphics
NewTerm_CFLAGS := -fobjc-arc

# 显式把 Info.plist 和图标加到资源文件里
NewTerm_RESOURCE_FILES := icon.png Icon.png Icon@2x.png Icon-72.png Icon-72@2x.png NewTerm-Info.plist

include $(THEOS_MAKE_PATH)/application.mk