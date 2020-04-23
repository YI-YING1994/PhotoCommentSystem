//
//  ViewController.h
//  PhotoCommentSystem
//
//  Created by CSIE on 2015/9/20.
//  Copyright © 2015年 CSIE. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import <ImageIO/ImageIO.h>
#import "FontSetViewController.h"
#import "CreateToAlbumTableViewController.h"

//----------------------------------------------------------------------------------------

@protocol AssetChangeDelegate <NSObject>

@optional

- (void)haveChangeGridViewAsset:(NSArray *)FetchAssets AlbumName:(NSString *)AlbumName
    AlbumPath:(NSString *)AlbumPath;
- (void)haveChangeGridViewPhAsset:(PHFetchResult *)FetchAssets AlbumName:(NSString *)AlbumName;
- (void)setGridViewBackgroundWithTheme:(NSUInteger)Theme;

@end

//----------------------------------------------------------------------------------------

@interface ViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, FontSetDelegate, UITextFieldDelegate,UITextViewDelegate, UIGestureRecognizerDelegate, AlbumChangeDelegate>

//----------------------------------------------------------------------------------------

// Theme
@property NSUInteger nsuintegerTheme;

//Display image
@property (weak, nonatomic) IBOutlet UIImageView *uiimageviewImageView;
@property (assign) CGSize cgsizeLastImageViewSize;
@property (strong, nonatomic) NSData *nsdataGlobalData;

//----------------------------------------------------------------------------------------

//Asset and Album
@property (strong) PHAsset *phassetAsset;
@property (strong) NSString *nsstringAsset;
@property (strong) NSString *nsstringAlbumPath;
@property NSUInteger nsuintegerAssetNum;
@property (strong) NSString *nsstringAlbumName;

//----------------------------------------------------------------------------------------

//Delegate property
@property (weak) id <AssetChangeDelegate> delegate;

//----------------------------------------------------------------------------------------

//image picker declares
//@property (assign, nonatomic) CGRect cgrectImageFrame;
//@property (strong, nonatomic) UIImage *uiimageImage;
//@property (strong, nonatomic) NSURL *nsurlImageURL;
//@property (weak, nonatomic) IBOutlet UIButton *uibuttonPickPictureButton;
//@property (strong, nonatomic) NSURL *nsurlMovieURL;
//@property (copy, nonatomic) NSString *nsstringLastChosenMediaType;

//----------------------------------------------------------------------------------------

//font set pass
@property (strong, nonatomic) NSString *nsstringFontSizeValue;
@property (strong, nonatomic) NSString *nsstringFontColorValue;
@property (strong, nonatomic) NSString *nsstringFontTypeValue;
@property NSUInteger nsuintegerFontSizeValue_ViewControll;
@property NSUInteger nsuintegerFontColorValue;
@property NSUInteger nsuintegerFontTypeValue;
@property (strong, nonatomic) NSIndexPath *nsindexpathFontSizeLastIndexPath;
@property (strong, nonatomic) NSIndexPath *nsindexpathFontColorLastIndexPath;
@property (strong, nonatomic) NSIndexPath *nsindexpathFontTypeLastIndexPath;

//----------------------------------------------------------------------------------------

//tool bar button
@property (weak, nonatomic) IBOutlet UIBarButtonItem *uibarbuttonitemEditCommentButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *uibarbuttonitemEditFontButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *uibarbuttonitemTrashButton;

//----------------------------------------------------------------------------------------

//edit comment declares
@property (strong, nonatomic) IBOutlet UITextView *uitextviewCommentShow;
@property (strong, nonatomic) IBOutlet UIControl *uicontrolEditCommentView;
@property (weak, nonatomic) IBOutlet UIToolbar *uitoolbarEditComment;
@property (strong, nonatomic) IBOutlet UIControl *uicontrolEncrytTextView;
@property (strong, nonatomic) IBOutlet UITextView *uitextviewCommentTextView;
@property (strong, nonatomic) IBOutlet UITextView *uitextviewEncryptTextShow;
@property (strong, nonatomic) IBOutlet UITextField *uitextfieldPasswardTextField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *uibarbuttonitemEditCommentCancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *uibarbutoonitemEditCommentEnsureButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *uibarbuttonitemNone;
@property (weak, nonatomic) IBOutlet UILabel *uilabelEncode;
@property (weak, nonatomic) IBOutlet UILabel *uilabelKey;
@property (weak, nonatomic) IBOutlet UISwitch *uiswitchPasswardSwitch;
@property uint uintCnt;
//@property uint uintDataLen;

//----------------------------------------------------------------------------------------

//encode declares
@property (strong, nonatomic) IBOutlet UIControl *uicontrolEncodeView;
@property (weak, nonatomic) IBOutlet UIToolbar *uitoolbarEncodeBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *uibarbuttonitemEncodeCancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *uibarbuttonitemEncodeSureButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *uibarbuttonitemDecodeNone;
@property (strong, nonatomic) IBOutlet UITextField *uitextfieldEncodeTextField;
@property (weak, nonatomic) IBOutlet UILabel *uilabelDecodeWrongAlert;
@property (weak, nonatomic) IBOutlet UILabel *uilabelDecodeNone;
@property BOOL boolHaveEncoded;

//----------------------------------------------------------------------------------------

//image picker methods
//- (IBAction)shootPictureOrVideo:(id)sender;
//- (IBAction)selectExistingPictureOrVideo:(id)sender;

//----------------------------------------------------------------------------------------

//edit comment methods
- (IBAction)editCommentViewShow:(id)sender;
- (IBAction)editCommentViewCancel:(id)sender;
- (IBAction)switchChanged:(id)sender;
- (IBAction)textFieldDone:(id)sender;
- (IBAction)editCommentViewEnsure:(id)sender;

//----------------------------------------------------------------------------------------

//background touch
- (IBAction)backgroundTouch:(id)sender;

//----------------------------------------------------------------------------------------

//encode methods
- (IBAction)encodeViewCancel:(id)sender;
- (IBAction)encodeViewEnsure:(id)sender;

//----------------------------------------------------------------------------------------

//delete asset method
- (IBAction)deleteAsset:(id)sender;

//----------------------------------------------------------------------------------------

//swipe change Image
- (IBAction)swipeRight:(id)sender;
- (IBAction)swipeLeft:(id)sender;

//----------------------------------------------------------------------------------------

//- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated;

//----------------------------------------------------------------------------------------

@end

