#import "VT100Parser.h"

typedef enum {
    kSequenceNone,
    kSequenceESC,
    kSequenceCSI,
    kSequenceOSC,
    kSequenceIgnore,
    kSequencePossibleST,
} SequenceState;

@interface VT100Parser () {
    SequenceState _sequence;
    NSInteger _CSIParam;
    NSMutableArray *_CSIParams;
    NSMutableString *_OSCString;
    unsigned char *_encbuf;
    CFIndex _encbufSize;
    CFIndex _encbufIndex;
    NSString *_title;
}

@end

@implementation VT100Parser

@synthesize delegate = _delegate, encoding = _encoding, currentTitle = _title;

- (id)init {
    if ((self = [super init])) {
        _encoding = kCFStringEncodingUTF8;
        _sequence = kSequenceNone;
        _CSIParam = 0;
        _CSIParams = nil;
        _OSCString = nil;
        _title = nil;
        _encbuf = NULL;
        _encbufSize = 0;
        _encbufIndex = 0;
    }
    return self;
}

- (void)setEncoding:(CFStringEncoding)encoding {
    if (_encoding != encoding) {
        _encoding = encoding;
        if (_encbuf) { free(_encbuf); _encbuf = NULL; }
        CFIndex size = CFStringGetMaximumSizeForEncoding(1, encoding);
        if (size > 1) {
            _encbuf = malloc(size);
            _encbufSize = size;
            _encbufIndex = 0;
        }
    }
}

- (NSInteger)csiParamAtIndex:(NSUInteger)index default:(NSInteger)def {
    if (!_CSIParams || index >= [_CSIParams count]) return def;
    return [[_CSIParams objectAtIndex:index] integerValue];
}

- (void)clearCSIParams {
    _CSIParams = nil;
    _CSIParam = 0;
}

- (void)publishParsed:(NSString *)parsed {
}

- (NSString *)parseInput:(NSString *)input {
    NSMutableString *output = [NSMutableString string];
    NSUInteger len = [input length];

    for (NSUInteger i = 0; i < len; i++) {
        unichar c = [input characterAtIndex:i];

        if (_sequence == kSequenceIgnore) {
            if (c == 0x1B) _sequence = kSequencePossibleST;
        }
        else if (_sequence == kSequencePossibleST) {
            _sequence = (c == '\\') ? kSequenceNone : kSequenceIgnore;
        }
        else if (c < 0x20) {
            if (_OSCString) {
                switch (c) {
                    case '\a':
                        [self handleOSCEnd];
                        break;
                    case 030: case 032:
                        _sequence = kSequenceNone;
                        _OSCString = nil;
                        break;
                    case 0x1B:
                        _sequence = kSequenceESC;
                        break;
                }
            } else {
                switch (c) {
                    case '\a':
                        if ([_delegate respondsToSelector:@selector(vt100Bell)])
                            [_delegate vt100Bell];
                        [output appendFormat:@"%C", c];
                        break;
                    case '\b':
                    case '\t':
                    case '\n':
                    case '\v':
                    case '\f':
                    case '\r':
                        [output appendFormat:@"%C", c];
                        break;
                    case 0x1B:
                        _sequence = kSequenceESC;
                        break;
                    default:
                        break;
                }
            }
        }
        else if (_sequence == kSequenceESC) {
            if (_OSCString) {
                _OSCString = nil;
            }
            _sequence = kSequenceNone;
            switch (c) {
                case '[': _sequence = kSequenceCSI; break;
                case ']': _OSCString = [[NSMutableString alloc] init]; _sequence = kSequenceOSC; break;
                case '7':
                    if ([_delegate respondsToSelector:@selector(vt100SaveCursor)])
                        [_delegate vt100SaveCursor];
                    [output appendFormat:@"%C%c", 0x1B, (char)c];
                    break;
                case '8':
                    if ([_delegate respondsToSelector:@selector(vt100RestoreCursor)])
                        [_delegate vt100RestoreCursor];
                    [output appendFormat:@"%C%c", 0x1B, (char)c];
                    break;
                case 'M':
                    if ([_delegate respondsToSelector:@selector(vt100ReverseLineFeed)])
                        [_delegate vt100ReverseLineFeed];
                    [output appendFormat:@"%C%c", 0x1B, (char)c];
                    break;
                case 'c':
                    if ([_delegate respondsToSelector:@selector(vt100Reset)])
                        [_delegate vt100Reset];
                    break;
                default:
                    [output appendFormat:@"%C%c", 0x1B, (char)c];
                    break;
            }
        }
        else if (_sequence == kSequenceCSI) {
            if (!_CSIParams) {
                if (c >= '0' && c <= '9') {
                    _CSIParam = c - '0';
                    continue;
                } else if (c == '?' || c == '>' || c == '=') {
                    [output appendFormat:@"%C[%c", 0x1B, (char)c];
                    continue;
                }
            }
            if (c >= '0' && c <= '9') {
                _CSIParam = _CSIParam * 10 + c - '0';
                continue;
            }
            if (c == ';') {
                if (!_CSIParams) _CSIParams = [[NSMutableArray alloc] init];
                [_CSIParams addObject:[NSNumber numberWithInteger:_CSIParam]];
                _CSIParam = 0;
                continue;
            }

            if (!_CSIParams) _CSIParams = [[NSMutableArray alloc] init];
            [_CSIParams addObject:[NSNumber numberWithInteger:_CSIParam]];

            _sequence = kSequenceNone;
            [self handleCSISequence:(char)c];
            [output appendFormat:@"%C[", 0x1B];
            for (NSUInteger j = 0; j < [_CSIParams count]; j++) {
                if (j > 0) [output appendString:@";"];
                [output appendFormat:@"%ld", (long)[[_CSIParams objectAtIndex:j] integerValue]];
            }
            [output appendFormat:@"%c", (char)c];

            [self clearCSIParams];
        }
        else if (_sequence == kSequenceOSC) {
            if (c == '\a' || (c == 0x1B)) {
                [self handleOSCEnd];
                if (c == 0x1B) _sequence = kSequenceESC;
                [output appendFormat:@"%C", c];
            } else {
                [_OSCString appendFormat:@"%C", c];
            }
        }
        else {
            [output appendFormat:@"%C", c];
        }
    }

    return output;
}

- (NSData *)processData:(NSData *)data {
    NSString *text = [[NSString alloc] initWithBytes:[data bytes]
                                              length:[data length]
                                            encoding:NSUTF8StringEncoding];
    if (!text) {
        text = [[NSString alloc] initWithBytes:[data bytes]
                                        length:[data length]
                                      encoding:NSASCIIStringEncoding];
    }
    if (!text) return nil;

    [self parseInput:text];
    return data;
}

- (void)handleCSISequence:(char)cmd {
    NSInteger p0 = [self csiParamAtIndex:0 default:1];
    NSInteger p1 = [self csiParamAtIndex:1 default:1];

    switch (cmd) {
        case 'A':
            if ([_delegate respondsToSelector:@selector(vt100MoveCursorUp:)])
                [_delegate vt100MoveCursorUp:p0];
            break;
        case 'B':
            if ([_delegate respondsToSelector:@selector(vt100MoveCursorDown:)])
                [_delegate vt100MoveCursorDown:p0];
            break;
        case 'C':
            if ([_delegate respondsToSelector:@selector(vt100MoveCursorRight:)])
                [_delegate vt100MoveCursorRight:p0];
            break;
        case 'D':
            if ([_delegate respondsToSelector:@selector(vt100MoveCursorLeft:)])
                [_delegate vt100MoveCursorLeft:p0];
            break;
        case 'H': case 'f':
            if ([_delegate respondsToSelector:@selector(vt100MoveCursorToRow:column:)])
                [_delegate vt100MoveCursorToRow:(p0 > 0 ? p0 : 1) column:(p1 > 0 ? p1 : 1)];
            break;
        case 'J':
            switch (p0) {
                case 0:
                    if ([_delegate respondsToSelector:@selector(vt100ClearToEndOfScreen)])
                        [_delegate vt100ClearToEndOfScreen];
                    break;
                case 1:
                    if ([_delegate respondsToSelector:@selector(vt100ClearToBeginningOfScreen)])
                        [_delegate vt100ClearToBeginningOfScreen];
                    break;
                case 2: case 3:
                    if ([_delegate respondsToSelector:@selector(vt100ClearScreen)])
                        [_delegate vt100ClearScreen];
                    break;
            }
            break;
        case 'K':
            switch (p0) {
                case 0:
                    if ([_delegate respondsToSelector:@selector(vt100ClearToEndOfLine)])
                        [_delegate vt100ClearToEndOfLine];
                    break;
                case 1:
                    if ([_delegate respondsToSelector:@selector(vt100ClearToBeginningOfLine)])
                        [_delegate vt100ClearToBeginningOfLine];
                    break;
                case 2:
                    if ([_delegate respondsToSelector:@selector(vt100ClearLine)])
                        [_delegate vt100ClearLine];
                    break;
            }
            break;
        case 'L':
            if ([_delegate respondsToSelector:@selector(vt100InsertLines:)])
                [_delegate vt100InsertLines:p0];
            break;
        case 'M':
            if ([_delegate respondsToSelector:@selector(vt100DeleteLines:)])
                [_delegate vt100DeleteLines:p0];
            break;
        case 'P':
            if ([_delegate respondsToSelector:@selector(vt100DeleteCharacters:)])
                [_delegate vt100DeleteCharacters:p0];
            break;
        case '@':
            if ([_delegate respondsToSelector:@selector(vt100InsertCharacters:)])
                [_delegate vt100InsertCharacters:p0];
            break;
        case 'r':
            if ([_delegate respondsToSelector:@selector(vt100SetScrollRegionTop:bottom:)])
                [_delegate vt100SetScrollRegionTop:(p0 > 0 ? p0 : 1) bottom:(p1 > 0 ? p1 : 24)];
            break;
        case 'S':
            if ([_delegate respondsToSelector:@selector(vt100ScrollUp:)])
                [_delegate vt100ScrollUp:p0];
            break;
        case 'T':
            if (p0 == 0 && [_delegate respondsToSelector:@selector(vt100ScrollDown:)])
                [_delegate vt100ScrollDown:p1];
            break;
        case 'h': case 'l': {
            BOOL set = (cmd == 'h');
            if (p0 == 25) {
                if ([_delegate respondsToSelector:@selector(vt100SetCursorVisible:)])
                    [_delegate vt100SetCursorVisible:set];
            }
            break;
        }
        default:
            break;
    }
}

- (void)handleOSCEnd {
    if (!_OSCString) return;
    NSUInteger len = [_OSCString length];
    if (len >= 2) {
        unichar firstChar = [_OSCString characterAtIndex:0];
        unichar secondChar = [_OSCString characterAtIndex:1];
        if ((firstChar == '0' || firstChar == '2') && secondChar == ';') {
            NSString *titleStr = nil;
            if (len > 2)
                titleStr = [_OSCString substringFromIndex:2];
            if (_title != titleStr) {
                _title = titleStr;
            }
            if ([_delegate respondsToSelector:@selector(vt100SetTitle:)])
                [_delegate vt100SetTitle:_title];
        }
    }
    _sequence = kSequenceNone;
    _OSCString = nil;
}

- (void)dealloc {
    [self clearCSIParams];
    _OSCString = nil;
    _title = nil;
    if (_encbuf) free(_encbuf);
}

@end
