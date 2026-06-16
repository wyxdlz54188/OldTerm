#import "TermViewController.h"
#import "TermView.h"
#import "SessionManager.h"
#import "SettingsViewController.h"

@interface TermViewController () {
    CGFloat _kbHeight;
    BOOL _keyboardVisible;
}
@end

@implementation TermViewController

@synthesize termView = _termView, sessionManager = _sessionManager;
@synthesize toolbar = _toolbar, isConnected = _isConnected;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        _isConnected = NO;
        _kbHeight = 0;
        _keyboardVisible = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"NewTerm";

    self.sessionManager = [[SessionManager alloc] init];

    CGFloat toolbarHeight = 44.0;
    CGRect terminalFrame = CGRectMake(0, 0, self.view.frame.size.width,
                                       self.view.frame.size.height - toolbarHeight);

    self.termView = [[TermView alloc] initWithFrame:terminalFrame];
    self.termView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.termView.sessionManager = self.sessionManager;
    self.sessionManager.delegate = self.termView;
    [self.view addSubview:self.termView];

    [self setupToolbar];
    [self setupKeyboardNotifications];

    [self.termView appendText:@"NewTerm for iOS 6\n"];
    [self.termView appendText:@"wyxdlz54188.newterm\n\n"];

    [self newTerminalSession];
}

- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

    self.settingsButton = [[UIBarButtonItem alloc] initWithTitle:@"Settings"
                                                             style:UIBarButtonItemStyleBordered
                                                            target:self
                                                            action:@selector(showSettings)];

    self.copyButton = [[UIBarButtonItem alloc] initWithTitle:@"Copy"
                                                         style:UIBarButtonItemStyleBordered
                                                        target:self
                                                        action:@selector(copyTerminalText)];

    UIBarButtonItem *kbToggleButton = [[UIBarButtonItem alloc] initWithTitle:@"KB"
                                                                         style:UIBarButtonItemStyleBordered
                                                                        target:self
                                                                        action:@selector(toggleKeyboard)];

    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                       target:nil action:nil];

    self.toolbar.items = @[self.newTabButton, flexibleSpace, kbToggleButton,
                           flexibleSpace, self.copyButton, flexibleSpace, self.settingsButton];
    [self.view addSubview:self.toolbar];
}

- (void)setupKeyboardNotifications {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(keyboardWillShow:)
                   name:UIKeyboardWillShowNotification object:nil];
    [center addObserver:self selector:@selector(keyboardWillHide:)
                   name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    _keyboardVisible = YES;
    NSDictionary *info = [notification userInfo];
    CGRect keyboardFrame = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];

    CGRect convertedFrame = [self.view convertRect:keyboardFrame fromView:nil];
    _kbHeight = convertedFrame.size.height;

    [self adjustForKeyboard];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    _keyboardVisible = NO;
    _kbHeight = 0;
    [self adjustForKeyboard];
}

- (void)adjustForKeyboard {
    UIEdgeInsets inset = self.termView.contentInset;
    inset.bottom = _kbHeight;
    self.termView.contentInset = inset;
    self.termView.scrollIndicatorInsets = inset;
}

- (void)toggleKeyboard {
    if ([self.termView isFirstResponder]) {
        [self.termView hideKeyboard];
    } else {
        [self.termView showKeyboard];
    }
}

#pragma mark - Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.termView setNeedsLayout];
}

#pragma mark - Actions

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
        NSData *pasteData = [text dataUsingEncoding:NSUTF8StringEncoding];
        if (pasteData) {
            [self.sessionManager sendData:pasteData];
        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
