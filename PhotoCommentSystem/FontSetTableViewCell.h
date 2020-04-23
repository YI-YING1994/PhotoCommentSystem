//
//  FontSetTableViewCell.h
//  PhotoCommentSystem
//
//  Created by CSIE on 2015/9/20.
//  Copyright © 2015年 CSIE. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FontSetTableViewCell : UITableViewCell

//-------------------------------------------------------------------------------------------

@property (copy, nonatomic) NSString *nsstringName;
@property (copy, nonatomic) NSString *nsstringAttribute;

//-------------------------------------------------------------------------------------------

@property (strong, nonatomic) IBOutlet UILabel *uilabelNameLabel;
@property (strong, nonatomic) IBOutlet UILabel *uilabelAttributeLabel;

//-------------------------------------------------------------------------------------------

@end
