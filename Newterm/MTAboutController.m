#import "MTAboutController.h"
#import "Core/MarkdownParser.h"

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
    
    // 异步加载并解析
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *url = [NSURL URLWithString:@"http://wyxdlz54188.github.io/repo/debs/io.github.wyxdlz54188.oldterm/About.md"];
        NSString *mdContent = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (mdContent) {
                MarkdownParser *parser = [[MarkdownParser alloc] init];
                NSAttributedString *attributed = [parser parse:mdContent];
                
                NSString *html = [self htmlFromAttributedString:attributed];
                [webView loadHTMLString:html baseURL:nil];
            } else {
                [webView loadHTMLString:@"<html><body style='font-family:-apple-system;padding:20px;color:#999;text-align:center;'><p>加载失败</p></body></html>" baseURL:nil];
            }
        });
    });
    
    [webView release];
}

- (NSString *)htmlFromAttributedString:(NSAttributedString *)attrString {
    NSMutableString *html = [NSMutableString string];
    
    [html appendString:@"<!DOCTYPE html><html><head><meta charset=\"utf-8\">"];
    [html appendString:@"<meta name=\"viewport\" content=\"width=device-width,initial-scale=1,maximum-scale=1\">"];
    [html appendString:@"<style>"];
    [html appendString:@"body{font-family:-apple-system,Helvetica;font-size:15px;color:#333;padding:16px;line-height:1.6;background:#fff}"];
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
    
    [attrString enumerateAttributesInRange:NSMakeRange(0, attrString.length)
                                   options:0
                                usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        NSString *text = [[attrString.string substringWithRange:range] stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
        text = [text stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
        text = [text stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
        text = [text stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"];
        
        UIFont *font = attrs[NSFontAttributeName];
        UIColor *color = attrs[NSForegroundColorAttributeName];
        NSString *url = attrs[@"MarkdownLinkURL"];
        
        NSMutableString *tagged = [NSMutableString stringWithString:text];
        
        if (url) {
            tagged = [NSMutableString stringWithFormat:@"<a href=\"%@\">%@</a>", url, text];
        }
        
        if (font) {
            CGFloat size = font.pointSize;
            BOOL isBold = [[font fontName] rangeOfString:@"bold" options:NSCaseInsensitiveSearch].location != NSNotFound;
            
            if (isBold && size >= 20) {
                tagged = [NSMutableString stringWithFormat:@"<h2>%@</h2>", tagged];
            } else if (isBold) {
                tagged = [NSMutableString stringWithFormat:@"<b>%@</b>", tagged];
            }
        }
        
        [html appendString:tagged];
    }];
    
    [html appendString:@"</body></html>"];
    return html;
}

@end