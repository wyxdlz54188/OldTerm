#import "VT100Parser.h"

@implementation VT100Parser

@synthesize escapeBuffer = _escapeBuffer, inEscapeSequence = _inEscapeSequence;
@synthesize delegate = _delegate;

- (id)init {
    if ((self = [super init])) {
        _escapeBuffer = @"";
        _inEscapeSequence = NO;
    }
    return self;
}

- (NSString *)parseInput:(NSString *)input {
    NSMutableString *output = [NSMutableString string];
    NSUInteger len = [input length];
    
    for (NSUInteger i = 0; i < len; i++) {
        unichar c = [input characterAtIndex:i];
        
        if (c == 0x1B) {
            [output appendFormat:@"%C", c];
            _inEscapeSequence = YES;
            _escapeBuffer = @"";
            continue;
        }
        
        if (_inEscapeSequence) {
            [output appendFormat:@"%C", c];
            _escapeBuffer = [_escapeBuffer stringByAppendingString:[NSString stringWithCharacters:&c length:1]];
            
            if ((c >= 'A' && c <= 'Z') || c == '~' || c == 'm') {
                [self handleEscapeSequence:_escapeBuffer];
                _inEscapeSequence = NO;
                _escapeBuffer = @"";
            }
            continue;
        }
        
        [output appendFormat:@"%C", c];
    }
    
    return output;
}

- (void)handleEscapeSequence:(NSString *)sequence {
    if ([sequence isEqualToString:@"[H"]) {
        if ([_delegate respondsToSelector:@selector(vt100MoveCursorToHome)]) {
            [_delegate vt100MoveCursorToHome];
        }
    } else if ([sequence isEqualToString:@"[J"] || [sequence isEqualToString:@"[2J"]) {
        if ([_delegate respondsToSelector:@selector(vt100ClearScreen)]) {
            [_delegate vt100ClearScreen];
        }
    }
}

- (void)dealloc {
}

@end