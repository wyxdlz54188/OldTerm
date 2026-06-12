#import <UIKit/UIKit.h>

@interface TermView : UIView {
    NSString *_buffer;
    UIColor *_textColor;
    UIColor *_backgroundColor;
    UIColor *_cursorColor;
    UIFont *_terminalFont;
    NSInteger _cursorX;
    NSInteger _cursorY;
    NSInteger _columns;
    NSInteger _rows;
    BOOL _cursorVisible;
}

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

- (void)appendText:(NSString *)text;
- (void)clearScreen;
- (void)moveCursorToRow:(NSInteger)row column:(NSInteger)col;
- (void)sendText:(NSString *)text;
- (void)showCursor;
- (void)hideCursor;

@end
