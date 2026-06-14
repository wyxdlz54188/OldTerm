#import "AlertHelper.h"

@implementation AlertHelper

- (void)showAlertWithTitle:(NSString *)title      // 第10行：添加 -
                   message:(NSString *)message
            viewController:(UIViewController *)vc {
    [self showAlertWithTitle:title message:message viewController:vc okHandler:nil];
}

- (void)showAlertWithTitle:(NSString *)title      // 第16行：添加 -
                   message:(NSString *)message
            viewController:(UIViewController *)vc
                okHandler:(void(^)(void))okHandler {
    // iOS 8+ 使用 UIAlertController
    if ([UIAlertController class]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction * _Nonnull action) {
            if (okHandler) okHandler();
        }];
        [alert addAction:ok];
        [vc presentViewController:alert animated:YES completion:nil];
    } else {
        // iOS 6/7 使用 UIAlertView（已废弃）
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil];
        [alert show];
        #pragma clang diagnostic pop
        if (okHandler) {
            // UIAlertView 没有回调，直接调用
            okHandler();
        }
    }
}

@end