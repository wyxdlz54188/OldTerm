#import <Foundation/Foundation.h>

@protocol PtySessionDelegate;

@interface PtySession : NSObject {
    __unsafe_unretained id<PtySessionDelegate> _delegate;
    int _masterFd;
    pid_t _pid;
    NSString *_shellPath;
}

@property (nonatomic, unsafe_unretained) id<PtySessionDelegate> delegate;
@property (nonatomic, retain) NSString *shellPath;
@property (nonatomic, readonly) int masterFd;
@property (nonatomic, readonly) pid_t pid;

- (id)initWithShell:(NSString *)shell;
- (void)start;
- (void)write:(NSData *)data;
- (void)close;

@end

@protocol PtySessionDelegate <NSObject>
- (void)ptySession:(PtySession *)session didReceiveData:(NSData *)data;
- (void)ptySessionDidFinish:(PtySession *)session;
@end
