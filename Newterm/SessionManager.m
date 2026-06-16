#import "SessionManager.h"
#import <sys/ioctl.h>
#import <sys/types.h>
#import <sys/wait.h>
#import <unistd.h>
#import <fcntl.h>
#import <util.h>
#import <signal.h>

@interface SessionManager () {
    int _ptyFd;
    pid_t _childPid;
    NSFileHandle *_fileHandle;
}
@end

@implementation SessionManager

@synthesize delegate = _delegate, host = _host, port = _port, isConnected = _isConnected;
@synthesize childPid = _childPid, ptyFd = _ptyFd;

- (id)init {
    if ((self = [super init])) {
        _isConnected = NO;
        _ptyFd = -1;
        _childPid = -1;
        _fileHandle = nil;
    }
    return self;
}

- (void)connectToHost:(NSString *)host port:(NSInteger)port {
    self.host = host;
    self.port = port;

    if ([host isEqualToString:@"localhost"]) {
        [self startLocalShell];
    } else {
        NSLog(@"Remote connection to %@:%ld (not implemented for iOS 6)", host, (long)port);
    }

    if ([_delegate respondsToSelector:@selector(sessionDidConnect)]) {
        [_delegate sessionDidConnect];
    }

    self.isConnected = YES;
}

- (void)startLocalShell {
    struct winsize win = {
        .ws_row = 24,
        .ws_col = 80,
        .ws_xpixel = 0,
        .ws_ypixel = 0
    };

    int master;
    pid_t pid = forkpty(&master, NULL, NULL, &win);

    if (pid < 0) {
        NSLog(@"forkpty failed: %d (%s)", errno, strerror(errno));
        if ([_delegate respondsToSelector:@selector(session:didFailWithError:)]) {
            NSDictionary *userInfo = @{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"forkpty failed: %s", strerror(errno)]
            };
            NSError *error = [NSError errorWithDomain:@"SessionManager" code:errno userInfo:userInfo];
            [_delegate session:self didFailWithError:error];
        }
        return;
    } else if (pid == 0) {
        setenv("TERM", "xterm-color", 1);
        setenv("PS1", "\\u@\\h \\w\\$ ", 1);
        setenv("HOME", "/var/mobile", 1);

        if (execve("/usr/bin/login",
            (char *[]){"login", "-fp", getlogin(), NULL},
            (char *[]){"TERM=xterm", NULL}) == -1) {
            execl("/bin/bash", "bash", "--login", NULL);
            execl("/bin/sh", "sh", NULL);
        }
        exit(127);
    }

    _ptyFd = master;
    _childPid = pid;

    fcntl(_ptyFd, F_SETFL, fcntl(_ptyFd, F_GETFL, 0) | O_NONBLOCK);

    [self setupReadHandler];

    NSLog(@"Shell started (PID: %d, FD: %d)", pid, _ptyFd);
}

- (void)setupReadHandler {
    if (_ptyFd <= 0) return;

    _fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:_ptyFd closeOnDealloc:NO];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ptyDataAvailable:)
                                                 name:NSFileHandleReadCompletionNotification
                                               object:_fileHandle];

    [_fileHandle readInBackgroundAndNotify];
}

- (void)ptyDataAvailable:(NSNotification *)notification {
    NSData *data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];

    if (data && [data length] > 0) {
        if ([_delegate respondsToSelector:@selector(session:didReceiveData:)]) {
            [_delegate session:self didReceiveData:data];
        }
        [_fileHandle readInBackgroundAndNotify];
        return;
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSFileHandleReadCompletionNotification
                                                  object:_fileHandle];

    int status = 0;
    waitpid(_childPid, &status, 0);

    if (data && [data length] == 0 && WIFEXITED(status)) {
        char exitMsg[64];
        int len = snprintf(exitMsg, sizeof(exitMsg), "\r\n[Exit %d]\r\n", WEXITSTATUS(status));
        NSData *exitData = [NSData dataWithBytes:exitMsg length:len];
        if ([_delegate respondsToSelector:@selector(session:didReceiveData:)]) {
            [_delegate session:self didReceiveData:exitData];
        }
    } else if (WIFSIGNALED(status)) {
        char sigMsg[64];
        int len = snprintf(sigMsg, sizeof(sigMsg), "\r\n[%s]\r\n", strsignal(WTERMSIG(status)));
        NSData *sigData = [NSData dataWithBytes:sigMsg length:len];
        if ([_delegate respondsToSelector:@selector(session:didReceiveData:)]) {
            [_delegate session:self didReceiveData:sigData];
        }
    }

    _ptyFd = -1;
    _childPid = -1;
    _fileHandle = nil;

    if ([_delegate respondsToSelector:@selector(sessionDidDisconnect)]) {
        [_delegate sessionDidDisconnect];
    }

    self.isConnected = NO;
}

- (void)resizeToColumns:(NSInteger)cols rows:(NSInteger)rows {
    if (_ptyFd == -1) return;
    if (cols < 4) cols = 4;
    if (rows < 2) rows = 2;

    struct winsize win = {
        .ws_col = (unsigned short)cols,
        .ws_row = (unsigned short)rows,
        .ws_xpixel = 0,
        .ws_ypixel = 0
    };

    if (ioctl(_ptyFd, TIOCSWINSZ, &win) == -1) {
        NSLog(@"ioctl(TIOCSWINSZ) failed: %s", strerror(errno));
    }
}

- (void)disconnect {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSFileHandleReadCompletionNotification
                                                  object:_fileHandle];

    _fileHandle = nil;

    if (_childPid > 0) {
        kill(_childPid, SIGHUP);
        usleep(100000);
        if (waitpid(_childPid, NULL, WNOHANG) == 0) {
            kill(_childPid, SIGTERM);
            usleep(100000);
            if (waitpid(_childPid, NULL, WNOHANG) == 0) {
                kill(_childPid, SIGKILL);
                waitpid(_childPid, NULL, 0);
            }
        }
        _childPid = -1;
    }

    if (_ptyFd > 0) {
        close(_ptyFd);
        _ptyFd = -1;
    }

    self.isConnected = NO;

    if ([_delegate respondsToSelector:@selector(sessionDidDisconnect)]) {
        [_delegate sessionDidDisconnect];
    }

    NSLog(@"Session disconnected");
}

- (void)sendCommand:(NSString *)command {
    if (self.isConnected && _ptyFd > 0) {
        const char *str = [command UTF8String];
        write(_ptyFd, str, strlen(str));
    }
}

- (void)sendData:(NSData *)data {
    if (_ptyFd > 0) {
        write(_ptyFd, [data bytes], [data length]);
    }
}

- (void)dealloc {
    if (self.isConnected) {
        [self disconnect];
    }
}

@end
