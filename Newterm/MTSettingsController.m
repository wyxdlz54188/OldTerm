#import "MTSettingsController.h"

@implementation MTSettingsController

-(void)loadView {
  [self setTitle:@"\u8bbe\u7f6e"];

  UIView* view = [[UIView alloc] initWithFrame:CGRectZero];
  view.backgroundColor = [UIColor groupTableViewBackgroundColor];
  view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.view = view;
  [view release];

  UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(20, 100, 280, 40)];
  label.text = @"\u8bbe\u7f6e\u9875\u9762";
  label.textAlignment = NSTextAlignmentCenter;
  label.font = [UIFont systemFontOfSize:18];
  label.textColor = [UIColor grayColor];
  label.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
  [self.view addSubview:label];
  [label release];
}

@end
