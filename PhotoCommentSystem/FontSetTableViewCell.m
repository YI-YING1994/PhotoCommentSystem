//
//  FontSetTableViewCell.m
//  PhotoCommentSystem
//
//  Created by CSIE on 2015/9/20.
//  Copyright © 2015年 CSIE. All rights reserved.
//

#import "FontSetTableViewCell.h"


@implementation FontSetTableViewCell

//-------------------------------------------------------------------------------------------

@synthesize nsstringName;
@synthesize nsstringAttribute;
@synthesize uilabelNameLabel;
@synthesize uilabelAttributeLabel;

//-------------------------------------------------------------------------------------------

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

//-------------------------------------------------------------------------------------------

- (void)setNsstringName:(NSString *)n
{
    if (![n isEqualToString:nsstringName])
        {
        nsstringName = [n copy];
        }
    
    uilabelNameLabel.text = nsstringName;
    uilabelNameLabel.font = [UIFont fontWithName:@"DFWaWaTC-W5" size:22.0];
}

//-------------------------------------------------------------------------------------------

- (void)setNsstringAttribute:(NSString *)a
{
    if (![a isEqualToString:nsstringAttribute])
        {
        nsstringAttribute = [a copy];
        }
    uilabelAttributeLabel.text = nsstringAttribute;
    uilabelAttributeLabel.font = [UIFont fontWithName:@"DFWaWaTC-W5" size:22.0];
}

//-------------------------------------------------------------------------------------------

@end
