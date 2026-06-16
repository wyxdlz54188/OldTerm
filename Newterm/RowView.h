#import <UIKit/UIKit.h>

@interface RowView : UIView

@property (nonatomic, retain) UIColor *defaultColor;
@property (nonatomic, assign) CGFloat charWidth;

- (void)renderLine:(NSString *)line;

@end
