//
//  SettingsLogViewController.h
//

//#import "BKRViewController.h"
//#import "BookerCustomCell.h"
#import <UIKit/UIKit.h>

@interface LogEntryViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *dateTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *methodLabel;
@property (weak, nonatomic) IBOutlet UITextView *textField;
@end

typedef enum : NSUInteger {
    SettingsErrorLogMode = 0,
    SettingsPerformanceLogMode = 1,
    SettingsSyncLogMode = 2,
} SettingsLogMode;

@interface SettingsLogViewController : UITableViewController
@property (nonatomic, assign) SettingsLogMode mode;
- (IBAction)sendEmail:(id)sender;
@end
