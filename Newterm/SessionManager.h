#import <Foundation/Foundation.h>

@protocol SessionManagerDelegate <NSObject>
- (void)sessionDidConnect;
- (void)sessionDidDisconnect;
- (void)session:(id)session didReceiveData:(NSData *)data;
- (void)session:(id)session didFailWithError:(NSError *)error;
@end

@interface SessionManager : NSObject {
    __unsafe_unretained id<SessionManagerDelegate> _delegate;
    NSString *_host;
    NSInteger _port;
    BOOL _isConnected;
    int _ptyFd;
    pid_t _childPid;
}

@property (nonatomic, unsafe_unretained) id<SessionManagerDelegate> delegate;
@property (nonatomic, retain) NSString *host;
@property (nonatomic, assign) NSInteger port;
@property (nonatomic, assign) BOOL isConnected;

- (void)connectToHost:(NSString *)host port:(NSInteger)port;
- (void)disconnect;
- (void)sendCommand:(NSString *)command;

@end
