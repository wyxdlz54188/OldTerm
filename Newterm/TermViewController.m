#import "TermViewController.h"
#import "TermView.h"
#import "SessionManager.h"
#import "SettingsViewController.h"
// #import "AlertHelper.h"  // removed

@implementation TermViewController

// @synthesize termView = _termView, sessionManager = _sessionManager; // removed (ARC)
// @synthesize toolbar = _toolbar, isConnected = _isConnected; // removed (ARC)

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        _isConnected = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"NewTerm", nil);
    
    self.sessionManager = [[SessionManager alloc] init];
    
    // 🔥 关键：termView 的 frame 要留出 toolbar 的空间
    CGFloat toolbarHeight = 44.0;
    CGRect terminalFrame = CGRectMake(0, 0, self.view.frame.size.width,
                                       self.view.frame.size.height - toolbarHeight);
    
    self.termView = [[TermView alloc] initWithFrame:terminalFrame];
    self.termView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.termView.sessionManager = self.sessionManager;
    self.sessionManager.delegate = self.termView;
    [self.view addSubview:self.termView];
    
    [self setupToolbar];
    
    [self.termView appendText:@"NewTerm for iOS 6\n"];
    [self.termView appendText:@"wyxdlz54188.newterm\n\n"];
    
    [self newTerminalSession];
}

/* viewDidUnload removed – ARC handles deallocation */

- (void)setupToolbar {
    CGFloat toolbarHeight = 44.0;
    CGRect toolbarFrame = CGRectMake(0, self.view.frame.size.height - toolbarHeight,
                                       self.view.frame.size.width, toolbarHeight);
    
    self.toolbar = [[UIToolbar alloc] initWithFrame:toolbarFrame];
    self.toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    
    self.addTabButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                 target:self
                 action:@selector(newTerminalSession)];
    
self.settingsButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"设置", nil)
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(showSettings)];
    
    self.copyBarButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Copy", nil)
                                                    style:UIBarButtonItemStylePlain
                                                   target:self
                                                   action:@selector(copyTerminalText)];
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                       target:nil action:nil];
    
    self.toolbar.items = @[self.addTabButton, flexibleSpace, self.copyBarButton, flexibleSpace, self.settingsButton];
    [self.view addSubview:self.toolbar];
}

- (void)newTerminalSession {
    if (!self.isConnected) {
        [self.sessionManager connectToHost:@"localhost" port:22];
        self.isConnected = YES;
    }
}

- (void)showSettings {
    SettingsViewController *settingsVC = [[SettingsViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)copyTerminalText {
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    pb.string = @"Terminal text copied";
    
    #pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"已复制", nil)
                                                    message:NSLocalizedString(@"终端文本已复制到剪贴板", nil)
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil];
[alert show];
#pragma clang diagnostic pop
}

- (void)pasteToTerminal {
    NSString *text = [UIPasteboard generalPasteboard].string;
    if (text) {
        NSData *pasteData = [text dataUsingEncoding:NSUTF8StringEncoding];
        if (pasteData) {
            [self.sessionManager sendData:pasteData];
        }
    }
}

@end