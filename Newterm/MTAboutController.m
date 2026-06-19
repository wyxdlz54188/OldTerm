#import "MTAboutController.h"

@implementation MTAboutController

- (void)loadView {
    [self setTitle:@"关于"];
    
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.view = view;
    [view release];
    
    // 创建滚动视图
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:view.bounds];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scrollView.alwaysBounceVertical = YES;
    [view addSubview:scrollView];
    
    CGFloat width = view.bounds.size.width;
    CGFloat padding = 20.0f;
    CGFloat yOffset = 30.0f;
    
    // 应用图标
    UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake((width - 80) / 2, yOffset, 80, 80)];
    iconView.image = [UIImage imageNamed:@"Icon"];
    iconView.layer.cornerRadius = 16.0f;
    iconView.clipsToBounds = YES;
    [scrollView addSubview:iconView];
    [iconView release];
    
    yOffset += 100.0f;
    
    // 应用名称
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding, yOffset, width - 2 * padding, 30)];
    nameLabel.text = @"NewTerm";
    nameLabel.font = [UIFont boldSystemFontOfSize:24.0f];
    nameLabel.textAlignment = NSTextAlignmentCenter;
    nameLabel.backgroundColor = [UIColor clearColor];
    [scrollView addSubview:nameLabel];
    [nameLabel release];
    
    yOffset += 35.0f;
    
    // 版本号
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    UILabel *versionLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding, yOffset, width - 2 * padding, 20)];
    versionLabel.text = [NSString stringWithFormat:@"版本 %@", version];
    versionLabel.font = [UIFont systemFontOfSize:16.0f];
    versionLabel.textColor = [UIColor grayColor];
    versionLabel.textAlignment = NSTextAlignmentCenter;
    versionLabel.backgroundColor = [UIColor clearColor];
    [scrollView addSubview:versionLabel];
    [versionLabel release];
    
    yOffset += 40.0f;
    
    // 分割线
    UIView *separator1 = [[UIView alloc] initWithFrame:CGRectMake(padding, yOffset, width - 2 * padding, 1)];
    separator1.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
    [scrollView addSubview:separator1];
    [separator1 release];
    
    yOffset += 20.0f;
    
    // 描述信息
    UILabel *descLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding, yOffset, width - 2 * padding, 80)];
    descLabel.text = @"NewTerm 是一个为 iOS 6 设计的终端模拟器，基于 MobileTerminal 开发，支持 VT100 终端模拟和完整的终端功能。";
    descLabel.font = [UIFont systemFontOfSize:14.0f];
    descLabel.textColor = [UIColor darkGrayColor];
    descLabel.numberOfLines = 0;
    descLabel.textAlignment = NSTextAlignmentCenter;
    descLabel.backgroundColor = [UIColor clearColor];
    [scrollView addSubview:descLabel];
    [descLabel release];
    
    yOffset += 100.0f;
    
    // 分割线
    UIView *separator2 = [[UIView alloc] initWithFrame:CGRectMake(padding, yOffset, width - 2 * padding, 1)];
    separator2.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
    [scrollView addSubview:separator2];
    [separator2 release];
    
    yOffset += 20.0f;
    
    // 技术信息标题
    UILabel *techTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding, yOffset, width - 2 * padding, 25)];
    techTitleLabel.text = @"技术信息";
    techTitleLabel.font = [UIFont boldSystemFontOfSize:18.0f];
    techTitleLabel.textAlignment = NSTextAlignmentCenter;
    techTitleLabel.backgroundColor = [UIColor clearColor];
    [scrollView addSubview:techTitleLabel];
    [techTitleLabel release];
    
    yOffset += 30.0f;
    
    // 技术信息项
    NSArray *techItems = @[
        @[@"终端引擎", @"VT100"],
        @[@"渲染引擎", @"CoreText"],
        @[@"最低系统", @"iOS 4.0"],
        @[@"目标系统", @"iOS 6.0"],
        @[@"架构", @"ARMv7 / ARMv7s"]
    ];
    
    for (NSArray *item in techItems) {
        UILabel *keyLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding + 20, yOffset, 100, 20)];
        keyLabel.text = item[0];
        keyLabel.font = [UIFont systemFontOfSize:14.0f];
        keyLabel.textColor = [UIColor grayColor];
        keyLabel.backgroundColor = [UIColor clearColor];
        [scrollView addSubview:keyLabel];
        [keyLabel release];
        
        UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding + 130, yOffset, width - 2 * padding - 130, 20)];
        valueLabel.text = item[1];
        valueLabel.font = [UIFont systemFontOfSize:14.0f];
        valueLabel.textColor = [UIColor darkTextColor];
        valueLabel.backgroundColor = [UIColor clearColor];
        [scrollView addSubview:valueLabel];
        [valueLabel release];
        
        yOffset += 25.0f;
    }
    
    yOffset += 10.0f;
    
    // 分割线
    UIView *separator3 = [[UIView alloc] initWithFrame:CGRectMake(padding, yOffset, width - 2 * padding, 1)];
    separator3.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f];
    [scrollView addSubview:separator3];
    [separator3 release];
    
    yOffset += 20.0f;
    
    // 感谢信息
    UILabel *thanksLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding, yOffset, width - 2 * padding, 40)];
    thanksLabel.text = @"感谢 MobileTerminal 项目\n及其所有贡献者";
    thanksLabel.font = [UIFont systemFontOfSize:14.0f];
    thanksLabel.textColor = [UIColor darkGrayColor];
    thanksLabel.numberOfLines = 0;
    thanksLabel.textAlignment = NSTextAlignmentCenter;
    thanksLabel.backgroundColor = [UIColor clearColor];
    [scrollView addSubview:thanksLabel];
    [thanksLabel release];
    
    yOffset += 60.0f;
    
    // 版权信息
    UILabel *copyrightLabel = [[UILabel alloc] initWithFrame:CGRectMake(padding, yOffset, width - 2 * padding, 20)];
    copyrightLabel.text = @"© 2024 NewTerm Project";
    copyrightLabel.font = [UIFont systemFontOfSize:12.0f];
    copyrightLabel.textColor = [UIColor lightGrayColor];
    copyrightLabel.textAlignment = NSTextAlignmentCenter;
    copyrightLabel.backgroundColor = [UIColor clearColor];
    [scrollView addSubview:copyrightLabel];
    [copyrightLabel release];
    
    yOffset += 30.0f;
    
    // 设置滚动视图内容大小
    scrollView.contentSize = CGSizeMake(width, yOffset + 20);
    [scrollView release];
    
    // 添加导航栏返回按钮（由系统自动提供）
    self.navigationItem.hidesBackButton = NO;
}

@end