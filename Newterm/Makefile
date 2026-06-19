ARCHS = armv7 armv7s
TARGET = iphone:6.0:4.0

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = NewTerm
Newterm_FILES = $(wildcard *.m)
Newterm_FRAMEWORKS = AudioToolbox CoreGraphics CoreText UIKit
Newterm_LIBRARIES = util
Newterm_LDFLAGS = -lSystem_syms
Newterm_RESOURCE_FILES = Info.plist Icon-72.png Icon-72@2x.png
ADDITIONAL_OBJCFLAGS = -fno-objc-arc -include MTerminal_Prefix.pch -Wno-single-bit-bitfield-constant-conversion

include $(THEOS_MAKE_PATH)/application.mk