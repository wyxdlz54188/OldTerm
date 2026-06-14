#import <UIKit/UIKit.h>

@class TermView;
@class SessionManager;
@interface TermViewController : UIViewController
 
 @property (strong, nonatomic) TermView *termView;
 @property (strong, nonatomic) SessionManager *sessionManager;
 @property (strong, nonatomic) UIToolbar *toolbar;
 @property (strong, nonatomic) UIBarButtonItem *addTabButton;
 @property (strong, nonatomic) UIBarButtonItem *settingsButton;
 @property (strong, nonatomic) UIBarButtonItem *copyBarButton;
 @property (assign, nonatomic) BOOL isConnected;
 
 // 方法声明
 - (void)newTerminalSession;
 - (void)showSettings;
 - (void)copyTerminalText;
 - (void)pasteToTerminal;
 
 @end