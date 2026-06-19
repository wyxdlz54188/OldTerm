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
    webView.scrollView.bounces = YES;
    webView.scrollView.alwaysBounceVertical = YES;
    [view addSubview:webView];
    
    // 加载远程 Markdown 文件
    NSURL *url = [NSURL URLWithString:@"http://wyxdlz54188.github.io/repo/debs/io.github.wyxdlz54188.oldterm/About.md"];
    NSString *mdContent = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    
    if (mdContent) {
        NSString *html = [NSString stringWithFormat:@"<!DOCTYPE html><html><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1,maximum-scale=1\"><style>body{font-family:-apple-system,Helvetica;font-size:15px;color:#333;padding:16px;line-height:1.6}h1{font-size:24px;text-align:center}h2{font-size:18px;color:#555}table{width:100%%;border-collapse:collapse}td,th{border:1px solid #ddd;padding:8px;text-align:left}th{background:#f5f5f5}code{background:#f0f0f0;padding:2px 6px;border-radius:3px}hr{border:none;border-top:1px solid #eee}img{max-width:100%%}a{color:#0366d6}</style></head><body>%@</body></html>", mdContent];
        
        [webView loadHTMLString:html baseURL:nil];
    } else {
        [webView loadHTMLString:@"<html><body style='font-family:-apple-system;padding:20px;color:#999;text-align:center;'><p>加载失败</p></body></html>" baseURL:nil];
    }
    
    [webView release];
}

@end