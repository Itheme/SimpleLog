//
//  HistogramViewController.h
//

#import <UIKit/UIKit.h>

@interface HistogramViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *midTime;
@property (weak, nonatomic) IBOutlet UILabel *maxTime;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segment;
@property (weak, nonatomic) IBOutlet UISwitch *groupSwitch;

@end


