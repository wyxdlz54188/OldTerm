#import <Foundation/Foundation.h>

@interface VT100Parser : NSObject {
    NSString *_escapeBuffer;
    BOOL _inEscapeSequence;
}

@property (nonatomic, retain) NSString *escapeBuffer;
@property (nonatomic, assign) BOOL inEscapeSequence;

- (NSString *)parseInput:(NSString *)input;
- (void)handleEscapeSequence:(NSString *)sequence;

@end
