//
//  ExplantionViewController.m
//  PhotoCommentSystem
//
//  Created by CSIE on 2015/10/21.
//  Copyright © 2015年 CSIE. All rights reserved.
//

#import "ExplantionViewController.h"
#import "GuideView.h"

#define GuideView_Height 470
#define GuideView_Width 320

@implementation ExplantionViewController

//------------------------------------------------------------------------------------------------

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    GuideView *gvAddTo = [[GuideView alloc] initWithTitle:@"新增到"
                                              description:@"新增相片到不同的資料夾"
                                                    image:[UIImage imageNamed:@"Create"]];
    
    gvAddTo.frame = CGRectMake(0, 0, GuideView_Width, GuideView_Height);

    GuideView *gvSet = [[GuideView alloc] initWithTitle:@"設定"
                                            description:@"在這裡面可以設定字體大小、顏色、字型"
                                                  image:[UIImage imageNamed:@"Set"]];
    gvSet.frame = CGRectMake(0, GuideView_Height + 10, GuideView_Width, GuideView_Height);

    GuideView *gvComment = [[GuideView alloc] initWithTitle:@"註解"
                                            description:@"在這裡能進行回憶的保存，與珍藏"
                                                  image:[UIImage imageNamed:@"Comment"]];
    gvComment.frame = CGRectMake(0, (GuideView_Height + 10) * 2, GuideView_Width, GuideView_Height);

    GuideView *gvDelete = [[GuideView alloc] initWithTitle:@"刪除"
                                            description:@"刪除照片"
                                                  image:[UIImage imageNamed:@"Delete"]];
    gvDelete.frame = CGRectMake(0, (GuideView_Height + 10) * 3, GuideView_Width, GuideView_Height);

    
    [self.uiscrollviewScrollView setContentSize:CGSizeMake(320, 1920)];

    [self.uiscrollviewScrollView addSubview:gvAddTo];
    [self.uiscrollviewScrollView addSubview:gvSet];
    [self.uiscrollviewScrollView addSubview:gvComment];
    [self.uiscrollviewScrollView addSubview:gvDelete];
    
}

//------------------------------------------------------------------------------------------------

@end
