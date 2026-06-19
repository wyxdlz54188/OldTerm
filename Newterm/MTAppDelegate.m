#import "MTAppDelegate.h"
#import "MTController.h"
#import "MTSettingsController.h"

static UIImage* createTerminalIcon() {
  UIGraphicsBeginImageContextWithOptions(CGSizeMake(30,30),NO,0);
  CGContextRef ctx=UIGraphicsGetCurrentContext();

  // 深色背景圆角矩形
  CGContextSetFillColorWithColor(ctx,[UIColor colorWithWhite:0.15 alpha:1].CGColor);
  [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(1,1,28,28) cornerRadius:6] fill];

  // 绿色 >_ 文字
  [[UIColor colorWithRed:0.3 green:0.85 blue:0.3 alpha:1] setFill];
  [@">_" drawAtPoint:CGPointMake(5,5) withFont:[UIFont fontWithName:@"Courier-Bold" size:18]];

  UIImage* img=UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return img;
}

static UIImage* createSettingsIcon() {
  UIGraphicsBeginImageContextWithOptions(CGSizeMake(30,30),NO,0);
  CGContextRef ctx=UIGraphicsGetCurrentContext();

  CGFloat cx=15,cy=15,outerR=13,innerR=9;
  
  // 齿轮齿
  CGContextSetFillColorWithColor(ctx,[UIColor colorWithWhite:0.35 alpha:1].CGColor);
  for(int i=0;i<8;i++){
    CGFloat a=i*M_PI/4-M_PI/2;
    CGFloat w=3,h=5;
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,cx+cosf(a)*innerR,cy+sinf(a)*innerR);
    CGContextRotateCTM(ctx,a);
    CGContextFillRect(ctx,CGRectMake(-w/2,-h/2,w,h));
    CGContextRestoreGState(ctx);
  }

  // 外圈
  CGContextSetFillColorWithColor(ctx,[UIColor colorWithWhite:0.55 alpha:1].CGColor);
  CGContextFillEllipseInRect(ctx,CGRectMake(cx-outerR,cy-outerR,outerR*2,outerR*2));
  // 内圈
  CGContextSetFillColorWithColor(ctx,[UIColor colorWithWhite:0.35 alpha:1].CGColor);
  CGContextFillEllipseInRect(ctx,CGRectMake(cx-innerR,cy-innerR,innerR*2,innerR*2));
  // 中心圆
  CGContextSetFillColorWithColor(ctx,[UIColor colorWithWhite:0.55 alpha:1].CGColor);
  CGContextFillEllipseInRect(ctx,CGRectMake(cx-4,cy-4,8,8));

  UIImage* img=UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return img;
}

@implementation MTAppDelegate

-(void)applicationDidFinishLaunching:(UIApplication*)application {
  window=[[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

  controller=[[MTController alloc] init];
  controller.title=@"Term";
  
  // 创建终端图标并设置
  UIImage* termIcon=createTerminalIcon();
  controller.tabBarItem=[[[UITabBarItem alloc] initWithTitle:@"Term"
    image:termIcon tag:0] autorelease];

  MTSettingsController* settingsController=[[MTSettingsController alloc] init];
  settingsController.title=@"设置";
  
  // 创建设置图标并设置
  UIImage* settingsIcon=createSettingsIcon();
  settingsController.tabBarItem=[[[UITabBarItem alloc] initWithTitle:@"设置"
    image:settingsIcon tag:1] autorelease];

  tabBarController=[[UITabBarController alloc] init];
  tabBarController.viewControllers=[NSArray arrayWithObjects:controller,settingsController,nil];
  [settingsController release];

  window.rootViewController=tabBarController;
  [tabBarController release];
  [window makeKeyAndVisible];
}

-(BOOL)application:(UIApplication*)application handleOpenURL:(NSURL*)URL {
  return [controller handleOpenURL:URL];
}

-(void)applicationDidEnterBackground:(UIApplication*)application {
  if(!controller.isRunning){exit(0);}
}

-(UIWindow*)window {
  return window;
}

-(void)dealloc {
  [window release];
  [controller release];
  [super dealloc];
}

@end