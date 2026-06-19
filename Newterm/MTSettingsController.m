#import "MTSettingsController.h"
#import "MTAboutController.h"

@interface MTSettingsController () <UITableViewDataSource,UITableViewDelegate> {
  UITableView* tableView;
  UISlider* fontSizeSlider;
  UILabel* fontSizeLabel;
  CGFloat currentFontSize;
}
@end

@implementation MTSettingsController

-(void)loadView {
  [self setTitle:@"设置"];

  NSUserDefaults* defaults=[NSUserDefaults standardUserDefaults];
  NSString* name=[NSBundle mainBundle].bundleIdentifier;
  NSDictionary* settings=[defaults persistentDomainForName:name];
  NSNumber* savedSize=[settings objectForKey:@"fontSize"];
  if([savedSize respondsToSelector:@selector(doubleValue)]){
    currentFontSize=[savedSize doubleValue];
  }
  if(currentFontSize<=0) currentFontSize=10;

  UIView* view=[[UIView alloc] initWithFrame:CGRectZero];
  view.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
  self.view=view;
  [view release];

  tableView=[[UITableView alloc] initWithFrame:view.bounds
    style:UITableViewStyleGrouped];
  tableView.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
  tableView.dataSource=self;
  tableView.delegate=self;
  tableView.backgroundView=nil;
  tableView.backgroundColor=[UIColor colorWithWhite:0.93 alpha:1];
  [view addSubview:tableView];
  [tableView release];

  // 创建 fontSizeSlider 并 retain
  fontSizeSlider=[[UISlider alloc] initWithFrame:CGRectMake(0,0,200,30)];
  fontSizeSlider.minimumValue=6;
  fontSizeSlider.maximumValue=24;
  fontSizeSlider.value=currentFontSize;
  [fontSizeSlider addTarget:self action:@selector(fontSizeChanged:)
    forControlEvents:UIControlEventValueChanged];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView*)tv {
  return 2;
}

-(NSInteger)tableView:(UITableView*)tv numberOfRowsInSection:(NSInteger)section {
  if (section == 0) {
    return 1;
  } else {
    return 1;
  }
}

-(NSString*)tableView:(UITableView*)tv titleForHeaderInSection:(NSInteger)section {
  if (section == 0) {
    return @"终端字体";
  } else {
    return @"应用信息";
  }
}

-(NSString*)tableView:(UITableView*)tv titleForFooterInSection:(NSInteger)section {
  if (section == 0) {
    return @"调整终端文本显示大小，切换回 Term 标签后生效";
  }
  return nil;
}

-(UITableViewCell*)tableView:(UITableView*)tv cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  if (indexPath.section == 0) {
    static NSString* ident=@"fontCell";
    UITableViewCell* cell=[tv dequeueReusableCellWithIdentifier:ident];
    if(!cell){
      cell=[[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
        reuseIdentifier:ident] autorelease];
      cell.selectionStyle=UITableViewCellSelectionStyleNone;

      fontSizeLabel=[[UILabel alloc] initWithFrame:CGRectMake(0,0,60,30)];
      fontSizeLabel.font=[UIFont boldSystemFontOfSize:16];
      fontSizeLabel.textColor=[UIColor colorWithRed:0.2 green:0.4 blue:0.8 alpha:1];
      fontSizeLabel.textAlignment=NSTextAlignmentCenter;
      fontSizeLabel.text=[NSString stringWithFormat:@"%.0f pt",fontSizeSlider.value];
      cell.accessoryView=fontSizeLabel;
      [fontSizeLabel release];

      CGRect frame=fontSizeSlider.frame;
      frame.origin.x=15;
      frame.origin.y=(44-frame.size.height)/2;
      frame.size.width=tv.bounds.size.width-30-70;
      fontSizeSlider.frame=frame;
      fontSizeSlider.autoresizingMask=UIViewAutoresizingFlexibleWidth;
      [cell.contentView addSubview:fontSizeSlider];
    }
    return cell;
  } else {
    static NSString* aboutIdent=@"aboutCell";
    UITableViewCell* cell=[tv dequeueReusableCellWithIdentifier:aboutIdent];
    if(!cell){
      cell=[[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
        reuseIdentifier:aboutIdent] autorelease];
      cell.textLabel.text=@"关于 NewTerm";
      cell.textLabel.textAlignment=NSTextAlignmentCenter;
      cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
  }
}

-(void)tableView:(UITableView*)tv didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  [tv deselectRowAtIndexPath:indexPath animated:YES];
  
  if (indexPath.section == 1 && indexPath.row == 0) {
    MTAboutController* aboutController=[[MTAboutController alloc] init];
    [self.navigationController pushViewController:aboutController animated:YES];
    [aboutController release];
  }
}

-(void)fontSizeChanged:(UISlider*)slider {
  CGFloat fontSize=round(slider.value);
  if(fontSizeLabel){
    fontSizeLabel.text=[NSString stringWithFormat:@"%.0f pt",fontSize];
  }

  NSUserDefaults* defaults=[NSUserDefaults standardUserDefaults];
  NSString* name=[NSBundle mainBundle].bundleIdentifier;
  NSMutableDictionary* settings=[[defaults persistentDomainForName:name] mutableCopy];
  if(!settings) settings=[[NSMutableDictionary alloc] init];
  [settings setObject:[NSNumber numberWithDouble:fontSize] forKey:@"fontSize"];
  [defaults setPersistentDomain:settings forName:name];
  [settings release];
}

-(void)dealloc {
  [fontSizeSlider release];
  [super dealloc];
}

@end