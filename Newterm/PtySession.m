#import "PtySession.h"
#import <sys/ioctl.h>
#import <sys/types.h>
#import <sys/wait.h>
#import <unistd.h>
#import <fcntl.h>
#import <util.h>
#import <signal.h>

@implementation PtySession

@synthesize delegate = _delegate, shellPath = _shellPath, masterFd = _masterFd, pid = _pid;
@dynamic isRunning;

- (id)initWithShell:(NSString *)shell {
    return [self initWithShell:shell columns:80 rows:24];
}

- (id)initWithShell:(NSString *)shell columns:(NSInteger)cols rows:(NSInteger)rows {
    if ((self = [super init])) {
        _shellPath = [shell copy];
        _masterFd = -1;
        _pid = -1;
        _readSource = NULL;
    }
    return self;
}

- (BOOL)isRunning {
    return (_masterFd != -1 && _pid > 0);
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
        NSLog(@"forkpty failed: %d (%s)", errno, strerror(errno));
        if ([_delegate respondsToSelector:@selector(ptySession:didFailWithError:)]) {
            NSDictionary *userInfo = @{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"forkpty failed: %s", strerror(errno)]
            };
            NSError *error = [NSError errorWithDomain:@"PtySession" code:errno userInfo:userInfo];
            [_delegate ptySession:self didFailWithError:error];
        }
        return;
    } else if (_pid == 0) {
        setenv("TERM", "xterm-color", 1);
        setenv("PS1", "\\u@\\h \\w\\$ ", 1);
        setenv("HOME", "/var/mobile", 1);

        if (execve("/usr/bin/login",
            (char *[]){"login", "-fp", getlogin(), NULL},
            (char *[]){"TERM=xterm", NULL}) == -1) {
            const char *shellPath = [_shellPath UTF8String];
            const char *shellName = [[_shellPath lastPathComponent] UTF8String];
            execl(shellPath, shellName, "--login", NULL);
            execl("/bin/sh", "sh", NULL);
        }
        exit(127);
    }

    fcntl(_masterFd, F_SETFL, fcntl(_masterFd, F_GETFL, 0) | O_NONBLOCK);

    [self setupReadSource];

    NSLog(@"PTY session started (PID: %d)", _pid);
}

- (void)setupReadSource {
    if (_masterFd <= 0) return;

    _readSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ,
        (uintptr_t)_masterFd, 0, dispatch_get_main_queue());

    dispatch_source_set_event_handler(_readSource, ^{
        unsigned char buffer[4096];
        ssize_t bytesRead;

        while (1) {
            bytesRead = read(_masterFd, buffer, sizeof(buffer));
            if (bytesRead > 0) {
                NSData *data = [NSData dataWithBytes:buffer length:bytesRead];
                if ([_delegate respondsToSelector:@selector(ptySession:didReceiveData:)]) {
                    [_delegate ptySession:self didReceiveData:data];
                }
                continue;
            }

            if (bytesRead < 0 && (errno == EINTR || errno == EAGAIN)) break;

            if (_readSource) {
                dispatch_source_cancel(_readSource);
                _readSource = NULL;
            }

            if (bytesRead < 0) kill(_pid, SIGKILL);

            int status = 0;
            waitpid(_pid, &status, 0);

            if (bytesRead == 0 && WIFEXITED(status)) {
                char exitMsg[64];
                int len = snprintf(exitMsg, sizeof(exitMsg), "\r\n[Exit %d]\r\n", WEXITSTATUS(status));
                NSData *data = [NSData dataWithBytes:exitMsg length:len];
                if ([_delegate respondsToSelector:@selector(ptySession:didReceiveData:)]) {
                    [_delegate ptySession:self didReceiveData:data];
                }
            } else if (WIFSIGNALED(status)) {
                char sigMsg[64];
                int len = snprintf(sigMsg, sizeof(sigMsg), "\r\n[%s]\r\n", strsignal(WTERMSIG(status)));
                NSData *data = [NSData dataWithBytes:sigMsg length:len];
                if ([_delegate respondsToSelector:@selector(ptySession:didReceiveData:)]) {
                    [_delegate ptySession:self didReceiveData:data];
                }
            }

            _masterFd = -1;
            _pid = -1;

            if ([_delegate respondsToSelector:@selector(ptySessionDidFinish:)]) {
                [_delegate ptySessionDidFinish:self];
            }
            return;
        }
    });

    dispatch_source_set_cancel_handler(_readSource, ^{
        if (_masterFd > 0) {
            close(_masterFd);
            _masterFd = -1;
        }
    });

    dispatch_resume(_readSource);
}

- (void)writeData:(NSData *)data {
    if (_masterFd > 0) {
        write(_masterFd, [data bytes], [data length]);
    }
}

- (void)writeString:(NSString *)string {
    if (_masterFd > 0 && string) {
        const char *str = [string UTF8String];
        if (str) write(_masterFd, str, strlen(str));
    }
}

- (void)resizeToColumns:(NSInteger)cols rows:(NSInteger)rows {
    if (_masterFd == -1) return;
    if (cols < 4) cols = 4;
    if (rows < 2) rows = 2;

    struct winsize win = {
        .ws_col = (unsigned short)cols,
        .ws_row = (unsigned short)rows,
        .ws_xpixel = 0,
        .ws_ypixel = 0
    };

    if (ioctl(_masterFd, TIOCSWINSZ, &win) == -1) {
        NSLog(@"ioctl(TIOCSWINSZ) failed: %s", strerror(errno));
    }
}

- (void)close {
    if (_readSource) {
        dispatch_source_cancel(_readSource);
        dispatch_release(_readSource);
        _readSource = NULL;
    }

    if (_pid > 0) {
        kill(_pid, SIGHUP);
        usleep(100000);
        if (waitpid(_pid, NULL, WNOHANG) == 0) {
            kill(_pid, SIGTERM);
            usleep(100000);
            if (waitpid(_pid, NULL, WNOHANG) == 0) {
                kill(_pid, SIGKILL);
                waitpid(_pid, NULL, 0);
            }
        }
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
