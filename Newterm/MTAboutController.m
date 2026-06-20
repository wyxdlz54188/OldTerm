#import "MTAboutController.h"
#import "Core/MarkdownParser.h"

@interface MTAboutController () <UIWebViewDelegate>
@end

@implementation MTAboutController

- (void)loadView {
    [self setTitle:@"关于"];
    
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.backgroundColor = [UIColor whiteColor];
    self.view = view;
    [view release];
    
    // 创建 WebView 用于显示
    UIWebView *webView = [[UIWebView alloc] initWithFrame:view.bounds];
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    webView.backgroundColor = [UIColor whiteColor];
    webView.opaque = YES;
    webView.scalesPageToFit = YES;
    webView.scrollView.bounces = YES;
    webView.scrollView.alwaysBounceVertical = YES;
    [view addSubview:webView];
    
    // 异步加载 Markdown
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *mdContent = nil;
        NSURL *url = [NSURL URLWithString:@"http://wyxdlz54188.github.io/repo/debs/io.github.wyxdlz54188.oldterm/About.md"];
        mdContent = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
        
        if (!mdContent) {
            mdContent = @"# NewTerm\n\n"
                         "iOS 6 终端模拟器，支持 VT100/xterm 控制序列。\n\n"
                         "---\n\n"
                         "## 功能特性\n\n"
                         "- 多窗口标签页管理\n"
                         "- 支持 SSH 连接\n"
                         "- 256 色调色板\n"
                         "- 自定义字体与字号\n"
                         "- Markdown 渲染引擎\n\n"
                         "---\n\n"
                         "## 版本信息\n\n"
                         "基于 MobileTerminal 改进，增加 Markdown 渲染、UTF-8 "
                         "多语言支持和现代化设置界面。";
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            MarkdownParser *parser = [[MarkdownParser alloc] init];
            NSAttributedString *attributed = [parser parse:mdContent];
            NSString *html = [self htmlFromAttributedString:attributed];
            [webView loadHTMLString:html baseURL:nil];
            [parser release];
        });
    });
    
    [webView release];
}

- (NSString *)htmlFromAttributedString:(NSAttributedString *)attrString {
    NSMutableString *html = [NSMutableString string];
    
    [html appendString:@"<!DOCTYPE html><html><head><meta charset=\"utf-8\">"];
    [html appendString:@"<meta name=\"viewport\" content=\"width=device-width,initial-scale=1,maximum-scale=1\">"];
    [html appendString:@"<style>"];
    [html appendString:@"body{font-family:-apple-system,Helvetica;font-size:14px;color:#333;padding:16px;line-height:1.6;background:#fff}"];
    [html appendString:@"h1{font-size:24px;text-align:center;margin:16px 0}"];
    [html appendString:@"h2{font-size:18px;color:#555;margin:20px 0 10px}"];
    [html appendString:@"table{width:100%;border-collapse:collapse;margin:10px 0}"];
    [html appendString:@"td,th{border:1px solid #ddd;padding:8px}"];
    [html appendString:@"th{background:#f5f5f5}"];
    [html appendString:@"code{background:#f0f0f0;padding:2px 6px;border-radius:3px}"];
    [html appendString:@"hr{border:none;border-top:1px solid #eee;margin:20px 0}"];
    [html appendString:@"a{color:#0366d6}"];
    [html appendString:@"img{max-width:100%}"];
    [html appendString:@"</style></head><body>"];
    
    // 逐段转换
    [attrString enumerateAttributesInRange:NSMakeRange(0, attrString.length)
                                   options:0
                                usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        NSString *text = [[attrString.string substringWithRange:range] stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
        text = [text stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
        text = [text stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
        text = [text stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"];
        
        UIFont *font = attrs[NSFontAttributeName];
        if (font) {
            CGFloat size = font.pointSize;
            BOOL isBold = [[font fontName] rangeOfString:@"bold" options:NSCaseInsensitiveSearch].location != NSNotFound;
            BOOL isItalic = [[font fontName] rangeOfString:@"italic" options:NSCaseInsensitiveSearch].location != NSNotFound;
            
            if (isBold && isItalic) {
                [html appendFormat:@"<b><i>%@</i></b>", text];
            } else if (isBold && size >= 20) {
                [html appendFormat:@"<h2>%@</h2>", text];
            } else if (isBold) {
                [html appendFormat:@"<b>%@</b>", text];
            } else if (isItalic) {
                [html appendFormat:@"<i>%@</i>", text];
            } else {
                [html appendString:text];
            }
        } else {
            [html appendString:text];
        }
    }];
    
    [html appendString:@"</body></html>"];
    return html;
}

@end