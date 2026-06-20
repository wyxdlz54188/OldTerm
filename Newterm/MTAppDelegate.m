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

  // ✅ 修改：设置页嵌入 NavigationController
  MTSettingsController* settingsController=[[MTSettingsController alloc] init];
  settingsController.title=@"设置";
  
  UINavigationController* settingsNav=[[UINavigationController alloc] initWithRootViewController:settingsController];
  settingsNav.navigationBar.barStyle=UIBarStyleDefault;
  [settingsController release];
  
  UIImage* settingsIcon=[UIImage imageNamed:@"tab_settings"];
  UITabBarItem* settingsItem=[[UITabBarItem alloc] initWithTitle:@"设置" image:settingsIcon tag:1];
  settingsNav.tabBarItem=settingsItem;
  [settingsItem release];

  tabBarController=[[UITabBarController alloc] init];
  tabBarController.viewControllers=[NSArray arrayWithObjects:controller,settingsNav,nil];
  [settingsNav release];

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