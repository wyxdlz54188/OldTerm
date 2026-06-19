#import "MTAboutController.h"

@implementation MTAboutController

- (void)loadView {
    [self setTitle:@"关于"];
    
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.backgroundColor = [UIColor whiteColor];
    self.view = view;
    [view release];
    
    // 创建 WebView
    UIWebView *webView = [[UIWebView alloc] initWithFrame:view.bounds];
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    webView.backgroundColor = [UIColor whiteColor];
    webView.opaque = YES;
    webView.scalesPageToFit = YES;
    [view addSubview:webView];
    
    // 加载远程 Markdown 文件（替换为你的实际 URL）
    NSURL *url = [NSURL URLWithString:@"http://wyxdlz54188.github.io/repo/debs/io.github.wyxdlz54188.oldterm/About.md"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [webView loadRequest:request];
    
    [webView release];
}

@end