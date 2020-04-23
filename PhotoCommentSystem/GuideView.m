//
//  GuideView.m
//  PhotoCommentSystem
//
//  Created by MCUCSIE on 3/14/17.
//  Copyright © 2017 CSIE. All rights reserved.
//

#import "GuideView.h"

@implementation GuideView

- (instancetype)initWithTitle:(NSString *)title description:(NSString *)description image:(UIImage *)image
{
    self = [super init];

    self.uilblTitle.text = title;
    self.uitxtvDescription.text = description;
    self.uiimvPicture.image = image;
    
    return self;

}
- (UILabel *)uilblTitle
{
    if (!_uilblTitle) {
        _uilblTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 21)];
        [_uilblTitle setTextAlignment:NSTextAlignmentCenter];
        [_uilblTitle setBackgroundColor:[UIColor colorWithRed:0.66666668653488159
                                                        green:0.66666668653488159
                                                         blue:0.66666668653488159
                                                        alpha:0.31]];
        [_uilblTitle setFont:[UIFont fontWithName:@"system" size:17]];
        [_uilblTitle setTextColor:[UIColor colorWithRed:0.0
                                                  green:0.0
                                                   blue:0.0
                                                  alpha:1]];
        [self addSubview:_uilblTitle];
    }
    
    
    return _uilblTitle;
}

- (UITextView *)uitxtvDescription
{
    if (!_uitxtvDescription) {
        _uitxtvDescription = [[UITextView alloc] initWithFrame:CGRectMake(8, 20, 304, 24)];
        [_uitxtvDescription setScrollEnabled:NO];
        [_uitxtvDescription setEditable:NO];
        [_uitxtvDescription setContentMode:UIViewContentModeScaleToFill];
        [_uitxtvDescription setTextAlignment:NSTextAlignmentCenter];
        [_uitxtvDescription setFont:[UIFont fontWithName:@"system" size:14]];
        
        [self addSubview:_uitxtvDescription];
    }
    
    return _uitxtvDescription;
}

- (UIImageView *)uiimvPicture
{
    if (!_uiimvPicture) {
        _uiimvPicture = [[UIImageView alloc] initWithFrame:CGRectMake(21, 50, 278, 422)];
        [_uiimvPicture setUserInteractionEnabled:NO];
        [_uiimvPicture setContentMode:UIViewContentModeScaleAspectFit];
        
        [self addSubview:_uiimvPicture];
    }
    
    return _uiimvPicture;
}

@end
