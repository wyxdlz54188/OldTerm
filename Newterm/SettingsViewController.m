#import "SettingsViewController.h"

@implementation SettingsViewController {
    UISlider *_fontSizeSlider;
    UILabel *_fontSizeLabel;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"设置";
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                target:self
                                                                                action:@selector(dismissSettings)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, self.view.frame.size.width - 40, 30)];
    titleLabel.text = @"NewTerm 设置";
    titleLabel.font = [UIFont boldSystemFontOfSize:20.0];
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.backgroundColor = [UIColor clearColor];
    [self.view addSubview:titleLabel];
    
    CGFloat currentSize = [[NSUserDefaults standardUserDefaults] floatForKey:@"terminalFontSize"];
    if (currentSize < 8.0) currentSize = 14.0;
    
    _fontSizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 70, self.view.frame.size.width - 40, 30)];
    _fontSizeLabel.text = [NSString stringWithFormat:@"字体大小: %.0fpt", currentSize];
    _fontSizeLabel.font = [UIFont systemFontOfSize:16.0];
    _fontSizeLabel.textColor = [UIColor darkGrayColor];
    _fontSizeLabel.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_fontSizeLabel];
    
    _fontSizeSlider = [[UISlider alloc] initWithFrame:CGRectMake(20, 110, self.view.frame.size.width - 40, 30)];
    _fontSizeSlider.minimumValue = 8.0;
    _fontSizeSlider.maximumValue = 24.0;
    _fontSizeSlider.value = currentSize;
    [_fontSizeSlider addTarget:self action:@selector(fontSizeChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_fontSizeSlider];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 160, self.view.frame.size.width - 40, 150)];
    label.text = @"颜色: 绿色终端\n\nShell: /bin/bash\n\n版本: 1.0.0";
    label.numberOfLines = 0;
    label.font = [UIFont systemFontOfSize:14.0];
    label.textColor = [UIColor grayColor];
    label.backgroundColor = [UIColor clearColor];
    [self.view addSubview:label];
}

- (void)fontSizeChanged:(UISlider *)slider {
    CGFloat size = roundf(slider.value);
    _fontSizeLabel.text = [NSString stringWithFormat:@"字体大小: %.0fpt", size];
    [[NSUserDefaults standardUserDefaults] setFloat:size forKey:@"terminalFontSize"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)dismissSettings {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end