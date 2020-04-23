//
//  GridViewCollectionViewController.h
//  PhotoCommentSystem
//
//  Created by CSIE on 2015/10/8.
//  Copyright © 2015年 CSIE. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"

@import Photos;

//----------------------------------------------------------------------------------------

@protocol ThemeChange <NSObject>

@optional

- (void)setRootViewBackgroundWithTheme:(NSUInteger)Theme;

@end

//----------------------------------------------------------------------------------------

@interface GridViewCollectionViewController : UICollectionViewController
    <AssetChangeDelegate>
    
//----------------------------------------------------------------------------------------

@property (strong) PHFetchResult *phfetchresultFetchAssets;
@property (strong) NSArray *nsarrayFetchAssets;
@property (strong) NSString *nsstringAlbumPath;
@property (strong) NSString *nsstringAlbumName;

//----------------------------------------------------------------------------------------

//Theme
@property NSUInteger nsuintegerTheme;
@property (weak) id <ThemeChange> delegate;

//----------------------------------------------------------------------------------------

@end
