#import <UIKit/UIKit.h>

@interface AlertHelper : NSObject

/**
 * Show a simple alert with an OK button.
 * The title and message should be localized via NSLocalizedString before calling.
 */
- (void)showAlertWithTitle:(NSString *)title      // 这里加 -
                 message:(NSString *)message
          viewController:(UIViewController *)vc;

/**
 * Show an alert with an OK button and a custom handler.
 */
- (void)showAlertWithTitle:(NSString *)title      // 这里加 -
                 message:(NSString *)message
          viewController:(UIViewController *)vc
              okHandler:(void(^)(void))okHandler;

@end