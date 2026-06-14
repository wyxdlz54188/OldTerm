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

/**
 * Connect to the given host/port.
 * Completion block returns an NSError if the connection fails, otherwise nil.
 * Passing nil for completion retains backward compatibility.
 */
- (void)connectToHost:(NSString *)host
                  port:(NSInteger)port
             completion:(void(^)(NSError *error))completion;

// 兼容旧接口（不返回错误）
- (void)connectToHost:(NSString *)host port:(NSInteger)port;
- (void)disconnect;
- (void)sendCommand:(NSString *)command;
- (void)sendData:(NSData *)data;

@end