//
//  MarkdownParser.m
//  MarkdownKit
//

#import "MarkdownParser.h"
#import "MarkdownElement.h"
#import "MarkdownHeader.h"
#import "MarkdownList.h"
#import "MarkdownQuote.h"
#import "MarkdownCode.h"
#import "MarkdownLink.h"
#import "MarkdownImage.h"
#import "MarkdownHorizontalRule.h"
#import "NSString+Markdown.h"

@interface MarkdownParser ()

@property (nonatomic, strong) NSArray *blockElements;
@property (nonatomic, strong) NSArray *inlineElements;

@end

@implementation MarkdownParser

- (id)init {
    return [self initWithConfiguration:[MarkdownConfiguration defaultConfiguration]];
}

- (id)initWithConfiguration:(MarkdownConfiguration *)configuration {
    self = [super init];
    if (self) {
        _configuration = configuration;
        [self setupElements];
    }
    return self;
}

- (void)setupElements {
    // 块级元素
    self.blockElements = @[
        [[MarkdownHeader alloc] init],
        [[MarkdownList alloc] init],
        [[MarkdownQuote alloc] init],
        [[MarkdownCode alloc] init],
        [[MarkdownHorizontalRule alloc] init]
    ];
    
    // 内联元素（注意顺序：先处理链接和图片）
    self.inlineElements = @[
        [[MarkdownImage alloc] init],
        [[MarkdownLink alloc] init]
    ];
}

- (NSAttributedString *)parse:(NSString *)markdown {
    if (!markdown) return [[NSAttributedString alloc] initWithString:@""];
    
    // 1. 先处理块级元素
    NSArray *lines = [markdown componentsSeparatedByString:@"\n"];
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];
    
    NSInteger i = 0;
    while (i < lines.count) {
        NSString *line = lines[i];
        
        BOOL handled = NO;
        for (id<MarkdownElement> element in self.blockElements) {
            if ([element canHandleLine:line]) {
                NSAttributedString *parsed = [element parseLines:lines atIndex:i];
                if (parsed) {
                    [result appendAttributedString:parsed];
                    // 跳转行数
                    i += [element numberOfLinesToSkip:lines atIndex:i];
                    handled = YES;
                    break;
                }
            }
        }
        
        if (!handled) {
            // 普通段落
            NSAttributedString *paragraph = [self parseParagraph:line];
            [result appendAttributedString:paragraph];
            if (i < lines.count - 1) {
                [result appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            }
            i++;
        }
    }
    
    return result;
}

- (NSAttributedString *)parseParagraph:(NSString *)line {
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:line];
    
    // 默认样式
    [attrString addAttribute:NSFontAttributeName
                       value:self.configuration.defaultFont
                       range:NSMakeRange(0, line.length)];
    [attrString addAttribute:NSForegroundColorAttributeName
                       value:self.configuration.defaultColor
                       range:NSMakeRange(0, line.length)];
    
    // 处理内联元素
    for (id<MarkdownElement> element in self.inlineElements) {
        attrString = [element parseInline:attrString withConfiguration:self.configuration];
    }
    
    // 处理 **粗体**
    [self applyAttribute:NSFontAttributeName
                  value:[UIFont boldSystemFontOfSize:self.configuration.defaultFont.pointSize]
           matchingPattern:@"\\*\\*([^*]+)\\*\\*"
       toAttributedString:attrString];

    // 处理 __粗体__
    [self applyAttribute:NSFontAttributeName
                  value:[UIFont boldSystemFontOfSize:self.configuration.defaultFont.pointSize]
           matchingPattern:@"__([^_]+)__"
       toAttributedString:attrString];

    // 处理 *斜体*
    [self applyAttribute:NSFontAttributeName
                  value:[UIFont italicSystemFontOfSize:self.configuration.defaultFont.pointSize]
           matchingPattern:@"\\*(?!\\*)([^*]+)\\*(?!\\*)"
       toAttributedString:attrString];

    // 处理 `行内代码`
    UIFont *codeFont = [UIFont fontWithName:@"Courier" size:self.configuration.defaultFont.pointSize];
    if (!codeFont) codeFont = [UIFont systemFontOfSize:self.configuration.defaultFont.pointSize];
    [self applyAttribute:NSFontAttributeName
                  value:codeFont
           matchingPattern:@"`([^`]+)`"
       toAttributedString:attrString];
    
    return attrString;
}

- (void)applyAttribute:(NSString *)attribute
                value:(id)value
     matchingPattern:(NSString *)pattern
 toAttributedString:(NSMutableAttributedString *)attrString {
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:0
                                                                             error:&error];
    if (error) return;
    
    NSString *string = attrString.string;
    NSArray *matches = [regex matchesInString:string
                                      options:0
                                        range:NSMakeRange(0, string.length)];
    
    for (NSInteger i = matches.count - 1; i >= 0; i--) {
        NSTextCheckingResult *match = matches[i];
        if (match.numberOfRanges < 2) continue;
        
        NSRange contentRange = [match rangeAtIndex:1];
        NSString *content = [string substringWithRange:contentRange];
        
        NSMutableAttributedString *replacement = [[NSMutableAttributedString alloc] initWithString:content];
        [replacement addAttribute:attribute value:value range:NSMakeRange(0, content.length)];
        
        UIColor *color = [attrString attribute:NSForegroundColorAttributeName
                                       atIndex:match.range.location
                                effectiveRange:NULL];
        if (color) {
            [replacement addAttribute:NSForegroundColorAttributeName
                                value:color
                                range:NSMakeRange(0, content.length)];
        }
        
        [attrString replaceCharactersInRange:match.range
                        withAttributedString:replacement];
        [replacement release];
    }
}

@end