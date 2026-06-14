#import <Foundation/Foundation.h>

@protocol VT100ParserDelegate <NSObject>
- (void)vt100ClearScreen;
- (void)vt100MoveCursorToHome;
@end

@interface VT100Parser : NSObject {
    NSString *_escapeBuffer;
    BOOL _inEscapeSequence;
}

@property (nonatomic, retain) NSString *escapeBuffer;
@property (nonatomic, assign) BOOL inEscapeSequence;
@property (nonatomic, unsafe_unretained) id<VT100ParserDelegate> delegate;

- (NSString *)parseInput:(NSString *)input;
- (void)handleEscapeSequence:(NSString *)sequence;

@end