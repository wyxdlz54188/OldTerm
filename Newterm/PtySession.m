#import "PtySession.h"
#import <sys/ioctl.h>
#import <sys/types.h>
#import <sys/wait.h>
#import <unistd.h>
#import <fcntl.h>
#import <util.h>

@implementation PtySession

@synthesize delegate = _delegate, shellPath = _shellPath, masterFd = _masterFd, pid = _pid;

- (id)initWithShell:(NSString *)shell {
    if ((self = [super init])) {
        _shellPath = [shell copy];
        _masterFd = -1;
        _pid = -1;
    }
    return self;
}

- (void)start {
    if (_shellPath == nil) {
        _shellPath = @"/bin/bash";
    }
    
    struct winsize win = {
        .ws_row = 24,
        .ws_col = 80,
        .ws_xpixel = 0,
        .ws_ypixel = 0
    };
    
    _pid = forkpty(&_masterFd, NULL, NULL, &win);
    
    if (_pid < 0) {
        NSLog(@"Failed to create PTY");
        return;
    } else if (_pid == 0) {
        setenv("TERM", "xterm-color", 1);
        setenv("PS1", "\\u@\\h \\w\\$ ", 1);
        setenv("HOME", "/var/mobile", 1);
        
        system("stty erase ^? 2>/dev/null");
        
        const char *shellPath = [_shellPath UTF8String];
        const char *shellName = [[_shellPath lastPathComponent] UTF8String];
        execl(shellPath, shellName, "--login", NULL);
        exit(1);
    }
    
    fcntl(_masterFd, F_SETFL, fcntl(_masterFd, F_GETFL, 0) | O_NONBLOCK);
    
    NSLog(@"PTY session started (PID: %d)", _pid);
    
    [self startReading];
}

- (void)startReading {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (_masterFd > 0) {
            char buffer[4096];
            ssize_t bytesRead = read(_masterFd, buffer, sizeof(buffer));
            
            if (bytesRead > 0) {
                NSData *data = [NSData dataWithBytes:buffer length:bytesRead];
                if ([_delegate respondsToSelector:@selector(ptySession:didReceiveData:)]) {
                    [_delegate ptySession:self didReceiveData:data];
                }
            } else if (bytesRead < 0 && errno == EAGAIN) {
            } else {
                if ([_delegate respondsToSelector:@selector(ptySessionDidFinish:)]) {
                    [_delegate ptySessionDidFinish:self];
                }
                return;
            }
            
            [self startReading];
        }
    });
}

- (void)write:(NSData *)data {
    if (_masterFd > 0) {
        write(_masterFd, [data bytes], [data length]);
    }
}

- (void)close {
    if (_pid > 0) {
        kill(_pid, SIGTERM);
        waitpid(_pid, NULL, 0);
        _pid = -1;
    }
    
    if (_masterFd > 0) {
        close(_masterFd);
        _masterFd = -1;
    }
    
    NSLog(@"PTY session closed");
}

- (void)dealloc {
    if (_pid > 0) {
        [self close];
    }
}

@end