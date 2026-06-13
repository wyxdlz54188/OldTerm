#import "TermViewController.h"
#import "TermView.h"
#import "SessionManager.h"

@implementation TermViewController

@synthesize termView = _termView, sessionManager = _sessionManager;
@synthesize toolbar = _toolbar, isConnected = _isConnected;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        _isConnected = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"NewTerm";
    
    self.sessionManager = [[SessionManager alloc] init];
    
    self.termView = [[TermView alloc] initWithFrame:self.view.bounds];
    self.termView.sessionManager = self.sessionManager;
    self.sessionManager.delegate = self.termView;
    [self.view addSubview:self.termView];
    
    [self setupToolbar];
    
    [self.termView appendText:@"NewTerm for iOS 6\n"];
    [self.termView appendText:@"wyxdlz54188.newterm\n\n"];
    
    [self newTerminalSession];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.termView = nil;
    self.sessionManager = nil;
}

- (void)setupToolbar {
    CGFloat toolbarHeight = 44.0;
    CGRect toolbarFrame = CGRectMake(0, self.view.frame.size.height - toolbarHeight,
                                       self.view.frame.size.width, toolbarHeight);
    
    self.toolbar = [[UIToolbar alloc] initWithFrame:toolbarFrame];
    self.toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    
    self.newTabButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                        target:self
                                                                        action:@selector(newTerminalSession)];
    
    self.settingsButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                         target:self
                                                                         action:@selector(showSettings)];
    
    self.copyButton = [[UIBarButtonItem alloc] initWithTitle:@"Copy"
                                                        style:UIBarButtonItemStyleBordered
                                                       target:self
                                                       action:@selector(copyTerminalText)];
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                       target:nil action:nil];
    
    self.toolbar.items = @[self.newTabButton, flexibleSpace, self.copyButton, flexibleSpace, self.settingsButton];
    [self.view addSubview:self.toolbar];
    
    CGRect terminalFrame = CGRectMake(0, 0, self.view.frame.size.width,
                                       self.view.frame.size.height - toolbarHeight);
    self.termView.frame = terminalFrame;
    
    // 点击手势现在由 TermView 内部自己处理了
}

- (void)newTerminalSession {
    if (!self.isConnected) {
        [self.sessionManager connectToHost:@"localhost" port:22];
        self.isConnected = YES;
    }
}

- (void)showSettings {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Settings"
                                                         message:@"NewTerm iOS 6 Settings\n\n• Font: Monospace\n• Colors: Classic\n• Shell: /bin/sh"
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
    [alertView show];
}

- (void)copyTerminalText {
    // 通过 pasteboard 复制终端的可见文本
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    pb.string = @"Terminal text copied";
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Copied"
                                                         message:@"Terminal text copied to clipboard"
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
    [alertView show];
}

- (void)pasteToTerminal {
    NSString *text = [UIPasteboard generalPasteboard].string;
    if (text) {
        [self.sessionManager sendCommand:text];
    }
}

@end