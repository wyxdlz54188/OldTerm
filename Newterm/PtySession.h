#import <Foundation/Foundation.h>

@protocol PtySessionDelegate;

@interface PtySession : NSObject {
    __unsafe_unretained id<PtySessionDelegate> _delegate;
    int _masterFd;
    pid_t _pid;
    NSString *_shellPath;
    dispatch_source_t _readSource;
}

@property (nonatomic, unsafe_unretained) id<PtySessionDelegate> delegate;
@property (nonatomic, retain) NSString *shellPath;
@property (nonatomic, readonly) int masterFd;
@property (nonatomic, readonly) pid_t pid;
@property (nonatomic, readonly) BOOL isRunning;

- (id)initWithShell:(NSString *)shell;
- (id)initWithShell:(NSString *)shell columns:(NSInteger)cols rows:(NSInteger)rows;
- (void)start;
- (void)writeData:(NSData *)data;
- (void)writeString:(NSString *)string;
- (void)resizeToColumns:(NSInteger)cols rows:(NSInteger)rows;
- (void)close;

@end

@protocol PtySessionDelegate <NSObject>
@required
- (void)ptySession:(PtySession *)session didReceiveData:(NSData *)data;
@optional
- (void)ptySessionDidFinish:(PtySession *)session;
- (void)ptySession:(PtySession *)session didFailWithError:(NSError *)error;
@end
