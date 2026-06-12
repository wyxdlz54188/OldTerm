#import <UIKit/UIKit.h>

@protocol SessionManagerDelegate;
@class SessionManager;

@interface TermView : UIView

@property (nonatomic, retain) NSString *buffer;
@property (nonatomic, retain) UIColor *textColor;
@property (nonatomic, retain) UIColor *backgroundColor;
@property (nonatomic, retain) UIColor *cursorColor;
@property (nonatomic, retain) UIFont *terminalFont;
@property (nonatomic, assign) NSInteger cursorX;
@property (nonatomic, assign) NSInteger cursorY;
@property (nonatomic, assign) NSInteger columns;
@property (nonatomic, assign) NSInteger rows;
@property (nonatomic, assign) BOOL cursorVisible;
@property (nonatomic, retain) UITextField *hiddenInput;
@property (nonatomic, retain) SessionManager *sessionManager;

- (void)appendText:(NSString *)text;
- (void)sendText:(NSString *)text;
- (void)clearScreen;
- (void)moveCursorToRow:(NSInteger)row column:(NSInteger)col;
- (void)showCursor;
- (void)hideCursor;

@end
