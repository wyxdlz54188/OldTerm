#import "SettingsViewController.h"

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"设置";
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    // 右上角完成按钮
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                target:self
                                                                                action:@selector(dismissSettings)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    // 简单标签
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, self.view.frame.size.width, 200)];
    label.text = @"设置页面\n\n字体: Courier 14pt\n颜色: 绿色\nShell: /bin/bash";
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    [self.view addSubview:label];
}

- (void)dismissSettings {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end