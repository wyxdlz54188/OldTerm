ARCHS = armv7 armv7s
TARGET = iphone:6.0:4.0

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = MTerminal
MTerminal_FILES = $(wildcard *.m)
MTerminal_FRAMEWORKS = AudioToolbox CoreGraphics CoreText UIKit
MTerminal_LIBRARIES = util
MTerminal_LDFLAGS = $(SYSROOT)/usr/lib/system/libsystem_c.dylib $(SYSROOT)/usr/lib/system/libsystem_kernel.dylib
ADDITIONAL_OBJCFLAGS = -fno-objc-arc -include MTerminal_Prefix.pch -Wno-single-bit-bitfield-constant-conversion

include $(THEOS_MAKE_PATH)/application.mk
