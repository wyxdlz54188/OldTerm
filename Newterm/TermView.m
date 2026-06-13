#import "TermView.h"
#import "SessionManager.h"

@implementation TermView

@synthesize sessionManager = _sessionManager, textColor = _textColor;
@synthesize backgroundColor = _backgroundColor, cursorVisible = _cursorVisible;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
        self.textColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
        
        CGFloat fontSize = [[NSUserDefaults standardUserDefaults] floatForKey:@"terminalFontSize"];
        if (fontSize < 8.0) fontSize = 14.0;
        _terminalFont = [UIFont fontWithName:@"Courier" size:fontSize];
        
        NSString *testChar = @"W";
        CGSize charSize = [testChar sizeWithFont:_terminalFont];
        _charWidth = charSize.width;
        _lineHeight = charSize.height + 2.0;
        
        _columns = 80;
        _rows = 24;
        _cursorVisible = YES;
        
        _terminalBuffer = [[NSMutableString alloc] init];
        _displayLines = [[NSMutableArray alloc] init];
        [_displayLines addObject:@""];
        
        _parser = [[VT100Parser alloc] init];
        _parser.delegate = self;
        
        // UIScrollView 配置（iOS 6 兼容）
        self.scrollEnabled = YES;
        self.bounces = YES;
        self.alwaysBounceVertical = YES;
        self.showsVerticalScrollIndicator = YES;
        self.delegate = self;
        
        [self setupView];
        [self setupHiddenInput];
        [self setupTapGesture];
        [self startCursorBlink];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(fontSizeDidChange:)
                                                     name:NSUserDefaultsDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)setupView {
    self.contentSize = CGSizeMake(self.frame.size.width, _rows * _lineHeight + 100);
}

- (void)setupHiddenInput {
    _hiddenInput = [[UITextField alloc] initWithFrame:CGRectMake(-100, -100, 1, 1)];
    _hiddenInput.keyboardType = UIKeyboardTypeASCIICapable;
    _hiddenInput.autocorrectionType = UITextAutocorrectionTypeNo;
    _hiddenInput.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _hiddenInput.spellCheckingType = UITextSpellCheckingTypeNo;
    _hiddenInput.delegate = self;
    _hiddenInput.hidden = YES;
    [self addSubview:_hiddenInput];
}

- (void)setupTapGesture {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self addGestureRecognizer:tap];
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    if ([_hiddenInput isFirstResponder]) {
        [_hiddenInput resignFirstResponder];
    } else {
        [_hiddenInput becomeFirstResponder];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (_charWidth > 0) {
        _columns = (NSInteger)(self.frame.size.width / _charWidth) - 1;
    }
    if (_lineHeight > 0) {
        _rows = (NSInteger)(self.frame.size.height / _lineHeight);
    }
    [self updateContentSize];
}

#pragma mark - 文本处理

- (void)appendText:(NSString *)text {
    if (!text || [text length] == 0) return;
    
    NSString *parsed = [_parser parseInput:text];
    if (!parsed) parsed = text;
    
    parsed = [parsed stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    
    NSArray *incomingLines = [parsed componentsSeparatedByString:@"\n"];
    
    for (NSInteger i = 0; i < [incomingLines count]; i++) {
        NSString *line = incomingLines[i];
        
        if (i == 0 && [_displayLines count] > 0) {
            NSString *lastLine = [_displayLines lastObject];
            [_displayLines removeLastObject];
            [_displayLines addObject:[lastLine stringByAppendingString:line]];
        } else {
            [_displayLines addObject:line];
        }
        
        while ([self visibleLengthOfLine:[_displayLines lastObject]] > _columns && _columns > 0) {
            NSString *longLine = [_displayLines lastObject];
            [_displayLines removeLastObject];
            
            NSInteger splitPos = [self splitPositionForLine:longLine atColumn:_columns];
            NSString *firstPart = [longLine substringToIndex:splitPos];
            NSString *secondPart = [longLine substringFromIndex:splitPos];
            
            [_displayLines addObject:firstPart];
            [_displayLines addObject:secondPart];
        }
    }
    
    while ([_displayLines count] > 500) {
        [_displayLines removeObjectAtIndex:0];
    }
    
    [self updateContentSize];
    [self scrollToBottom];
    [self setNeedsDisplay];
}

- (NSInteger)visibleLengthOfLine:(NSString *)line {
    NSInteger length = 0;
    BOOL inEscape = NO;
    for (NSInteger i = 0; i < [line length]; i++) {
        unichar c = [line characterAtIndex:i];
        if (c == 0x1B) {
            inEscape = YES;
            continue;
        }
        if (inEscape) {
            if ((c >= 'A' && c <= 'Z') || c == '~' || c == 'm') {
                inEscape = NO;
            }
            continue;
        }
        length++;
    }
    return length;
}

- (NSInteger)splitPositionForLine:(NSString *)line atColumn:(NSInteger)column {
    NSInteger visible = 0;
    BOOL inEscape = NO;
    for (NSInteger i = 0; i < [line length]; i++) {
        unichar c = [line characterAtIndex:i];
        if (c == 0x1B) {
            inEscape = YES;
            continue;
        }
        if (inEscape) {
            if ((c >= 'A' && c <= 'Z') || c == '~' || c == 'm') {
                inEscape = NO;
            }
            continue;
        }
        visible++;
        if (visible > column) {
            return i;
        }
    }
    return [line length];
}

- (void)clearScreen {
    [_displayLines removeAllObjects];
    [_displayLines addObject:@""];
    [_terminalBuffer setString:@""];
    [self updateContentSize];
    [self scrollToBottom];
    [self setNeedsDisplay];
}

- (void)updateContentSize {
    CGFloat totalHeight = [_displayLines count] * _lineHeight + 50;
    CGFloat minHeight = MAX(totalHeight, self.frame.size.height);
    self.contentSize = CGSizeMake(self.frame.size.width, minHeight);
}

#pragma mark - 滚动控制

- (void)scrollToBottom {
    CGFloat bottomY = self.contentSize.height - self.frame.size.height;
    if (bottomY < 0) bottomY = 0;
    [self setContentOffset:CGPointMake(0, bottomY) animated:NO];
}

#pragma mark - 绘制

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;
    
    [self.backgroundColor setFill];
    CGContextFillRect(ctx, rect);
    
    if ([_displayLines count] == 0) return;
    if (_charWidth <= 0 || _lineHeight <= 0) return;
    
    NSInteger startLine = (NSInteger)(self.contentOffset.y / _lineHeight);
    NSInteger endLine = startLine + _rows + 2;
    if (endLine > [_displayLines count]) endLine = [_displayLines count];
    if (startLine < 0) startLine = 0;
    
    for (NSInteger i = startLine; i < endLine; i++) {
        NSString *line = [_displayLines objectAtIndex:i];
        CGFloat y = (i * _lineHeight) + 2;
        if (y + _lineHeight < self.contentOffset.y || y > self.contentOffset.y + self.frame.size.height) continue;
        
        if ([line rangeOfString:@"\x1B"].location == NSNotFound) {
            [self.textColor setFill];
            [line drawAtPoint:CGPointMake(5, y) withFont:_terminalFont];
        } else {
            CGFloat x = 5;
            UIColor *currentColor = self.textColor;
            BOOL inEscape = NO;
            NSMutableString *escapeSeq = [[NSMutableString alloc] init];
            
            for (NSInteger j = 0; j < [line length]; j++) {
                unichar c = [line characterAtIndex:j];
                
                if (c == 0x1B) {
                    inEscape = YES;
                    [escapeSeq setString:@""];
                    continue;
                }
                
                if (inEscape) {
                    if (c == '[' && [escapeSeq length] == 0) {
                        continue;
                    }
                    if ((c >= 'A' && c <= 'Z') || c == '~' || c == 'm') {
                        if (c == 'm') {
                            currentColor = [self colorFromANSICode:escapeSeq];
                        }
                        inEscape = NO;
                        [escapeSeq setString:@""];
                        continue;
                    }
                    [escapeSeq appendFormat:@"%C", c];
                    continue;
                }
                
                NSString *singleChar = [NSString stringWithCharacters:&c length:1];
                [currentColor setFill];
                [singleChar drawAtPoint:CGPointMake(x, y) withFont:_terminalFont];
                x += _charWidth;
            }
        }
    }
    
    if (_cursorVisible && [_displayLines count] > 0) {
        [[UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.5] setFill];
        NSString *lastLine = [_displayLines lastObject];
        NSInteger visibleLen = [self visibleLengthOfLine:lastLine];
        CGFloat cursorX = 5 + (visibleLen % MAX(1, _columns)) * _charWidth;
        CGFloat cursorY = (([_displayLines count] - 1) * _lineHeight) + 2;
        
        if (cursorY >= self.contentOffset.y && cursorY < self.contentOffset.y + self.frame.size.height) {
            CGContextFillRect(ctx, CGRectMake(cursorX, cursorY, _charWidth, _lineHeight));
        }
    }
}

- (UIColor *)colorFromANSICode:(NSString *)code {
    if ([code isEqualToString:@"0"] || [code isEqualToString:@""]) {
        return self.textColor;
    }
    if ([code isEqualToString:@"1"]) return self.textColor;
    if ([code isEqualToString:@"30"]) return [UIColor blackColor];
    if ([code isEqualToString:@"31"]) return [UIColor redColor];
    if ([code isEqualToString:@"32"]) return [UIColor greenColor];
    if ([code isEqualToString:@"33"]) return [UIColor yellowColor];
    if ([code isEqualToString:@"34"]) return [UIColor blueColor];
    if ([code isEqualToString:@"35"]) return [UIColor magentaColor];
    if ([code isEqualToString:@"36"]) return [UIColor cyanColor];
    if ([code isEqualToString:@"37"]) return [UIColor whiteColor];
    return self.textColor;
}

#pragma mark - VT100ParserDelegate

- (void)vt100ClearScreen {
    [self clearScreen];
}

- (void)vt100MoveCursorToHome {
    [_displayLines addObject:@""];
    [self setNeedsDisplay];
}

#pragma mark - 光标闪烁

- (void)startCursorBlink {
    [NSTimer scheduledTimerWithTimeInterval:0.5
                                     target:self
                                   selector:@selector(toggleCursor)
                                   userInfo:nil
                                    repeats:YES];
}

- (void)toggleCursor {
    _cursorVisible = !_cursorVisible;
    [self setNeedsDisplay];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([string length] == 0) {
        unsigned char del = 0x7F;
        NSData *data = [NSData dataWithBytes:&del length:1];
        [_sessionManager sendData:data];
        return NO;
    }
    
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    if (data) {
        [_sessionManager sendData:data];
    }
    return NO;
}

#pragma mark - SessionManagerDelegate

- (void)sessionDidConnect {
    [_hiddenInput becomeFirstResponder];
}

- (void)sessionDidDisconnect {
    [self appendText:@"\n[Disconnected]\n"];
}

- (void)session:(id)session didReceiveData:(NSData *)data {
    NSString *text = [[NSString alloc] initWithBytes:[data bytes]
                                              length:[data length]
                                            encoding:NSUTF8StringEncoding];
    if (text) {
        [self appendText:text];
    }
}

- (void)session:(id)session didFailWithError:(NSError *)error {
    [self appendText:[NSString stringWithFormat:@"\n[Error: %@]\n", [error localizedDescription]]];
}

#pragma mark - 字体大小变化

- (void)fontSizeDidChange:(NSNotification *)notification {
    CGFloat fontSize = [[NSUserDefaults standardUserDefaults] floatForKey:@"terminalFontSize"];
    if (fontSize < 8.0) fontSize = 14.0;
    _terminalFont = [UIFont fontWithName:@"Courier" size:fontSize];
    
    NSString *testChar = @"W";
    CGSize charSize = [testChar sizeWithFont:_terminalFont];
    _charWidth = charSize.width;
    _lineHeight = charSize.height + 2.0;
    
    if (_charWidth > 0) {
        _columns = (NSInteger)(self.frame.size.width / _charWidth) - 1;
    }
    if (_lineHeight > 0) {
        _rows = (NSInteger)(self.frame.size.height / _lineHeight);
    }
    [self updateContentSize];
    [self setNeedsDisplay];
}

@end