#import "TermView.h"
#import "SessionManager.h"
#import "RowView.h"

static CGFloat getScreenHeight(UIScrollView *view) {
    CGSize size = view.bounds.size;
    UIEdgeInsets inset = view.contentInset;
    size.height -= inset.top + inset.bottom;
    return size.height;
}

typedef enum {
    kTapZoneTopLeft, kTapZoneTop, kTapZoneTopRight,
    kTapZoneLeft, kTapZoneCenter, kTapZoneRight,
    kTapZoneBottomLeft, kTapZoneBottom, kTapZoneBottomRight,
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
    if ((self = [super initWithFrame:frame style:UITableViewStylePlain])) {
        self.backgroundColor = [UIColor blackColor];
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
        _shouldScrollToBottom = YES;

        _terminalBuffer = [[NSMutableString alloc] init];
        _displayLines = [[NSMutableArray alloc] init];
        [_displayLines addObject:@""];

        _parser = [[VT100Parser alloc] init];
        _parser.delegate = self;

        self.dataSource = self;
        self.delegate = self;
        self.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.allowsSelection = NO;
        self.bounces = YES;
        self.alwaysBounceVertical = YES;

        [self setupGestures];
        [self setupMenuItems];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(fontSizeDidChange:)
                                                     name:NSUserDefaultsDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
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

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_displayLines count] + 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return _lineHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"TermCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        cell.backgroundColor = [UIColor blackColor];
        RowView *rowView = [[RowView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, _lineHeight)];
        rowView.defaultColor = self.textColor;
        rowView.charWidth = _charWidth;
        cell.backgroundView = rowView;
    }

    RowView *rowView = (RowView *)cell.backgroundView;
    rowView.frame = CGRectMake(0, 0, self.frame.size.width, _lineHeight);

    if (indexPath.row < [_displayLines count]) {
        NSString *line = [_displayLines objectAtIndex:indexPath.row];
        [rowView renderLine:line];
    } else {
        [rowView renderLine:@""];
    }

    return cell;
}

#pragma mark - UITableViewDelegate
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat bottomOffset = scrollView.contentSize.height - scrollView.frame.size.height + scrollView.contentInset.bottom;
    _shouldScrollToBottom = (scrollView.contentOffset.y >= bottomOffset - _lineHeight);
}

#pragma clang diagnostic pop

#pragma mark - UIKeyInput

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
                [_sessionManager sendData:[NSData dataWithBytes:&ctrl length:1]];
                return;
            }
            if (c == '\t') {
                [_sessionManager sendData:[NSData dataWithBytes:"\t" length:1]];
                return;
            }
            if (c == '\n') {
                [_sessionManager sendData:[NSData dataWithBytes:"\r" length:1]];
                return;
            }
        }
    }

    [_sessionManager sendData:[text dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)deleteBackward {
    if (!_sessionManager) return;
    unsigned char bs = 0x08;
    [_sessionManager sendData:[NSData dataWithBytes:&bs length:1]];
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

    if (![self isFirstResponder]) {
        [self showKeyboard];
        return;
    }

    if (!_sessionManager || !_sessionManager.isConnected) return;

    BOOL shift = NO;
    UIKeyboardImpl *kb = (UIKeyboardImpl *)[UIKeyboardImpl sharedInstance];
    if (kb) shift = [kb isShifted];

    unsigned char key = 0;
    switch (getTapZone(gesture, NULL)) {
        case kTapZoneTop:     key = shift ? 0x10 : 0x1B; break;
        case kTapZoneBottom:  key = shift ? 0x0E : 0x1C; break;
        case kTapZoneLeft:    key = shift ? 0x02 : 0x1D; break;
        case kTapZoneRight:   key = shift ? 0x06 : 0x1E; break;
        case kTapZoneTopLeft:     key = 0x1B; break;
        case kTapZoneTopRight:    key = 0x7F; break;
        case kTapZoneBottomLeft:  key = 0x1B; break;
        case kTapZoneBottomRight:
        case kTapZoneCenter:
            return;
        default: return;
    }

    [_sessionManager sendData:[NSData dataWithBytes:&key length:1]];
}

- (void)handleHoldGesture:(UIGestureRecognizer *)gesture {
    if (!_sessionManager || !_sessionManager.isConnected) return;

    if (gesture.state == UIGestureRecognizerStateBegan) {
        if (_repeatTimer) return;
        [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];

        CGPoint origin;
        TapZone zone = getTapZone(gesture, &origin);

        switch (zone) {
            case kTapZoneCenter:
                _ctrlLock = YES;
                [[UIMenuController sharedMenuController] setTargetRect:CGRectMake(origin.x, origin.y, 1, 1) inView:self];
                [[UIMenuController sharedMenuController] setMenuVisible:YES animated:YES];
                return;
            case kTapZoneTop: case kTapZoneBottom:
            case kTapZoneLeft: case kTapZoneRight: {
                unsigned char key = 0;
                switch (zone) {
                    case kTapZoneTop: key = 0x10; break;
                    case kTapZoneBottom: key = 0x0E; break;
                    case kTapZoneLeft: key = 0x02; break;
                    case kTapZoneRight: key = 0x06; break;
                    default: break;
                }
                _repeatTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                    target:self selector:@selector(repeatTimerFired:)
                    userInfo:[NSNumber numberWithUnsignedChar:key] repeats:YES];
                return;
            }
            default: return;
        }
    } else if (gesture.state == UIGestureRecognizerStateEnded ||
               gesture.state == UIGestureRecognizerStateCancelled) {
        if (_repeatTimer) { [_repeatTimer invalidate]; _repeatTimer = nil; }
        _ctrlLock = NO;
    }
}

- (void)handleTwoFingerGesture:(UIGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) return;
    if ([self isFirstResponder])
        [self hideKeyboard];
    else
        [self showKeyboard];
}

- (void)repeatTimerFired:(NSTimer *)timer {
    unsigned char key = (unsigned char)[timer.userInfo unsignedCharValue];
    [_sessionManager sendData:[NSData dataWithBytes:&key length:1]];
}

#pragma mark - UIMenuController Actions

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(ctrlLockAction:)) return YES;
    if (action == @selector(pasteAction:))
        return [[UIPasteboard generalPasteboard] containsPasteboardTypes:UIPasteboardTypeListString];
    if (action == @selector(copy:)) return YES;
    return NO;
}

- (void)ctrlLockAction:(UIMenuController *)menu {
    _ctrlLock = !_ctrlLock;
}

- (void)pasteAction:(UIMenuController *)menu {
    NSString *text = [UIPasteboard generalPasteboard].string;
    if (text && _sessionManager)
        [_sessionManager sendData:[text dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)copy:(UIMenuController *)menu {
    [UIPasteboard generalPasteboard].string = [_terminalBuffer copy];
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
    }

    while ([_displayLines count] > 500)
        [_displayLines removeObjectAtIndex:0];

    [self reloadData];

    if (_shouldScrollToBottom)
        [self scrollToBottom];
}

- (void)clearScreen {
    [_displayLines removeAllObjects];
    [_displayLines addObject:@""];
    [_terminalBuffer setString:@""];
    [self reloadData];
}

- (void)scrollToBottom {
    NSInteger count = [_displayLines count];
    if (count == 0) return;
    NSIndexPath *lastRow = [NSIndexPath indexPathForRow:count inSection:0];
    [self scrollToRowAtIndexPath:lastRow atScrollPosition:UITableViewScrollPositionBottom animated:NO];
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
    if (text) [self appendText:text];
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
    [self reloadData];
}

#pragma mark - Font Size Change

- (void)fontSizeDidChange:(NSNotification *)notification {
    CGFloat fontSize = [[NSUserDefaults standardUserDefaults] floatForKey:@"terminalFontSize"];
    if (fontSize < 8.0) fontSize = 14.0;
    _terminalFont = [UIFont fontWithName:@"Courier" size:fontSize];

    NSInteger oldColumns = _columns, oldRows = _rows;
    NSString *testChar = @"W";
    CGSize charSize = [testChar sizeWithFont:_terminalFont];
    _charWidth = charSize.width;
    _lineHeight = charSize.height + 2.0;

    if (_charWidth > 0) _columns = (NSInteger)(self.frame.size.width / _charWidth) - 1;
    if (_lineHeight > 0) _rows = (NSInteger)(self.frame.size.height / _lineHeight);

    if ((oldColumns != _columns || oldRows != _rows) && _sessionManager)
        [_sessionManager resizeToColumns:_columns rows:_rows];

    [self reloadData];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_repeatTimer) [_repeatTimer invalidate];
}

@end
