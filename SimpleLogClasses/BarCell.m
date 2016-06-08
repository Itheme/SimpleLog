//
//  BarCell.m
//  SimpleLog
//
//  Created by Danila Parkhomenko on 08/06/16.
//  Copyright © 2016 Itheme. All rights reserved.
//

#import "BarCell.h"

@implementation BarCell

- (void)awakeFromNib {
    [super awakeFromNib];
    if (UIEdgeInsetsEqualToEdgeInsets(self.barImageView.image.capInsets, UIEdgeInsetsZero)) {
        self.barImageView.image = [self.barImageView.image resizableImageWithCapInsets:UIEdgeInsetsMake(0, 4, 0, 4)];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
