#import <Foundation/Foundation.h>

@protocol VT100ParserDelegate <NSObject>
@optional
- (void)vt100ClearScreen;
- (void)vt100ClearToEndOfScreen;
- (void)vt100ClearToBeginningOfScreen;
- (void)vt100ClearLine;
- (void)vt100ClearToEndOfLine;
- (void)vt100ClearToBeginningOfLine;
- (void)vt100MoveCursorToHome;
- (void)vt100MoveCursorToRow:(NSInteger)row column:(NSInteger)col;
- (void)vt100MoveCursorUp:(NSInteger)n;
- (void)vt100MoveCursorDown:(NSInteger)n;
- (void)vt100MoveCursorLeft:(NSInteger)n;
- (void)vt100MoveCursorRight:(NSInteger)n;
- (void)vt100SetScrollRegionTop:(NSInteger)top bottom:(NSInteger)bottom;
- (void)vt100ScrollUp:(NSInteger)n;
- (void)vt100ScrollDown:(NSInteger)n;
- (void)vt100DeleteLines:(NSInteger)n;
- (void)vt100InsertLines:(NSInteger)n;
- (void)vt100DeleteCharacters:(NSInteger)n;
- (void)vt100InsertCharacters:(NSInteger)n;
- (void)vt100SetTitle:(NSString *)title;
- (void)vt100Bell;
- (void)vt100ReverseLineFeed;
- (void)vt100SaveCursor;
- (void)vt100RestoreCursor;
- (void)vt100SetCursorVisible:(BOOL)visible;
- (void)vt100Reset;
@end

@interface VT100Parser : NSObject

@property (nonatomic, unsafe_unretained) id<VT100ParserDelegate> delegate;
@property (nonatomic, assign) CFStringEncoding encoding;
@property (nonatomic, readonly) NSString *currentTitle;

- (NSString *)parseInput:(NSString *)input;
- (NSData *)processData:(NSData *)data;

@end
