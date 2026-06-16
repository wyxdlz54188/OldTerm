#import "RowView.h"
#import <CoreText/CoreText.h>

static UIColor *colorForIndex(int idx) {
    static UIColor *table[16];
    static BOOL inited = NO;
    if (!inited) {
        inited = YES;
        CGFloat vals[16][3] = {
            {0.00,0.00,0.00},{0.67,0.00,0.00},{0.00,0.67,0.00},{0.67,0.67,0.00},
            {0.00,0.00,0.67},{0.67,0.00,0.67},{0.00,0.67,0.67},{0.67,0.67,0.67},
            {0.33,0.33,0.33},{1.00,0.33,0.33},{0.33,1.00,0.33},{1.00,1.00,0.33},
            {0.33,0.33,1.00},{1.00,0.33,1.00},{0.33,1.00,1.00},{1.00,1.00,1.00},
        };
        for (int i = 0; i < 16; i++)
            table[i] = [[UIColor alloc] initWithRed:vals[i][0] green:vals[i][1] blue:vals[i][2] alpha:1];
    }
    return (idx >= 0 && idx < 16) ? table[idx] : nil;
}

@interface RowView () {
    CTLineRef _ctLine;
    CGFloat _lineAscent;
}
@end

@implementation RowView

@synthesize defaultColor = _defaultColor, charWidth = _charWidth;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _ctLine = NULL;
        _lineAscent = 0;
        _defaultColor = [UIColor greenColor];
        _charWidth = 0;
        self.opaque = YES;
        self.clearsContextBeforeDrawing = NO;
        self.backgroundColor = [UIColor blackColor];
    }
    return self;
}

- (void)renderLine:(NSString *)line {
    if (_ctLine) {
        CFRelease(_ctLine);
        _ctLine = NULL;
    }

    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:@""];
    UIColor *currentColor = _defaultColor;
    BOOL inEscape = NO;
    NSMutableString *escapeSeq = [[NSMutableString alloc] init];
    NSMutableString *textRun = [[NSMutableString alloc] init];

    void (^flushRun)(void) = ^{
        if ([textRun length] == 0) return;
        NSDictionary *attrs = @{
            (id)kCTForegroundColorAttributeName: (id)currentColor.CGColor,
        };
        NSAttributedString *runStr = [[NSAttributedString alloc] initWithString:textRun attributes:attrs];
        [attrStr appendAttributedString:runStr];
        [textRun setString:@""];
    };

    for (NSInteger i = 0; i < [line length]; i++) {
        unichar c = [line characterAtIndex:i];

        if (c == 0x1B) {
            flushRun();
            inEscape = YES;
            [escapeSeq setString:@""];
            continue;
        }

        if (inEscape) {
            if (c == '[' && [escapeSeq length] == 0) continue;
            if ((c >= 'A' && c <= 'Z') || c == '~' || c == 'm') {
                if (c == 'm') {
                    UIColor *newColor = [self colorFromSGR:escapeSeq defaultColor:_defaultColor];
                    if (newColor) currentColor = newColor;
                }
                inEscape = NO;
                continue;
            }
            [escapeSeq appendFormat:@"%C", c];
            continue;
        }

        [textRun appendFormat:@"%C", c];
    }

    flushRun();

    _ctLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)attrStr);

    CGFloat ascent, descent, leading;
    CTLineGetTypographicBounds(_ctLine, &ascent, &descent, &leading);
    _lineAscent = ascent;

    [self setNeedsDisplay];
}

- (UIColor *)colorFromSGR:(NSString *)code defaultColor:(UIColor *)defColor {
    NSArray *parts = [code componentsSeparatedByString:@";"];
    if ([parts count] == 0) return defColor;
    NSInteger p0 = [[parts objectAtIndex:0] integerValue];

    if ([parts count] >= 3 && p0 == 38 && [[parts objectAtIndex:1] integerValue] == 5) {
        return defColor;
    }
    if ([parts count] >= 5 && p0 == 38 && [[parts objectAtIndex:1] integerValue] == 2) {
        return defColor;
    }

    if ([code isEqualToString:@"0"] || [code isEqualToString:@""]) return defColor;
    if ([code isEqualToString:@"1"]) return defColor;

    switch (p0) {
        case 30: case 40: return colorForIndex(0);
        case 31: case 41: return colorForIndex(1);
        case 32: case 42: return colorForIndex(2);
        case 33: case 43: return colorForIndex(3);
        case 34: case 44: return colorForIndex(4);
        case 35: case 45: return colorForIndex(5);
        case 36: case 46: return colorForIndex(6);
        case 37: case 47: return colorForIndex(7);
        case 90: case 100: return colorForIndex(8);
        case 91: case 101: return colorForIndex(9);
        case 92: case 102: return colorForIndex(10);
        case 93: case 103: return colorForIndex(11);
        case 94: case 104: return colorForIndex(12);
        case 95: case 105: return colorForIndex(13);
        case 96: case 106: return colorForIndex(14);
        case 97: case 107: return colorForIndex(15);
    }
    return defColor;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;

    CGContextSetFillColorWithColor(ctx, self.backgroundColor.CGColor);
    CGContextFillRect(ctx, rect);

    if (!_ctLine) return;

    CGContextSetTextMatrix(ctx, CGAffineTransformMake(1, 0, 0, -1, 0, _lineAscent));
    CTLineDraw(_ctLine, ctx);
}

- (void)dealloc {
    if (_ctLine) CFRelease(_ctLine);
}

@end
