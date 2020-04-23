//
//  GuideView.h
//  PhotoCommentSystem
//
//  Created by MCUCSIE on 3/14/17.
//  Copyright © 2017 CSIE. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GuideView : UIView
@property (strong, nonatomic) UILabel *uilblTitle;
@property (strong, nonatomic) UITextView *uitxtvDescription;
@property (strong, nonatomic) UIImageView *uiimvPicture;

- (instancetype)initWithTitle:(NSString *)title description:(NSString *)description image:(UIImage *)image;
@end
