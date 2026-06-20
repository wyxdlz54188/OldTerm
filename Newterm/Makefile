ARCHS = armv7 armv7s
TARGET = iphone:6.0:4.0

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = Newterm

# 所有 .m 文件（含子目录）
Newterm_FILES = $(wildcard *.m) $(wildcard Core/*.m) $(wildcard Elements/*.m) $(wildcard Extensions/*.m)

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

stage::
	$(ECHO_NOTHING)mkdir -p "$(THEOS_STAGING_DIR)/Applications/Newterm.app/assets"$(ECHO_END)
	$(ECHO_NOTHING)cp assets/tab_settings.png "$(THEOS_STAGING_DIR)/Applications/Newterm.app/assets/tab_settings.png"$(ECHO_END)

# 全局 MRC，MarkdownKit 文件通过上面的 _CFLAGS 覆盖为 ARC
ADDITIONAL_OBJCFLAGS = -fno-objc-arc -include MTerminal_Prefix.pch -Wno-single-bit-bitfield-constant-conversion -I./Core -I./Elements -I./Extensions

include $(THEOS_MAKE_PATH)/application.mk