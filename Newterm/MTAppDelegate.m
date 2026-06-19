#import "MTAppDelegate.h"
#import "MTController.h"
#import "MTSettingsController.h"

static UIImage* createTerminalIcon() {
  UIGraphicsBeginImageContextWithOptions(CGSizeMake(30,30),NO,0);

  // 深色背景
  [[UIColor colorWithWhite:0.15 alpha:1] setFill];
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

  CGFloat cx=15,cy=15,outerR=13,innerR=9;

  // 齿轮齿
  [[UIColor colorWithWhite:0.7 alpha:1] setFill];
  for(int i=0;i<8;i++){
    CGFloat a=i*M_PI/4-M_PI/2;
    CGFloat w=3,h=5;
    CGContextRef ctx=UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx,cx+cosf(a)*innerR,cy+sinf(a)*innerR);
    CGContextRotateCTM(ctx,a);
    CGContextFillRect(ctx,CGRectMake(-w/2,-h/2,w,h));
    CGContextRestoreGState(ctx);
  }

  // 外圈
  [[UIColor colorWithWhite:0.5 alpha:1] setFill];
  CGContextFillEllipseInRect(UIGraphicsGetCurrentContext(),CGRectMake(cx-outerR,cy-outerR,outerR*2,outerR*2));
  // 内圈
  [[UIColor colorWithWhite:0.35 alpha:1] setFill];
  CGContextFillEllipseInRect(UIGraphicsGetCurrentContext(),CGRectMake(cx-innerR,cy-innerR,innerR*2,innerR*2));
  // 中心圆
  [[UIColor colorWithWhite:0.5 alpha:1] setFill];
  CGContextFillEllipseInRect(UIGraphicsGetCurrentContext(),CGRectMake(cx-4,cy-4,8,8));

  UIImage* img=UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return img;
}

@implementation MTAppDelegate

-(void)applicationDidFinishLaunching:(UIApplication*)application {
  window=[[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

  controller=[[MTController alloc] init];
  controller.title=@"Term";
  
  UIImage* termIcon=createTerminalIcon();
  UITabBarItem* termItem=[[UITabBarItem alloc] initWithTitle:@"Term" image:nil tag:0];
  if([termItem respondsToSelector:@selector(setFinishedSelectedImage:withFinishedUnselectedImage:)]){
    [termItem setFinishedSelectedImage:termIcon withFinishedUnselectedImage:termIcon];
  }
  controller.tabBarItem=termItem;
  [termItem release];

  MTSettingsController* settingsController=[[MTSettingsController alloc] init];
  settingsController.title=@"设置";
  
  UIImage* settingsIcon=createSettingsIcon();
  UITabBarItem* settingsItem=[[UITabBarItem alloc] initWithTitle:@"设置" image:nil tag:1];
  if([settingsItem respondsToSelector:@selector(setFinishedSelectedImage:withFinishedUnselectedImage:)]){
    [settingsItem setFinishedSelectedImage:settingsIcon withFinishedUnselectedImage:settingsIcon];
  }
  settingsController.tabBarItem=settingsItem;
  [settingsItem release];

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