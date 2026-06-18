ARCHS = armv7 armv7s
TARGET = iphone:latest:4.0

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = MTerminal
MTerminal_FILES = $(wildcard *.m)
MTerminal_FRAMEWORKS = AudioToolbox CoreGraphics CoreText UIKit
ADDITIONAL_OBJCFLAGS = -fno-objc-arc -include MTerminal_Prefix.pch

include $(THEOS_MAKE_PATH)/application.mk
