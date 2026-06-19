ARCHS = armv7 armv7s
TARGET = iphone:6.0:4.0

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = Newterm

# 所有 .m 文件
Newterm_FILES = $(wildcard *.m)

# MarkdownKit 文件单独开启 ARC
MarkdownParser.m_CFLAGS = -fobjc-arc
MarkdownConfiguration.m_CFLAGS = -fobjc-arc
MarkdownElement.m_CFLAGS = -fobjc-arc
MarkdownHeader.m_CFLAGS = -fobjc-arc
MarkdownList.m_CFLAGS = -fobjc-arc
MarkdownQuote.m_CFLAGS = -fobjc-arc
MarkdownCode.m_CFLAGS = -fobjc-arc
MarkdownLink.m_CFLAGS = -fobjc-arc
MarkdownImage.m_CFLAGS = -fobjc-arc
MarkdownHorizontalRule.m_CFLAGS = -fobjc-arc
NSString+Markdown.m_CFLAGS = -fobjc-arc

Newterm_FRAMEWORKS = AudioToolbox CoreGraphics CoreText UIKit QuartzCore CoreFoundation
Newterm_LIBRARIES = util
Newterm_LDFLAGS = -lSystem_syms
Newterm_RESOURCE_FILES = Info.plist Icon-72.png Icon-72@2x.png

# 全局 MRC，MarkdownKit 文件通过上面的 _CFLAGS 覆盖为 ARC
ADDITIONAL_OBJCFLAGS = -fno-objc-arc -include MTerminal_Prefix.pch -Wno-single-bit-bitfield-constant-conversion

include $(THEOS_MAKE_PATH)/application.mk