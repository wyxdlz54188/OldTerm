#import "TermView.h"
#import "SessionManager.h"

@implementation TermView

@synthesize sessionManager = _sessionManager, textColor = _textColor;
@synthesize backgroundColor = _backgroundColor, cursorVisible = _cursorVisible;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
        self.textColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
        
        _terminalFont = [UIFont fontWithName:@"Courier" size:14.0];
        _lineHeight = 18.0;
        _charWidth = 8.0;
        _columns = 80;
        _rows = 24;
        _cursorVisible = YES;
        
        _terminalBuffer = [[NSMutableString alloc] init];
        _displayLines = [[NSMutableArray alloc] init];
        [_displayLines addObject:@""];
        
        _parser = [[VT100Parser alloc] init];
        
        [self setupView];
        [self setupHiddenInput];
        [self setupTapGesture];
        [self startCursorBlink];
    }
    return self;
}

- (void)setupView {
    // 关键：允许滚动
    self.scrollEnabled = YES;
    self.bounces = NO;
    self.showsVerticalScrollIndicator = YES;
    self.alwaysBounceVertical = NO;
    self.delegate = self;
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
    // 点击终端区域任意位置弹出键盘
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
    _columns = (NSInteger)(self.frame.size.width / _charWidth) - 1;
    _rows = (NSInteger)(self.frame.size.height / _lineHeight);
    self.contentSize = CGSizeMake(self.frame.size.width, MAX(_rows, [_displayLines count]) * _lineHeight + 100);
}

#pragma mark - 文本处理（支持自动换行）

- (void)appendText:(NSString *)text {
    if (!text || [text length] == 0) return;
    
    // 用 VT100Parser 解析 ANSI 转义序列
    NSString *parsed = [_parser parseInput:text];
    if (!parsed) parsed = text;
    
    // 过滤掉部分控制字符
    parsed = [parsed stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    
    // 按换行分割
    NSArray *incomingLines = [parsed componentsSeparatedByString:@"\n"];
    
    for (NSInteger i = 0; i < [incomingLines count]; i++) {
        NSString *line = incomingLines[i];
        
        if (i == 0 && [_displayLines count] > 0) {
            // 第一段追加到最后一行
            NSString *lastLine = [_displayLines lastObject];
            [_displayLines removeLastObject];
            [_displayLines addObject:[lastLine stringByAppendingString:line]];
        } else {
            [_displayLines addObject:line];
        }
        
        // 自动换行：超长行拆成多行
        while ([[_displayLines lastObject] length] > _columns) {
            NSString *longLine = [_displayLines lastObject];
            [_displayLines removeLastObject];
            
            NSString *firstPart = [longLine substringToIndex:_columns];
            NSString *secondPart = [longLine substringFromIndex:_columns];
            
            [_displayLines addObject:firstPart];
            [_displayLines addObject:secondPart];
        }
    }
    
    // 限制总行数（保留最近 500 行）
    while ([_displayLines count] > 500) {
        [_displayLines removeObjectAtIndex:0];
    }
    
    [self updateContentSize];
    [self setNeedsDisplay];
}

- (void)clearScreen {
    [_displayLines removeAllObjects];
    [_displayLines addObject:@""];
    [_terminalBuffer setString:@""];
    [self setNeedsDisplay];
}

- (void)updateContentSize {
    CGFloat totalHeight = [_displayLines count] * _lineHeight + 50;
    self.contentSize = CGSizeMake(self.frame.size.width, MAX(totalHeight, self.frame.size.height));
    
    // 自动滚到底部
    if (self.contentSize.height > self.frame.size.height) {
        CGPoint bottomOffset = CGPointMake(0, self.contentSize.height - self.frame.size.height);
        [self setContentOffset:bottomOffset animated:NO];
    }
}

#pragma mark - 绘制

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    // 背景
    [self.backgroundColor setFill];
    CGContextFillRect(ctx, rect);
    
    // 计算可见范围
    NSInteger startLine = (NSInteger)(self.contentOffset.y / _lineHeight);
    NSInteger endLine = startLine + _rows + 2;
    if (endLine > [_displayLines count]) endLine = [_displayLines count];
    if (startLine < 0) startLine = 0;
    
    [self.textColor setFill];
    
    for (NSInteger i = startLine; i < endLine; i++) {
        NSString *line = [_displayLines objectAtIndex:i];
        CGFloat y = (i * _lineHeight) - self.contentOffset.y + 5;
        if (y + _lineHeight < 0 || y > self.frame.size.height) continue;
        
        [line drawAtPoint:CGPointMake(5, y) withFont:_terminalFont];
    }
    
    // 光标
    if (_cursorVisible && [_displayLines count] > 0) {
        [[UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.5] setFill];
        NSString *lastLine = [_displayLines lastObject];
        CGFloat cursorX = 5 + ([lastLine length] % _columns) * _charWidth;
        CGFloat cursorY = (([_displayLines count] - 1) * _lineHeight) - self.contentOffset.y + 5;
        
        if (cursorY >= 0 && cursorY < self.frame.size.height) {
            CGContextFillRect(ctx, CGRectMake(cursorX, cursorY, _charWidth, _lineHeight));
        }
    }
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

#pragma mark - UITextFieldDelegate（核心：不再重复显示输入）

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    // 回车
    if ([string isEqualToString:@"\n"]) {
        [_sessionManager sendCommand:@"\n"];
        textField.text = @"";
        return NO;
    }
    
    // 删除
    if ([string isEqualToString:@""] && range.length > 0) {
        [_sessionManager sendCommand:@"\x7f"];
        textField.text = @"";
        return NO;
    }
    
    // 普通字符：只发送到 shell，不手动 append（shell 会回显）
    if ([string length] > 0) {
        [_sessionManager sendCommand:string];
        textField.text = @"";
        return NO;
    }
    
    return YES;
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

- (void)dealloc {
    [_terminalBuffer release];
    [_displayLines release];
    [_parser release];
    [super dealloc];
}

@end