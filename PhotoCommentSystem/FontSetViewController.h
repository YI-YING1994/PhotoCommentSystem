//
//  FontSetViewController.h
//  PhotoCommentSystem
//
//  Created by CSIE on 2015/9/20.
//  Copyright © 2015年 CSIE. All rights reserved.
//

#import <UIKit/UIKit.h>

//-------------------------------------------------------------------------------------------

//create protocol and delegate

@protocol FontSetDelegate <NSObject>

@optional

- (void)fontSettingPassToViewController:(NSString *)fontSizeValue ColorSet:(NSString *)fontColorValue TypeSet:(NSString *)fontTypeValue FontSizeLast:(NSIndexPath *)fontSizeIndexPath FontColorLast:(NSIndexPath *)fontColorIndexPath FontTypeLast:(NSIndexPath *)fontTypeIndexPath;

- (void)setViewBackgroundWithTheme:(NSUInteger)Theme;

@end

//-------------------------------------------------------------------------------------------

@interface FontSetViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

//-------------------------------------------------------------------------------------------

//Theme
@property NSUInteger nsuintegerTheme;
@property (weak, nonatomic) IBOutlet UIImageView *uiimageBackground;

//Table View
@property (strong, nonatomic) IBOutlet UITableView *uitableviewFontSetTableView;
@property (strong, nonatomic) IBOutlet UITableView *uitableviewFontDetailTableView;
@property (weak, nonatomic) IBOutlet UILabel *uilabelUseless;

//-------------------------------------------------------------------------------------------

//data array
@property (strong, nonatomic) NSMutableArray *nsmutablearrayFontSettings;
@property (strong, nonatomic) NSArray *nsarrayFontSizes;
@property (strong, nonatomic) NSArray *nsarrayFontColors;
@property (strong, nonatomic) NSArray *nsarrayFontTypes;

//-------------------------------------------------------------------------------------------

//font value set
@property (strong, nonatomic) NSString *nsstringFontSizeValue;
@property (strong, nonatomic) NSString *nsstringFontColorValue;
@property (strong, nonatomic) NSString *nsstringFontTypeValue;
@property NSUInteger nsuintegerFontSizeValue_UInt;
@property (weak, nonatomic) IBOutlet UITextView *uitextviewFontDemoView;

//-------------------------------------------------------------------------------------------

//Detail View Select & Last indexPath
@property NSUInteger nsuintegerDetailViewSelect;
@property (strong, nonatomic) NSIndexPath *nsindexpathFontSizeLastIndexPath;
@property (strong, nonatomic) NSIndexPath *nsindexpathFontColorLastIndexPath;
@property (strong, nonatomic) NSIndexPath *nsindexpathFontTypeLastIndexPath;

//-------------------------------------------------------------------------------------------

//delegate property
@property (weak, nonatomic) id <FontSetDelegate> delegate;

//-------------------------------------------------------------------------------------------

//background Touch
- (IBAction)backgroundTouch:(id)sender;

//-------------------------------------------------------------------------------------------

@end


