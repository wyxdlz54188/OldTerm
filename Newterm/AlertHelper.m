#import "AlertHelper.h"

@implementation AlertHelper

#pragma clang diagnostic ignored "-Wstrict-selector-match"

- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
            viewController:(UIViewController *)vc {
    [self showAlertWithTitle:title message:message viewController:vc okHandler:nil];
}

- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
            viewController:(UIViewController *)vc
                 okHandler:(void(^)(void))okHandler {
    
    // 运行时动态调用 UIAlertController (iOS 8+)
    Class alertClass = NSClassFromString(@"UIAlertController");
    if (alertClass) {
        // 1. 创建 UIAlertController
        id alert = [alertClass alertControllerWithTitle:title
                                               message:message
                                        preferredStyle:0]; // 0 = UIAlertControllerStyleAlert
        
        // 2. 创建 UIAlertAction
        Class actionClass = NSClassFromString(@"UIAlertAction");
        id okAction = [actionClass actionWithTitle:NSLocalizedString(@"OK", nil)
                                             style:0 // 0 = UIAlertActionStyleDefault
                                           handler:^(id action) {
            if (okHandler) okHandler();
        }];
        
        // 3. 添加动作并展示
        [alert addAction:okAction];
        [vc presentViewController:alert animated:YES completion:nil];
        
    } else {
        // iOS 6/7 降级使用 UIAlertView
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
            okHandler();
        }
    }
}

@end