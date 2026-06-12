#import "VT100Parser.h"

@implementation VT100Parser

@synthesize escapeBuffer = _escapeBuffer, inEscapeSequence = _inEscapeSequence;

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
            _inEscapeSequence = YES;
            _escapeBuffer = @"";
            continue;
        }
        
        if (_inEscapeSequence) {
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
    NSLog(@"VT100 Escape Sequence: %@", sequence);
    
    if ([sequence isEqualToString:@"(null"]) {
    } else if ([sequence hasPrefix:@"["]) {
        if ([sequence isEqualToString:@"[H"]) {
        } else if ([sequence isEqualToString:@"[J"]) {
        } else if ([sequence hasPrefix:@"[A"]) {
        } else if ([sequence hasPrefix:@"[B"]) {
        } else if ([sequence hasPrefix:@"[C"]) {
        } else if ([sequence hasPrefix:@"[D"]) {
        }
    }
}

- (void)dealloc {
    [_escapeBuffer release];
    [super dealloc];
}

@end
