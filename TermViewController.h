#import <UIKit/UIKit.h>

@class TermView;
@class SessionManager;

@interface TermViewController : UIViewController {
    TermView *_termView;
    SessionManager *_sessionManager;
    UIToolbar *_toolbar;
    UIBarButtonItem *_newTabButton;
    UIBarButtonItem *_settingsButton;
    UIBarButtonItem *_copyButton;
    BOOL _isConnected;
}

@property (nonatomic, retain) TermView *termView;
@property (nonatomic, retain) SessionManager *sessionManager;
@property (nonatomic, retain) UIToolbar *toolbar;
@property (nonatomic, retain, getter=getNewButton) UIBarButtonItem *newTabButton;
@property (nonatomic, retain, getter=getSettingsBtn) UIBarButtonItem *settingsButton;
@property (nonatomic, retain, getter=getCopyBtn) UIBarButtonItem *copyButton;
@property (nonatomic, assign) BOOL isConnected;

- (void)newTerminalSession;
- (void)showSettings;
- (void)copyTerminalText;
- (void)pasteToTerminal;

@end
