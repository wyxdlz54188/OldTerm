#import "TermView.h"
#import "SessionManager.h"

static CGFloat getScreenHeight(UIScrollView *view) {
    CGSize size = view.bounds.size;
    UIEdgeInsets inset = view.contentInset;
    size.height -= inset.top + inset.bottom;
    return size.height;
}

typedef enum {
    kTapZoneTopLeft,
    kTapZoneTop,
    kTapZoneTopRight,
    kTapZoneLeft,
    kTapZoneCenter,
    kTapZoneRight,
    kTapZoneBottomLeft,
    kTapZoneBottom,
    kTapZoneBottomRight,
} TapZone;

static TapZone getTapZone(UIGestureRecognizer *gesture, CGPoint *outPoint) {
    UIScrollView *view = (UIScrollView *)gesture.view;
    CGPoint origin = [gesture locationInView:view];
    if (outPoint) *outPoint = origin;
    CGPoint offset = view.contentOffset;
    origin.x -= offset.x;
    origin.y -= offset.y;
    CGFloat height = getScreenHeight(view);
    CGFloat width = view.bounds.size.width;
    CGFloat margin = (width < height ? width : height) / 5;
    if (margin < 60) margin = 60;
    BOOL right = (origin.x > width - margin);
    if (origin.y < margin)
        return right ? kTapZoneTopRight : (origin.x < margin) ? kTapZoneTopLeft : kTapZoneTop;
    if (origin.y > height - margin)
        return right ? kTapZoneBottomRight : (origin.x < margin) ? kTapZoneBottomLeft : kTapZoneBottom;
    return right ? kTapZoneRight : (origin.x < margin) ? kTapZoneLeft : kTapZoneCenter;
}

@interface UIKeyboardImpl : NSObject
+ (id)sharedInstance;
- (BOOL)isShifted;
- (BOOL)isShiftLocked;
- (void)setShift:(BOOL)shift;
@end

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
        _ctrlLock = NO;

        _terminalBuffer = [[NSMutableString alloc] init];
        _displayLines = [[NSMutableArray alloc] init];
        [_displayLines addObject:@""];

        _parser = [[VT100Parser alloc] init];
        _parser.delegate = self;

        self.scrollEnabled = YES;
        self.bounces = YES;
        self.alwaysBounceVertical = YES;
        self.showsVerticalScrollIndicator = YES;
        self.delegate = self;

        [self setupView];
        [self setupGestures];
        [self setupMenuItems];
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

- (void)setupGestures {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleTapGesture:)];
    [self addGestureRecognizer:tap];

    UILongPressGestureRecognizer *hold = [[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleHoldGesture:)];
    hold.minimumPressDuration = 0.25;
    [self addGestureRecognizer:hold];

    UILongPressGestureRecognizer *twoFinger = [[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleTwoFingerGesture:)];
    twoFinger.numberOfTouchesRequired = 2;
    [self addGestureRecognizer:twoFinger];
}

- (void)setupMenuItems {
    UIMenuController *menu = [UIMenuController sharedMenuController];
    UIMenuItem *ctrlItem = [[UIMenuItem alloc] initWithTitle:@"Ctrl" action:@selector(ctrlLockAction:)];
    UIMenuItem *pasteItem = [[UIMenuItem alloc] initWithTitle:@"Paste" action:@selector(pasteAction:)];
    menu.menuItems = @[ctrlItem, pasteItem];
}

#pragma mark - UIKeyInput

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)hasText {
    return YES;
}

- (void)insertText:(NSString *)text {
    if (!_sessionManager) return;

    if (text.length == 1) {
        unichar c = [text characterAtIndex:0];
        if (c < 0x80) {
            if (_ctrlLock && c >= 0x40 && c <= 0x5f) {
                unsigned char ctrl = c & 0x1f;
                NSData *data = [NSData dataWithBytes:&ctrl length:1];
                [_sessionManager sendData:data];
                return;
            }
            if (c == '\t') {
                unsigned char tab = '\t';
                NSData *data = [NSData dataWithBytes:&tab length:1];
                [_sessionManager sendData:data];
                return;
            }
            if (c == '\n') {
                unsigned char cr = '\r';
                NSData *data = [NSData dataWithBytes:&cr length:1];
                [_sessionManager sendData:data];
                return;
            }
        }
    }

    [_sessionManager sendData:[text dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)deleteBackward {
    if (!_sessionManager) return;
    unsigned char del = 0x7F;
    NSData *data = [NSData dataWithBytes:&del length:1];
    [_sessionManager sendData:data];
}

- (UIKeyboardAppearance)keyboardAppearance {
    return UIKeyboardAppearanceAlert;
}

- (UITextAutocapitalizationType)autocapitalizationType {
    return UITextAutocapitalizationTypeNone;
}

- (UITextAutocorrectionType)autocorrectionType {
    return UITextAutocorrectionTypeNo;
}

- (BOOL)isSecureTextEntry {
    return YES;
}

#pragma mark - Keyboard Control

- (void)showKeyboard {
    [self becomeFirstResponder];
}

- (void)hideKeyboard {
    [self resignFirstResponder];
}

#pragma mark - Gesture Handlers

- (void)handleTapGesture:(UIGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateEnded) return;
    if (!_sessionManager || !_sessionManager.isConnected) return;

    BOOL shift = NO;
    UIKeyboardImpl *kb = (UIKeyboardImpl *)[UIKeyboardImpl sharedInstance];
    if (kb) shift = [kb isShifted];

    unsigned char key = 0;
    switch (getTapZone(gesture, NULL)) {
        case kTapZoneTop:
            key = shift ? 0x06 : 0x1B; break;  // PageUp or ESC-like up arrow
        case kTapZoneBottom:
            key = shift ? 0x07 : 0x1C; break;  // PageDown or down-like
        case kTapZoneLeft:
            key = shift ? 0x08 : 0x1D; break;  // Home or left-like
        case kTapZoneRight:
            key = shift ? 0x09 : 0x1E; break;  // End or right-like
        case kTapZoneTopLeft:     key = 0x1B; break;  // ESC
        case kTapZoneTopRight:    key = 0x7F; break;  // DEL
        case kTapZoneBottomLeft:  key = 0x1B; break;  // ESC
        case kTapZoneBottomRight: {
            [self becomeFirstResponder];
            return;
        }
        case kTapZoneCenter: {
            if ([self isFirstResponder]) {
                [self hideKeyboard];
            } else {
                [self showKeyboard];
            }
            return;
        }
        default: return;
    }

    NSData *data = [NSData dataWithBytes:&key length:1];
    [_sessionManager sendData:data];
}

- (void)handleHoldGesture:(UIGestureRecognizer *)gesture {
    if (!_sessionManager || !_sessionManager.isConnected) return;

    if (gesture.state == UIGestureRecognizerStateBegan) {
        if (_repeatTimer) return;

        [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];

        CGPoint origin;
        TapZone zone = getTapZone(gesture, &origin);

        switch (zone) {
            case kTapZoneCenter: {
                _ctrlLock = YES;
                UIMenuController *menu = [UIMenuController sharedMenuController];
                CGRect rect = CGRectMake(origin.x, origin.y, 1, 1);
                [menu setTargetRect:rect inView:self];
                [menu setMenuVisible:YES animated:YES];
                return;
            }
            case kTapZoneTop:
            case kTapZoneBottom:
            case kTapZoneLeft:
            case kTapZoneRight: {
                unsigned char key = 0;
                switch (zone) {
                    case kTapZoneTop:    key = 0x10; break;  // up
                    case kTapZoneBottom: key = 0x0E; break;  // down
                    case kTapZoneLeft:   key = 0x02; break;  // left
                    case kTapZoneRight:  key = 0x06; break;  // right
                    default: break;
                }
                NSNumber *keyNum = [NSNumber numberWithUnsignedChar:key];
                _repeatTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                    target:self selector:@selector(repeatTimerFired:)
                    userInfo:keyNum repeats:YES];
                return;
            }
            default: return;
        }
    }
    else if (gesture.state == UIGestureRecognizerStateEnded ||
             gesture.state == UIGestureRecognizerStateCancelled) {
        if (_repeatTimer) {
            [_repeatTimer invalidate];
            _repeatTimer = nil;
        }
        _ctrlLock = NO;
    }
}

- (void)handleTwoFingerGesture:(UIGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) return;
    if ([self isFirstResponder]) {
        [self hideKeyboard];
    } else {
        [self showKeyboard];
    }
}

- (void)repeatTimerFired:(NSTimer *)timer {
    unsigned char key = (unsigned char)[timer.userInfo unsignedCharValue];
    NSData *data = [NSData dataWithBytes:&key length:1];
    [_sessionManager sendData:data];
}

#pragma mark - UIMenuController Actions

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(ctrlLockAction:)) return YES;
    if (action == @selector(pasteAction:)) {
        return [[UIPasteboard generalPasteboard] containsPasteboardTypes:UIPasteboardTypeListString];
    }
    if (action == @selector(copy:)) return YES;
    return NO;
}

- (void)ctrlLockAction:(UIMenuController *)menu {
    _ctrlLock = !_ctrlLock;
}

- (void)pasteAction:(UIMenuController *)menu {
    NSString *text = [UIPasteboard generalPasteboard].string;
    if (text && _sessionManager) {
        [_sessionManager sendData:[text dataUsingEncoding:NSUTF8StringEncoding]];
    }
}

- (void)copy:(UIMenuController *)menu {
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    pb.string = [_terminalBuffer copy];
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    NSInteger oldColumns = _columns;
    NSInteger oldRows = _rows;

    if (_charWidth > 0) {
        _columns = (NSInteger)(self.frame.size.width / _charWidth) - 1;
    }
    if (_lineHeight > 0) {
        _rows = (NSInteger)(self.frame.size.height / _lineHeight);
    }

    if ((oldColumns != _columns || oldRows != _rows) && _sessionManager) {
        [_sessionManager resizeToColumns:_columns rows:_rows];
    }

    [self updateContentSize];
}

#pragma mark - Text Processing

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

#pragma mark - Scrolling

- (void)scrollToBottom {
    CGFloat bottomY = self.contentSize.height - self.frame.size.height;
    if (bottomY < 0) bottomY = 0;
    [self setContentOffset:CGPointMake(0, bottomY) animated:NO];
}

#pragma mark - Drawing

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

#pragma mark - Cursor Blink

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

#pragma mark - SessionManagerDelegate

- (void)sessionDidConnect {
    [self appendText:@"\n[Connected]\n"];
    [self showKeyboard];
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

#pragma mark - VT100ParserDelegate

- (void)vt100ClearScreen {
    [self clearScreen];
}

- (void)vt100MoveCursorToHome {
    [_displayLines addObject:@""];
    [self setNeedsDisplay];
}

#pragma mark - Font Size Change

- (void)fontSizeDidChange:(NSNotification *)notification {
    CGFloat fontSize = [[NSUserDefaults standardUserDefaults] floatForKey:@"terminalFontSize"];
    if (fontSize < 8.0) fontSize = 14.0;
    _terminalFont = [UIFont fontWithName:@"Courier" size:fontSize];

    NSInteger oldColumns = _columns;
    NSInteger oldRows = _rows;

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

    if ((oldColumns != _columns || oldRows != _rows) && _sessionManager) {
        [_sessionManager resizeToColumns:_columns rows:_rows];
    }

    [self updateContentSize];
    [self setNeedsDisplay];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_repeatTimer) {
        [_repeatTimer invalidate];
    }
}

@end
