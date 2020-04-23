//
//  GridViewCellCollectionViewCell.m
//  PhotoCommentSystem
//
//  Created by CSIE on 2015/10/8.
//  Copyright © 2015年 CSIE. All rights reserved.
//

#import "GridViewCellCollectionViewCell.h"

@interface GridViewCellCollectionViewCell ()

@property (strong) IBOutlet UIImageView *imageView;

@end

@implementation GridViewCellCollectionViewCell

- (void)setUiimageThumbnailImage:(UIImage *)uiimageThumbnailImage
{
    _uiimageThumbnailImage = uiimageThumbnailImage;
    self.imageView.image = uiimageThumbnailImage;
}

@end
