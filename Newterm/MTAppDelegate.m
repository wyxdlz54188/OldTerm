#import "MTAppDelegate.h"
#import "MTController.h"
#import "MTSettingsController.h"

@implementation MTAppDelegate
-(void)applicationDidFinishLaunching:(UIApplication*)application {
  window=[[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

  controller=[[MTController alloc] init];
  controller.title=@"Term";

  MTSettingsController* settingsController=[[MTSettingsController alloc] init];

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
