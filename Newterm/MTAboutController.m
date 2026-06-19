#import "MTAboutController.h"

@implementation MTAboutController

- (void)loadView {
    [self setTitle:@"关于"];
    
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.backgroundColor = [UIColor whiteColor];
    self.view = view;
    [view release];
    
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
        // 转义 Markdown 中的特殊字符，防止 JS 注入
        mdContent = [mdContent stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
        mdContent = [mdContent stringByReplacingOccurrencesOfString:@"`" withString:@"\\`"];
        mdContent = [mdContent stringByReplacingOccurrencesOfString:@"$" withString:@"\\$"];
        
        NSString *html = [NSString stringWithFormat:
            @"<!DOCTYPE html><html><head>"
            @"<meta charset=\"utf-8\">"
            @"<meta name=\"viewport\" content=\"width=device-width,initial-scale=1,maximum-scale=1\">"
            @"<style>"
            @"body{font-family:-apple-system,Helvetica;font-size:15px;color:#333;padding:16px;line-height:1.6;background:#fff}"
            @"h1{font-size:24px;text-align:center;margin:16px 0}"
            @"h2{font-size:18px;color:#555;margin:20px 0 10px}"
            @"table{width:100%%;border-collapse:collapse;margin:10px 0}"
            @"td,th{border:1px solid #ddd;padding:8px;text-align:left}"
            @"th{background:#f5f5f5;font-weight:bold}"
            @"code{background:#f0f0f0;padding:2px 6px;border-radius:3px;font-family:Courier,monospace}"
            @"pre{background:#f0f0f0;padding:10px;border-radius:4px;overflow-x:auto}"
            @"hr{border:none;border-top:1px solid #eee;margin:20px 0}"
            @"ul,ol{padding-left:20px}"
            @"li{margin:4px 0}"
            @"blockquote{border-left:4px solid #ddd;padding-left:15px;color:#666;margin:10px 0}"
            @"img{max-width:100%%}"
            @"a{color:#0366d6}"
            @".loading{text-align:center;color:#999;padding:50px}"
            @"</style>"
            @"</head><body>"
            @"<div class=\"loading\">正在加载...</div>"
            @"<div id=\"content\"></div>"
            @"<script src=\"https://lizirepo.dpdns.org/js/marked.min.js\"></script>"
            @"<script>"
            @"document.addEventListener('DOMContentLoaded',function(){"
            @"  var mdContent=`%@`;"
            @"  document.getElementById('content').innerHTML=marked.parse(mdContent);"
            @"  document.querySelector('.loading').style.display='none';"
            @"});"
            @"</script>"
            @"</body></html>", mdContent];
        
        [webView loadHTMLString:html baseURL:url];
    } else {
        [webView loadHTMLString:@"<html><body style='font-family:-apple-system;padding:20px;color:#999;text-align:center;'><p>加载失败</p><p>请检查网络连接</p></body></html>" baseURL:nil];
    }
    
    [webView release];
}

@end