#import <UIKit/UIKit.h>
#import "VT100Parser.h"
#import "SessionManager.h"

@class SessionManager;

@interface TermView : UITableView <UITableViewDataSource, UITableViewDelegate, SessionManagerDelegate, VT100ParserDelegate, UIKeyInput> {
    VT100Parser *_parser;
    SessionManager *_sessionManager;
    NSMutableString *_terminalBuffer;
    NSMutableArray *_displayLines;
    UIFont *_terminalFont;
    CGFloat _lineHeight;
    CGFloat _charWidth;
    NSInteger _columns;
    NSInteger _rows;
    BOOL _cursorVisible;
    BOOL _ctrlLock;
    NSTimer *_repeatTimer;
    BOOL _shouldScrollToBottom;
}

@property (nonatomic, retain) SessionManager *sessionManager;
@property (nonatomic, retain) UIColor *textColor;
@property (nonatomic, retain) UIColor *backgroundColor;
@property (nonatomic, assign) BOOL cursorVisible;

- (void)appendText:(NSString *)text;
- (void)clearScreen;
- (void)scrollToBottom;
- (void)showKeyboard;
- (void)hideKeyboard;

@end
