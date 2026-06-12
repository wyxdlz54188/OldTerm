#import "TermView.h"
#import "SessionManager.h"

@interface TermView () <UITextFieldDelegate, SessionManagerDelegate>
@end

@implementation TermView

@synthesize buffer = _buffer, textColor = _textColor, backgroundColor = _backgroundColor;
@synthesize cursorColor = _cursorColor, terminalFont = _terminalFont;
@synthesize cursorX = _cursorX, cursorY = _cursorY, columns = _columns, rows = _rows;
@synthesize cursorVisible = _cursorVisible;
@synthesize sessionManager = _sessionManager;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
        self.textColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
        self.cursorColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.5];
        self.terminalFont = [UIFont fontWithName:@"Courier" size:14.0];
        self.buffer = @"";
        self.cursorX = 0;
        self.cursorY = 0;
        self.columns = 80;
        self.rows = 24;
        self.cursorVisible = YES;
        
        [self setupView];
        [self startCursorBlink];
    }
    return self;
}

- (void)setupView {
    self.userInteractionEnabled = YES;
    self.multipleTouchEnabled = NO;
    
    self.hiddenInput = [[UITextField alloc] initWithFrame:CGRectZero];
    self.hiddenInput.keyboardType = UIKeyboardTypeASCIICapable;
    self.hiddenInput.autocorrectionType = UITextAutocorrectionTypeNo;
    self.hiddenInput.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.hiddenInput.spellCheckingType = UITextSpellCheckingTypeNo;
    self.hiddenInput.returnKeyType = UIReturnKeySend;
    self.hiddenInput.delegate = self;
    [self addSubview:self.hiddenInput];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.hiddenInput becomeFirstResponder];
}

- (void)drawRect:(CGRect)rect {
    [self.backgroundColor setFill];
    UIRectFill(rect);
    
    [self.textColor setFill];
    
    NSInteger lineHeight = 16;
    NSArray *lines = [self.buffer componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    for (NSInteger i = 0; i < [lines count] && i < self.rows; i++) {
        NSString *line = [lines objectAtIndex:i];
        [line drawAtPoint:CGPointMake(5.0, 5.0 + (i * lineHeight)) withFont:self.terminalFont];
    }
    
    if (self.cursorVisible) {
        [self.cursorColor setFill];
        CGFloat cursorX = 5.0 + (self.cursorX * 8);
        CGFloat cursorY = 5.0 + (self.cursorY * lineHeight);
        UIRectFill(CGRectMake(cursorX, cursorY, 8, 16));
    }
}

- (void)appendText:(NSString *)text {
    self.buffer = [self.buffer stringByAppendingString:text];
    [self updateCursorPosition];
    [self setNeedsDisplay];
}

- (void)updateCursorPosition {
    NSArray *lines = [self.buffer componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    if ([lines count] > 0) {
        NSString *lastLine = [lines lastObject];
        self.cursorX = [lastLine length];
        self.cursorY = [lines count] - 1;
        
        if (self.cursorX >= self.columns) {
            self.cursorX = 0;
            self.cursorY++;
        }
    }
}

- (void)clearScreen {
    self.buffer = @"";
    self.cursorX = 0;
    self.cursorY = 0;
    [self setNeedsDisplay];
}

- (void)moveCursorToRow:(NSInteger)row column:(NSInteger)col {
    self.cursorY = row;
    self.cursorX = col;
    [self setNeedsDisplay];
}

- (void)sendText:(NSString *)text {
    [self appendText:text];
}

- (void)startCursorBlink {
    [NSTimer scheduledTimerWithTimeInterval:0.5 
                                     target:self 
                                   selector:@selector(toggleCursor) 
                                   userInfo:nil 
                                    repeats:YES];
}

- (void)toggleCursor {
    self.cursorVisible = !self.cursorVisible;
    [self setNeedsDisplay];
}

- (void)showCursor {
    self.cursorVisible = YES;
    [self setNeedsDisplay];
}

- (void)hideCursor {
    self.cursorVisible = NO;
    [self setNeedsDisplay];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([string isEqualToString:@"\n"] || [string isEqualToString:@"\r"]) {
        [self.sessionManager sendCommand:@"\n"];
        return NO;
    }
    
    if ([string isEqualToString:@"\b"] || [string isEqualToString:@"\x7f"]) {
        [self.sessionManager sendCommand:@"\x7f"];
        return NO;
    }
    
    if (string.length > 0) {
        [self.sessionManager sendCommand:string];
        [self appendText:string];
        return NO;
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.sessionManager sendCommand:@"\n"];
    [textField setText:@""];
    return NO;
}

#pragma mark - SessionManagerDelegate

- (void)sessionDidConnect {
    [self appendText:@"\n[Connected to local session]\n"];
    [self.hiddenInput becomeFirstResponder];
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
}

@end
