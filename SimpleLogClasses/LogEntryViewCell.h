//
//  LogEntryViewCell.h
//  SimpleLog
//
//  Created by Danila Parkhomenko on 08/06/16.
//  Copyright © 2016 Itheme. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LogEntryViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *dateTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *methodLabel;
@property (weak, nonatomic) IBOutlet UITextView *textField;

@end
