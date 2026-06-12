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
NewTerm_LDFLAGS := -Wl,-sectcreate,__TEXT,__info_plist,NewTerm-Info.plist

include $(THEOS_MAKE_PATH)/application.mk
