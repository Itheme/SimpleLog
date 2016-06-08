//
//  SettingsLogViewController.h
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    SettingsErrorLogMode = 0,
    SettingsPerformanceLogMode = 1,
    SettingsGenericLogMode = 2,
} SettingsLogMode;

@interface SimpleLogViewController : UITableViewController
@property (nonatomic, assign) SettingsLogMode mode;
- (IBAction)sendEmail:(id)sender;
@end
