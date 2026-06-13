#import <UIKit/UIKit.h>
#import "VT100Parser.h"
#import "SessionManager.h"

@class SessionManager;

@interface TermView : UIScrollView <UIScrollViewDelegate, UITextFieldDelegate, SessionManagerDelegate, VT100ParserDelegate> {
    VT100Parser *_parser;
    SessionManager *_sessionManager;
    UITextField *_hiddenInput;
    NSMutableString *_terminalBuffer;
    NSMutableArray *_displayLines;
    UIFont *_terminalFont;
    CGFloat _lineHeight;
    CGFloat _charWidth;
    NSInteger _columns;
    NSInteger _rows;
    BOOL _cursorVisible;
}

@property (nonatomic, retain) SessionManager *sessionManager;
@property (nonatomic, retain) UIColor *textColor;
@property (nonatomic, retain) UIColor *backgroundColor;
@property (nonatomic, assign) BOOL cursorVisible;

- (void)appendText:(NSString *)text;
- (void)clearScreen;
- (void)scrollToBottom;

@end