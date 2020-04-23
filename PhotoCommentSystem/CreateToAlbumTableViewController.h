//
//  CreateToAlbumTableViewController.h
//  PhotoCommentSystem
//
//  Created by CSIE on 2015/10/18.
//  Copyright © 2015年 CSIE. All rights reserved.
//

#import <UIKit/UIKit.h>

@import Photos;
//------------------------------------------------------------------------------------------------------------------------------

@protocol AlbumChangeDelegate <NSObject>

@optional

- (void)haveChangedViewAlbum:(NSString *)AlbumPath AlbumName:(NSString *)AlbumName Asset:(NSString *)Asset;
- (void)sendNewPhAsset:(NSString *)Asset AlbumName:(NSString *)AlbumName;

@end

//------------------------------------------------------------------------------------------------------------------------------

@interface CreateToAlbumTableViewController : UITableViewController

@property NSUInteger nsuintegerTheme;
@property (strong) NSString *nsstringAlbumName;
@property (strong) NSData *nsdataGlobalData;
@property (weak) id <AlbumChangeDelegate> delegate;

@end
