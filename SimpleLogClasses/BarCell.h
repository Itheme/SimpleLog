//
//  BarCell.h
//  SimpleLog
//
//  Created by Danila Parkhomenko on 08/06/16.
//  Copyright © 2016 Itheme. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BarCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *barImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *barWidth;
@property (weak, nonatomic) IBOutlet UILabel *label;

@end
