#import "MTSettingsController.h"

@interface MTSettingsController () <UITableViewDataSource,UITableViewDelegate> {
  UITableView* tableView;
  UISlider* fontSizeSlider;
  UILabel* fontSizeLabel;
  CGFloat currentFontSize;
}
@end

@implementation MTSettingsController

-(void)loadView {
  [self setTitle:@"\u8bbe\u7f6e"];

  // 从 UserDefaults 读取当前字体大小
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
  return 1;
}

-(NSInteger)tableView:(UITableView*)tv numberOfRowsInSection:(NSInteger)section {
  return 1;
}

-(NSString*)tableView:(UITableView*)tv titleForHeaderInSection:(NSInteger)section {
  return @"\u7ec8\u7aef\u5b57\u4f53";
}

-(NSString*)tableView:(UITableView*)tv titleForFooterInSection:(NSInteger)section {
  return @"\u8c03\u6574\u7ec8\u7aef\u6587\u672c\u663e\u793a\u5927\u5c0f\uff0c\u5207\u6362\u56de Term \u6807\u7b7e\u540e\u751f\u6548";
}

-(UITableViewCell*)tableView:(UITableView*)tv cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  static NSString* ident=@"fontCell";
  UITableViewCell* cell=[tv dequeueReusableCellWithIdentifier:ident];
  if(!cell){
    cell=[[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
      reuseIdentifier:ident] autorelease];
    cell.selectionStyle=UITableViewCellSelectionStyleNone;

    // 创建 fontSizeLabel 并 retain
    fontSizeLabel=[[UILabel alloc] initWithFrame:CGRectMake(0,0,60,30)];
    fontSizeLabel.font=[UIFont boldSystemFontOfSize:16];
    fontSizeLabel.textColor=[UIColor colorWithRed:0.2 green:0.4 blue:0.8 alpha:1];
    fontSizeLabel.textAlignment=NSTextAlignmentCenter;
    fontSizeLabel.text=[NSString stringWithFormat:@"%.0f pt",fontSizeSlider.value];
    cell.accessoryView=fontSizeLabel;
    [fontSizeLabel release];

    // 设置 slider 的 frame 并添加到 cell
    CGRect frame=fontSizeSlider.frame;
    frame.origin.x=15;
    frame.origin.y=(44-frame.size.height)/2;
    frame.size.width=tv.bounds.size.width-30-70;
    fontSizeSlider.frame=frame;
    fontSizeSlider.autoresizingMask=UIViewAutoresizingFlexibleWidth;
    [cell.contentView addSubview:fontSizeSlider];
  }
  return cell;
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