#import "SessionManager.h"
#import <sys/ioctl.h>
#import <sys/types.h>
#import <sys/wait.h>
#import <unistd.h>
#import <fcntl.h>
#import <util.h>

@implementation SessionManager

@synthesize delegate = _delegate, host = _host, port = _port, isConnected = _isConnected;

- (id)init {
    if ((self = [super init])) {
        _isConnected = NO;
        _ptyFd = -1;
        _childPid = -1;
    }
    return self;
}

- (void)connectToHost:(NSString *)host
                  port:(NSInteger)port
             completion:(void(^)(NSError *error))completion {
    self.host = host;
    self.port = port;
    
    NSError *error = nil;
    if ([host isEqualToString:@"localhost"]) {
        // 本地 shell，尝试启动
        @try {
            [self startLocalShell];
        } @catch (NSException *exception) {
            // 将异常转为 NSError
            error = [NSError errorWithDomain:@"com.newterm.session"
                                        code:1001
                                    userInfo:@{NSLocalizedDescriptionKey:exception.reason}];
        }
    } else {
        // 远程连接当前未实现，返回错误
        error = [NSError errorWithDomain:@"com.newterm.session"
                                    code:1002
                                userInfo:@{NSLocalizedDescriptionKey:
                                          [NSString stringWithFormat:NSLocalizedString(@"Remote connection to %@:%ld not supported", nil), host, (long)port]}];
    }
    
    if (error) {
        if ([_delegate respondsToSelector:@selector(session:didFailWithError:)]) {
            [_delegate session:self didFailWithError:error];
        }
        if (completion) {
            completion(error);
        }
        return;
    }
    
    // 成功连通
    self.isConnected = YES;
    if ([_delegate respondsToSelector:@selector(sessionDidConnect)]) {
        [_delegate sessionDidConnect];
    }
    if (completion) {
        completion(nil);
    }
}

// 兼容旧接口（不返回错误）
- (void)connectToHost:(NSString *)host port:(NSInteger)port {
    [self connectToHost:host port:port completion:nil];
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
        NSLog(@"Failed to create PTY: %d", errno);
        return;
    } else if (pid == 0) {
        setenv("TERM", "xterm-color", 1);
        setenv("PS1", "\\u@\\h \\w\\$ ", 1);
        setenv("HOME", "/var/mobile", 1);
        
        system("stty erase ^? 2>/dev/null");
        
        execl("/bin/bash", "bash", "--login", NULL);
        execl("/bin/sh", "sh", NULL);
        exit(127);
    }
    
    _ptyFd = master;
    _childPid = pid;
    
    fcntl(_ptyFd, F_SETFL, fcntl(_ptyFd, F_GETFL, 0) | O_NONBLOCK);
    
    [self startReadingPTY];
    
    NSLog(@"Local shell started (PID: %d, FD: %d)", pid, _ptyFd);
}

- (void)startReadingPTY {
    if (_ptyFd <= 0) {
        return;
    }
    
    char buffer[4096];
    ssize_t bytesRead = read(_ptyFd, buffer, sizeof(buffer));
    
    if (bytesRead > 0) {
        NSData *data = [NSData dataWithBytes:buffer length:bytesRead];
        if ([_delegate respondsToSelector:@selector(session:didReceiveData:)]) {
            [_delegate session:self didReceiveData:data];
        }
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self startReadingPTY];
    });
}

- (void)disconnect {
    if (self.isConnected) {
        if (_childPid > 0) {
            kill(_childPid, SIGTERM);
            waitpid(_childPid, NULL, 0);
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