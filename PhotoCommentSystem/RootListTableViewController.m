//
//  RootListTableViewController.m
//  PhotoCommentSystem
//
//  Created by CSIE on 2015/10/8.
//  Copyright © 2015年 CSIE. All rights reserved.
//

#import "RootListTableViewController.h"
#import "GridViewCollectionViewController.h"

@import Photos;

//----------------------------------------------------------------------------------------

@interface RootListTableViewController ()

//Get Album Name and SandBox Path
@property (strong) NSMutableDictionary *nsmutabledictionaryAlbumName;
@property (strong) NSArray *nsarrayCollectionsLocalizedTitles;
@property (strong) NSString *nsstringSandBox;
@property (strong) NSMutableArray *nsmutablearrayAlbumsFetchResults;

//Temp store current textfield text
@property (strong) NSString *nsstringTempLast;
@property (strong) UITextField *uitextfieldCurrent;

@end

//----------------------------------------------------------------------------------------

@implementation RootListTableViewController

static NSString * const nsstringCameraRollReuseIdentifier = @"CameraRollCell";
static NSString * const nsstringPhotoCommentReuseIdentifier = @"PhotoCommentCell";

static NSString * const nsstringCameraRollSegue = @"showCameraRoll";
static NSString * const nsstringPhotoCommentSegue = @"showPhotoComment";
static NSString * const nsstringFontSetViewSegue = @"fontSetViewShow";

//----------------------------------------------------------------------------------------

#pragma mark- awakeFromNib and dealloc

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    //Get SandBox Path
    NSArray *nsarrayPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *nsstringDocumentDirectory = [nsarrayPath objectAtIndex:0];

    _nsstringSandBox = nsstringDocumentDirectory;

    NSLog(@"%@", _nsstringSandBox);

    //Get Config
    NSString *nsstringConfigPath = [nsstringDocumentDirectory stringByAppendingPathComponent:@"config.plist"];
        
    if (![[NSFileManager defaultManager] fileExistsAtPath:nsstringConfigPath])
        {
        NSString *nsstringBundle = [[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"];
        [[NSFileManager defaultManager] copyItemAtPath:nsstringBundle toPath:nsstringConfigPath error:nil];
        }
            
    NSMutableDictionary *nsmutabledictionaryConfigRoot = [[NSMutableDictionary alloc] initWithContentsOfFile:nsstringConfigPath];
    
    _nsuintegerTheme = [[nsmutabledictionaryConfigRoot objectForKey:@"Theme"] unsignedIntegerValue];
    
    UIImage *uiimageBackground = nil;
    UIImage *uiimageUpperBar = nil;
    UIImage *uiimageBottomBar = nil;

    //Set Theme
    switch (_nsuintegerTheme)
        {
        case 0:
            uiimageBackground = [UIImage imageNamed:@"MAINPAGE_BACKGROUND.png"];
            uiimageBottomBar = [UIImage imageNamed:@"BOTTOM_BAR.png"];
            uiimageUpperBar = [UIImage imageNamed:@"UPPER_BAR.png"];
            
            [self.tableView setBackgroundView:[[UIImageView alloc]
                initWithImage:uiimageBackground]];
            
//            [self.tableView setBackgroundColor:[UIColor colorWithPatternImage:uiimageBackground]];
            
            self.navigationController.navigationBar.barTintColor = [UIColor colorWithPatternImage:uiimageUpperBar];

            [self.navigationController.toolbar setBarTintColor:[UIColor colorWithPatternImage:uiimageBottomBar]];

            [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:0.294 green:0.686 blue:0.49 alpha:1]];

            [self.navigationController.navigationBar
                setTitleTextAttributes:@
                    {
                    NSFontAttributeName:[UIFont fontWithName:@"DFWaWaTC-W5" size:20.0],
                    NSForegroundColorAttributeName:[UIColor whiteColor]
                    }];
            
            [_uibarbuttonitemExplantion setTintColor:[UIColor colorWithRed:0.294 green:0.686 blue:0.49 alpha:1]];
            [_uibarbuttonitemSetting setTintColor:[UIColor colorWithRed:0.294 green:0.686 blue:0.49 alpha:1]];
            break;
        case 1:
            uiimageBackground = [UIImage imageNamed:@"MAINPAGE_BACKGROUND_White.png"];
            uiimageBottomBar = [UIImage imageNamed:@"BOTTOM_BAR_White.png"];
            uiimageUpperBar = [UIImage imageNamed:@"UPPER_BAR_White.png"];
            
            [self.tableView setBackgroundView:[[UIImageView alloc]
                initWithImage:uiimageBackground]];
            
            self.navigationController.navigationBar.barTintColor = [UIColor colorWithPatternImage:uiimageUpperBar];

            [self.navigationController.toolbar setBarTintColor:[UIColor colorWithPatternImage:uiimageBottomBar]];

            [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:1]];

            [self.navigationController.navigationBar
                setTitleTextAttributes:@
                    {
                    NSFontAttributeName:[UIFont fontWithName:@"DFWaWaTC-W5" size:20.0],
                    NSForegroundColorAttributeName:[UIColor colorWithRed:0.294 green:1 blue:1 alpha:1]
                    }];

            [_uibarbuttonitemExplantion setTintColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:1]];
            [_uibarbuttonitemSetting setTintColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:1]];
            break;
        default:
            break;
        }

    //改變導覽列Back Button字型與大小，
    [self.navigationItem.backBarButtonItem
        setTitleTextAttributes:@
            {
            NSFontAttributeName:[UIFont fontWithName:@"DFWaWaTC-W5" size:17.0],
            }
        forState:UIControlStateNormal];
    self.navigationItem.backBarButtonItem.title = @"返回";

    [_uibarbuttonitemExplantion setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"DFWaWaTC-W5" size:17.0]} forState:UIControlStateNormal];
    
    [_uibarbuttonitemEdit setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"DFWaWaTC-W5" size:17.0]} forState:UIControlStateNormal];
    
    [_uibarbuttonitemSetting setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"DFWaWaTC-W5" size:17.0]} forState:UIControlStateNormal];
    
    //custom Addbutton Image
    uiimageBackground = [[UIImage imageNamed:@"AddButton.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];

//    UIButton *uibutton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
//    [uibutton setBackgroundImage:uiimageBackground forState:UIControlStateNormal];
//    [uibutton addTarget:self action:@selector(newAlbum:) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *uibarbuttonitem = [[UIBarButtonItem alloc] initWithImage:uiimageBackground style:UIBarButtonItemStylePlain target:self action:@selector(newAlbum:)];
    self.navigationItem.leftBarButtonItem = uibarbuttonitem;
    
    NSFileManager *nsfilemanagerFileManager = [NSFileManager defaultManager];
    
    //確認沙盒裡有albumname.plist 如果沒有就建立一個
    if (![nsfilemanagerFileManager fileExistsAtPath:[self.nsstringSandBox stringByAppendingPathComponent:@"albumname.plist"] isDirectory:NULL])
        {
        NSString *nsstringBundle = [[NSBundle mainBundle] pathForResource:@"AlbumName" ofType:@"plist"];
        [nsfilemanagerFileManager copyItemAtPath:nsstringBundle toPath:[_nsstringSandBox stringByAppendingPathComponent:@"albumname.plist"] error:nil];
        }
    
    //宣告一NSMutableDictionary來取得在沙盒內的所有Album Name
    NSMutableDictionary *nsmutabledictionaryAlbumRoot = [[NSMutableDictionary alloc] initWithContentsOfFile:[_nsstringSandBox stringByAppendingPathComponent:@"albumname.plist"]];
    _nsmutabledictionaryAlbumName = nsmutabledictionaryAlbumRoot;

    //確認沙盒裡有目錄 如果沒有就建立一個
    if (![nsfilemanagerFileManager fileExistsAtPath:[_nsstringSandBox stringByAppendingPathComponent:@"Photo Comment/0"] isDirectory:NULL])
        [nsfilemanagerFileManager createDirectoryAtPath:[_nsstringSandBox stringByAppendingPathComponent:@"Photo Comment/0"] withIntermediateDirectories:YES attributes:nil error:NULL];
    
    //宣告一NSArray來存放在沙盒內的所有Album 目錄
    NSArray *nsarrayAlbums = [nsfilemanagerFileManager contentsOfDirectoryAtPath:[_nsstringSandBox stringByAppendingPathComponent:@"Photo Comment"] error:NULL];
    
    NSMutableArray *nsmutablearrayAlbums = [NSMutableArray array];

    dispatch_async(dispatch_get_global_queue(0, 0), ^
        {
        BOOL boolIsDirectory;
        for (int i = 0; i < nsarrayAlbums.count; i++)
            {
            [nsfilemanagerFileManager fileExistsAtPath:[_nsstringSandBox stringByAppendingPathComponent:[NSString stringWithFormat:@"Photo Comment/%@",nsarrayAlbums[i]]] isDirectory:&boolIsDirectory];
            
            if (boolIsDirectory)
                [nsmutablearrayAlbums addObject:nsarrayAlbums[i]];
            }
        
        //NSArray放入全域變數
        self.nsmutablearrayAlbumsFetchResults = nsmutablearrayAlbums;
        });

    //將table 不同section的title放到全域變數中
    self.nsarrayCollectionsLocalizedTitles = @[NSLocalizedString(@"相片分享目錄", @""), NSLocalizedString(@"私用目錄", @"")];
    
}

//----------------------------------------------------------------------------------------

- (void)dealloc
{
    _nsmutabledictionaryAlbumName = nil;
    _nsarrayCollectionsLocalizedTitles = nil;
    _nsstringSandBox = nil;
    _nsmutablearrayAlbumsFetchResults = nil;
    _nsstringTempLast = nil;
    _uitextfieldCurrent = nil;

}

//----------------------------------------------------------------------------------------

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}
//----------------------------------------------------------------------------------------

#pragma mark- UIViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    GridViewCollectionViewController *gridviewcollectionviewcontroller = segue.destinationViewController;

    //確認等下是要到哪個Album中
    if ([segue.identifier isEqualToString:nsstringCameraRollSegue])
        {
        // Fetch all assets, sorted by date created.
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
        
        gridviewcollectionviewcontroller.phfetchresultFetchAssets = [PHAsset fetchAssetsWithOptions:options];
        gridviewcollectionviewcontroller.nsstringAlbumName = @"Camera Roll";
        gridviewcollectionviewcontroller.delegate = self;
        }
    else if ([segue.identifier isEqualToString:nsstringPhotoCommentSegue])
        {
        NSIndexPath *nsindexpathIndex = [self.tableView indexPathForCell:sender];
        
        NSString *nsstringAlbumPath = _nsmutablearrayAlbumsFetchResults[nsindexpathIndex.row];
        NSString *nsstringAlbumName = [_nsmutabledictionaryAlbumName valueForKey:nsstringAlbumPath];
        
        NSArray *nsarrayFetchAssets = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[_nsstringSandBox stringByAppendingPathComponent:[NSString stringWithFormat:@"Photo Comment/%@",nsstringAlbumPath]] error:NULL];
            
        gridviewcollectionviewcontroller.nsarrayFetchAssets = nsarrayFetchAssets;
        gridviewcollectionviewcontroller.nsstringAlbumPath = [_nsstringSandBox stringByAppendingPathComponent: [NSString stringWithFormat:@"Photo Comment/%@",nsstringAlbumPath]];
        
        gridviewcollectionviewcontroller.nsstringAlbumName = nsstringAlbumName;
        
        gridviewcollectionviewcontroller.delegate = self;
        }
    else if ([segue.identifier isEqualToString:nsstringFontSetViewSegue])
        {
        FontSetViewController *fontsetviewcontroller = segue.destinationViewController;
        fontsetviewcontroller.delegate = self;
        }
    else
        ;
    gridviewcollectionviewcontroller.nsuintegerTheme = _nsuintegerTheme;

}

//----------------------------------------------------------------------------------------

#pragma mark- Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

//----------------------------------------------------------------------------------------

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger nsintegerNumberOfRows = 0;
    
    if (section == 0)
        {
        nsintegerNumberOfRows = 1; // "All Photos" section
        }
    else
        {
        nsintegerNumberOfRows = self.nsmutabledictionaryAlbumName.count;
        }
    return nsintegerNumberOfRows;
}

//----------------------------------------------------------------------------------------

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *uitableviewCell = nil;
    NSString *nsstringLocalizedTitle = nil;
    NSString *nsstringSubTitle = nil;
    
    if (indexPath.section == 0)
        {
        uitableviewCell = [tableView dequeueReusableCellWithIdentifier:nsstringCameraRollReuseIdentifier];
        if (uitableviewCell == nil)
            {
            uitableviewCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nsstringCameraRollReuseIdentifier];
            
            UITextField *uitextfield = [[UITextField alloc] initWithFrame:CGRectMake(15, 9, 200, 30)];
            uitextfield.enabled = NO;
            uitextfield.returnKeyType = UIReturnKeyDone;
            uitextfield.delegate = self;
            [uitextfield addTarget:self action:@selector(textFieldDone:) forControlEvents:UIControlEventEditingDidEndOnExit];
            [uitableviewCell addSubview:uitextfield];
            
            UILabel *uilabel = [[UILabel alloc] initWithFrame:CGRectMake(uitextfield.frame.origin.x +215, uitextfield.frame.origin.y, 50, 30)];
            uilabel.userInteractionEnabled = NO;
            [uitableviewCell addSubview: uilabel];
            }
        nsstringLocalizedTitle = NSLocalizedString(@"Camera Roll", @"");
        
        PHFetchResult *phfetchresultAssets = [PHAsset fetchAssetsWithOptions:nil];

        nsstringSubTitle = [NSString stringWithFormat:@"%d",(unsigned int)phfetchresultAssets.count];
        }
    else
        {
        uitableviewCell = [tableView dequeueReusableCellWithIdentifier:nsstringPhotoCommentReuseIdentifier];

        if (uitableviewCell == nil)
            {
            uitableviewCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nsstringPhotoCommentReuseIdentifier];
            
            UITextField *uitextfield = [[UITextField alloc] init];
            uitextfield.returnKeyType = UIReturnKeyDone;
            uitextfield.delegate = self;
            [uitextfield addTarget:self action:@selector(textFieldDone:) forControlEvents:UIControlEventEditingDidEndOnExit];
            [uitableviewCell addSubview:uitextfield];

            UILabel *uilabel = [[UILabel alloc] initWithFrame:CGRectMake(uitextfield.frame.origin.x +215, uitextfield.frame.origin.y, 50, 30)];
            uilabel.userInteractionEnabled = NO;
            [uitableviewCell addSubview: uilabel];
            }
        NSString *nsstringAlbumName = [_nsmutabledictionaryAlbumName valueForKey: _nsmutablearrayAlbumsFetchResults[indexPath.row]];
        
        nsstringLocalizedTitle = nsstringAlbumName;
        
        NSArray *nsarrayAssets = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[_nsstringSandBox stringByAppendingPathComponent:[NSString stringWithFormat:@"Photo Comment/%@",_nsmutablearrayAlbumsFetchResults[indexPath.row]]] error:nil];
            
        nsstringSubTitle = [NSString stringWithFormat:@"%d",(unsigned int)nsarrayAssets.count];
        }
    UITextField *uitextfield = nil;
    UILabel *uilabel = nil;
    for (UIView *uiview in uitableviewCell.subviews)
        {
        if ([uiview isMemberOfClass:[UITextField class]])
                uitextfield = (UITextField *)uiview;
        if ([uiview isMemberOfClass:[UILabel class]])
            uilabel = (UILabel *)uiview;
        }
    uitextfield.text = nsstringLocalizedTitle;
    
    [uitextfield setFont:[UIFont fontWithName:@"STKaiTi-TC-Regular" size:21]];
    
    uitextfield.frame = tableView.editing ?
        CGRectMake(65, 9, 200, 30) : CGRectMake(15, 9, 200, 30);
    
    uitextfield.enabled = indexPath.section != 0 && tableView.editing;
    
    if (_uitextfieldCurrent == uitextfield)
        _uitextfieldCurrent = nil;
    
    uitextfield.tag = indexPath.section == 0 ? -1 : indexPath.row;
    
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    uilabel.frame = CGRectMake(uitextfield.frame.origin.x +215, uitextfield.frame.origin.y, 50, 30);
    uilabel.text = nsstringSubTitle;
    [uilabel setFont:[UIFont fontWithName:@"STKaiTi-TC-Regular" size:21]];

    //Set Theme
    switch (_nsuintegerTheme)
        {
        case 0:
            uitextfield.textColor = self.tableView.editing && uitextfield.tag == -1 ? [UIColor grayColor]:[UIColor whiteColor];
            uilabel.textColor = self.tableView.editing && uitextfield.tag == -1 ? [UIColor grayColor]:[UIColor whiteColor];
            [uitableviewCell setBackgroundColor:[UIColor clearColor]];
            break;

        case 1:
            uitextfield.textColor = self.tableView.editing && uitextfield.tag == -1 ? [UIColor grayColor]:[UIColor blackColor];
            uilabel.textColor = self.tableView.editing && uitextfield.tag == -1 ? [UIColor grayColor]:[UIColor blackColor];
            [uitableviewCell setBackgroundColor:[UIColor clearColor]];
            break;

        default:
            uitextfield.textColor = self.tableView.editing && uitextfield.tag == -1 ? [UIColor grayColor]:[UIColor blackColor];
            uilabel.textColor = self.tableView.editing && uitextfield.tag == -1 ? [UIColor grayColor]:[UIColor blackColor];
            [uitableviewCell setBackgroundColor:[UIColor whiteColor]];
            break;
        }
    return uitableviewCell;
}

//----------------------------------------------------------------------------------------

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *nsstringTitle = nil;
    
    if (section == 0)
        {
        nsstringTitle = self.nsarrayCollectionsLocalizedTitles[0];
        }
    else
        nsstringTitle = self.nsarrayCollectionsLocalizedTitles[1];
    
    return nsstringTitle;
}

//--------------------------------------------------------------------------------------

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *uiviewHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 50, tableView.frame.size.width, 21)];
    UILabel *uilabelHeader;
    
    if (section == 0)
        uilabelHeader = [[UILabel alloc] initWithFrame:CGRectMake(10, 30, tableView.frame.size.width, 21)];
    else
        uilabelHeader = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, tableView.frame.size.width, 21)];
    
    [uilabelHeader setFont:[UIFont fontWithName:@"Weibei-TC-Bold" size:21]];
    
    uilabelHeader.text = _nsarrayCollectionsLocalizedTitles[section];
    
//    UIImage *uiimageBachground;
    
    switch (_nsuintegerTheme)
        {
        case 0:
//            uiimageBachground = [UIImage imageNamed:@"FolderArea_BACKGROUND.png"];
            [uilabelHeader setBackgroundColor:[UIColor clearColor]];//[UIColor colorWithPatternImage:uiimageBachground]];
            [uilabelHeader setTextColor:[UIColor redColor]];
            break;

        case 1:
            [uilabelHeader setBackgroundColor:[UIColor clearColor]];//[UIColor colorWithPatternImage:uiimageBachground]];
            [uilabelHeader setTextColor:[UIColor colorWithRed:0.294 green:0.294 blue:0.784 alpha:1]];
            break;

        default:
            [uilabelHeader setTextColor:[UIColor grayColor]];
            break;
        }
    [uiviewHeader addSubview:uilabelHeader];
    return uiviewHeader;
}

//--------------------------------------------------------------------------------------

#pragma mark- TableView Delegate Methods

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger nsuintegerRow = [indexPath row];
    
    UIAlertController *uialertcontroller = [UIAlertController
        alertControllerWithTitle:[NSString stringWithFormat:@"刪除 \"%@\"",
            [_nsmutabledictionaryAlbumName valueForKey:_nsmutablearrayAlbumsFetchResults[nsuintegerRow]]]
        message:[NSString stringWithFormat:@"你確定要刪除相簿 \"%@\"?\n裡面的相片也會被刪除",
            [_nsmutabledictionaryAlbumName valueForKey:_nsmutablearrayAlbumsFetchResults[nsuintegerRow]]]
        preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *uialertactionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *uialertactionDelete = [UIAlertAction actionWithTitle:@"刪除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action)
        {
        [self.nsmutabledictionaryAlbumName removeObjectForKey:_nsmutablearrayAlbumsFetchResults[nsuintegerRow]];
    
        [_nsmutabledictionaryAlbumName writeToFile:[_nsstringSandBox stringByAppendingPathComponent:@"albumname.plist"] atomically:YES];
    
        [[NSFileManager defaultManager] removeItemAtPath:[_nsstringSandBox stringByAppendingPathComponent:[NSString stringWithFormat:@"Photo Comment/%@",_nsmutablearrayAlbumsFetchResults[nsuintegerRow]]] error:nil];
    
        [_nsmutablearrayAlbumsFetchResults removeObjectAtIndex:nsuintegerRow];
    
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        }];
    [uialertcontroller addAction:uialertactionCancel];
    [uialertcontroller addAction:uialertactionDelete];
    [self presentViewController:uialertcontroller animated:YES completion:nil];
    
}

//----------------------------------------------------------------------------------------

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger nsuintegerRow = [indexPath row];
    
    if (nsuintegerRow == 0)
        return UITableViewCellEditingStyleNone;
    else
        return UITableViewCellEditingStyleDelete;
}
//----------------------------------------------------------------------------------------

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *uitableviewcell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (indexPath.section == 0)
        [self performSegueWithIdentifier:nsstringCameraRollSegue sender:uitableviewcell];
    else
        [self performSegueWithIdentifier:nsstringPhotoCommentSegue sender:uitableviewcell];

}
//----------------------------------------------------------------------------------------

#pragma mark- TextField Delegate Methods

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.uitextfieldCurrent = textField;
    self.nsstringTempLast = textField.text;
}

//----------------------------------------------------------------------------------------

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if ([textField.text isEqualToString:@""])
        textField.text = _nsstringTempLast;
    [_nsmutabledictionaryAlbumName setValue:textField.text forKey:_nsmutablearrayAlbumsFetchResults[textField.tag]];
}

//----------------------------------------------------------------------------------------

#pragma mark - IBAction Methods

- (void)newAlbum:(id)sender
{
    // Prompt user from new album title.
    UIAlertController *uialertcontroller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"New Album", @"") message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [uialertcontroller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:NULL]];
    [uialertcontroller addTextFieldWithConfigurationHandler:^(UITextField *textField)
        {
        textField.placeholder = NSLocalizedString(@"Album Name", @"");
        [textField addTarget:self action:@selector(alertTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        }];
    
    UIAlertAction *uialertactionCreate = [UIAlertAction actionWithTitle:NSLocalizedString(@"Create", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action)
            {
            UITextField *uitextfield = uialertcontroller.textFields.firstObject;
            NSString *nsstringTitle = uitextfield.text;

            // Create new album.
            uint uintName = 0;
            
            for (uintName = 0; uintName < _nsmutablearrayAlbumsFetchResults.count; uintName++)
                {
                if (![_nsmutablearrayAlbumsFetchResults[uintName] isEqualToString:[NSString stringWithFormat:@"%i",uintName]])
                    break;
                }
            [[NSFileManager defaultManager] createDirectoryAtPath:[_nsstringSandBox stringByAppendingPathComponent:[NSString stringWithFormat:@"Photo Comment/%i",uintName]] withIntermediateDirectories:YES attributes:nil error:nil];
            
            [_nsmutablearrayAlbumsFetchResults addObject:[NSString stringWithFormat:@"%i",uintName]];
            
            [_nsmutabledictionaryAlbumName setObject:nsstringTitle forKey:[NSString stringWithFormat:@"%i",uintName]];
            
            
            [_nsmutabledictionaryAlbumName writeToFile:[_nsstringSandBox stringByAppendingPathComponent:@"albumname.plist"] atomically:YES];
            dispatch_async(dispatch_get_main_queue(), ^
                {
                [self.tableView reloadData];
                });
            }];
    uialertactionCreate.enabled = NO;
    [uialertcontroller addAction:uialertactionCreate];
    
    [self presentViewController:uialertcontroller animated:YES completion:NULL];
}

//--------------------------------------------------------------------------------------

- (IBAction)EditAlbum:(id)sender
{
    [self.tableView setEditing:!self.tableView.editing animated:YES];
    
    UITextField *uitextfield = nil;
    UILabel *uilabel = nil;
    if (self.tableView.editing)
        {
        [_uibarbuttonitemEdit setTitle:@"Done"];
        [_uibarbuttonitemEdit setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"DFWaWaTC-W5" size:17.0]} forState:UIControlStateNormal];
        
        for (UITableViewCell *uitableviewcell in self.tableView.visibleCells)
            {
            for (UIView *uiview in uitableviewcell.subviews)
                {
                if ([uiview isMemberOfClass:[UITextField class]])
                    {
                    uitextfield = (UITextField *)uiview;
                    
                    [UIView animateWithDuration:0.3 delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                        animations:^
                            {
                            [uitextfield setFrame:CGRectMake(65, 9, 200, 30)];
                            if (uitextfield.tag == -1)
                                uitextfield.textColor = [UIColor grayColor];
                            else
                                uitextfield.enabled = YES;
                            }
                        completion:nil];
                    }
    
                if ([uiview isMemberOfClass:[UILabel class]])
                    {
                    uilabel = (UILabel *)uiview;
                    
                    [UIView animateWithDuration:0.3 delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                        animations:^
                            {
                            [uilabel setFrame:CGRectMake(uitextfield.frame.origin.x +215, uitextfield.frame.origin.y, 50, 30)];
                            if (uitextfield.tag == -1)
                                uilabel.textColor = [UIColor grayColor];
                            }
                        completion:nil];
                    }
                }
            }
        }
    else
        {
        [_uibarbuttonitemEdit setTitle:@"Edit"];
        [_uibarbuttonitemEdit setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"DFWaWaTC-W5" size:17.0]} forState:UIControlStateNormal];

        for (UITableViewCell *uitableviewcell in self.tableView.visibleCells)
            for (UIView *uiview in uitableviewcell.subviews)
                {
                if ([uiview isMemberOfClass:[UITextField class]])
                    {
                    uitextfield = (UITextField *)uiview;
                    
                    [UIView animateWithDuration:0.3 delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                        animations:^
                            {
                            [uitextfield setFrame:CGRectMake(15, 9, 200, 30)];
                            if (uitextfield.tag == -1)
                                {
                                switch (_nsuintegerTheme)
                                    {
                                    case 0:
                                        uitextfield.textColor = [UIColor whiteColor];
                                        break;
                                    case 1:
                                        uitextfield.textColor = [UIColor blackColor];
                                        break;
                                    default:
                                        uitextfield.textColor = [UIColor blackColor];
                                    }
                                }
                            else
                                uitextfield.enabled = NO;
                            }
                        completion:nil];
                    }
    
                if ([uiview isMemberOfClass:[UILabel class]])
                    {
                    uilabel = (UILabel *)uiview;
                    
                    [UIView animateWithDuration:0.3 delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                        animations:^
                            {
                            [uilabel setFrame:CGRectMake(uitextfield.frame.origin.x +215, uitextfield.frame.origin.y, 50, 30)];
                            if (uitextfield.tag == -1)
                                {
                                switch (_nsuintegerTheme)
                                    {
                                    case 0:
                                        uilabel.textColor = [UIColor whiteColor];
                                        break;
                                    case 1:
                                        uilabel.textColor = [UIColor blackColor];
                                        break;
                                    default:
                                        uilabel.textColor = [UIColor blackColor];
                                    }
                                }
                            }
                        completion:nil];
                    }
                }
        if (_uitextfieldCurrent != nil)
            {
            [_nsmutabledictionaryAlbumName writeToFile:[_nsstringSandBox stringByAppendingPathComponent:@"albumname.plist"] atomically:YES];
            _uitextfieldCurrent = nil;
            }
        }
}

//----------------------------------------------------------------------------------------

- (IBAction)textFieldDone:(id)sender
{
    [sender resignFirstResponder];
}

//----------------------------------------------------------------------------------------

#pragma mark- Alert TextField Text Change Methods

- (void)alertTextFieldDidChange:(UITextField *)sender
{
    UIAlertController *uialertcontroller = (UIAlertController *)self.presentedViewController;
    if (uialertcontroller)
        {
        UITextField *uitextfield = (UITextField *)sender;
        UIAlertAction *uialertactionCreate = uialertcontroller.actions.lastObject;
        
        uialertactionCreate.enabled = uitextfield.text.length > 0;
        }
}

//----------------------------------------------------------------------------------------

#pragma mark- Set Theme Delegate Method

- (void)setRootViewBackgroundWithTheme:(NSUInteger)Theme
{
    _nsuintegerTheme = Theme;
    
    UIImage *uiimageBackground = nil;
    
    //Set Theme
    switch (_nsuintegerTheme)
        {
        case 0:
            uiimageBackground = [UIImage imageNamed:@"MAINPAGE_BACKGROUND.png"];
            self.tableView.backgroundView = [[UIImageView alloc] initWithImage:uiimageBackground];
            
            [_uibarbuttonitemExplantion setTintColor:[UIColor colorWithRed:0.294 green:0.686 blue:0.49 alpha:1]];
            [_uibarbuttonitemSetting setTintColor:[UIColor colorWithRed:0.294 green:0.686 blue:0.49 alpha:1]];
            break;

        case 1:
            uiimageBackground = [UIImage imageNamed:@"MAINPAGE_BACKGROUND_White.png"];
            self.tableView.backgroundView = [[UIImageView alloc] initWithImage:uiimageBackground];
            
            [_uibarbuttonitemExplantion setTintColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:1]];
            [_uibarbuttonitemSetting setTintColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:1]];
            break;

        default:
            [self.tableView setBackgroundView:nil];
            
            [_uibarbuttonitemExplantion setTintColor:nil];
            [_uibarbuttonitemSetting setTintColor:nil];

//            [self.tableView setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
            break;
        }
}

//----------------------------------------------------------------------------------------

#pragma mark- FontSetDelegate Methods

- (void)setViewBackgroundWithTheme:(NSUInteger)Theme
{
    _nsuintegerTheme = Theme;
    UIImage *uiimageBackground = nil;
    
    //Set Theme
    switch (_nsuintegerTheme)
        {
        case 0:
            uiimageBackground = [UIImage imageNamed:@"MAINPAGE_BACKGROUND.png"];
            self.tableView.backgroundView = [[UIImageView alloc] initWithImage:uiimageBackground];
            
            [_uibarbuttonitemExplantion setTintColor:[UIColor colorWithRed:0.294 green:0.686 blue:0.49 alpha:1]];
            [_uibarbuttonitemSetting setTintColor:[UIColor colorWithRed:0.294 green:0.686 blue:0.49 alpha:1]];
            break;

        case 1:
            uiimageBackground = [UIImage imageNamed:@"MAINPAGE_BACKGROUND_White.png"];
            self.tableView.backgroundView = [[UIImageView alloc] initWithImage:uiimageBackground];
            
            [_uibarbuttonitemExplantion setTintColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:1]];
            [_uibarbuttonitemSetting setTintColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:1]];
            break;

        default:
            [self.tableView setBackgroundView:nil];
            
            [_uibarbuttonitemExplantion setTintColor:nil];
            [_uibarbuttonitemSetting setTintColor:nil];
            break;
        }
}

//----------------------------------------------------------------------------------------

- (void)fontSettingPassToViewController:(NSString *)fontSizeValue ColorSet:(NSString *)fontColorValue TypeSet:(NSString *)fontTypeValue FontSizeLast:(NSIndexPath *)fontSizeIndexPath FontColorLast:(NSIndexPath *)fontColorIndexPath FontTypeLast:(NSIndexPath *)fontTypeIndexPath
{
}

//----------------------------------------------------------------------------------------

@end
