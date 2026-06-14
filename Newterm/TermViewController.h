#import <UIKit/UIKit.h>

@class TermView;
@class SessionManager;
@interface TermViewController : UIViewController

@property (strong, nonatomic) TermView *termView;
@property (strong, nonatomic) SessionManager *sessionManager;
@property (strong, nonatomic) UIToolbar *toolbar;
@property (strong, nonatomic) UIBarButtonItem *newTabButton;
@property (strong, nonatomic) UIBarButtonItem *settingsButton;
@property (strong, nonatomic) UIBarButtonItem *copyButton;
@property (assign, nonatomic) BOOL isConnected;

@end

- (void)newTerminalSession;
- (void)showSettings;
- (void)copyTerminalText;
- (void)pasteToTerminal;

@end