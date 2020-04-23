//
//  CreateToAlbumTableViewController.m
//  PhotoCommentSystem
//
//  Created by CSIE on 2015/10/18.
//  Copyright © 2015年 CSIE. All rights reserved.
//

#import "CreateToAlbumTableViewController.h"

@import Photos;

//----------------------------------------------------------------------------------------

@interface CreateToAlbumTableViewController ()

@property (strong) NSString *nsstringSandBox;
@property (strong) NSArray *nsarrayAlbumsFetchResults;
@property (strong) NSDictionary *nsdictionaryAlbumName;
@property (strong) NSArray *nsarrayCollectionsLocalizedTitles;

//New Asset
@property (strong) NSString *nsstringNew;

//新增照片到沙盒
- (void)createPhotoToSandBox:(NSIndexPath *)nsindexPath;

@end

//----------------------------------------------------------------------------------------

@implementation CreateToAlbumTableViewController

static NSString * const nsstringAlbumReuseIdentifier = @"Album";

//----------------------------------------------------------------------------------------

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Set Theme
    UIImage *uiimageBackground = nil;

    switch (_nsuintegerTheme)
        {
        case 0:
            uiimageBackground = [UIImage imageNamed:@"MAINPAGE_BACKGROUND.png"];
            [self.tableView setBackgroundView:[[UIImageView alloc] initWithImage:uiimageBackground]];
            break;

        case 1:
            uiimageBackground = [UIImage imageNamed:@"MAINPAGE_BACKGROUND_White.png"];
            [self.tableView setBackgroundView:[[UIImageView alloc] initWithImage:uiimageBackground]];
            break;

        default:
            break;
        }

    //取得沙盒目錄
    NSArray *nsarrayPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *nsstringDocumentDirectory = [nsarrayPath objectAtIndex:0];
    self.nsstringSandBox = nsstringDocumentDirectory;
    
    //宣告一NSMutableDictionary來取得在沙盒內的所有Album Name
    NSMutableDictionary *nsmutabledictionaryRoot = [[NSMutableDictionary alloc] initWithContentsOfFile:[_nsstringSandBox stringByAppendingPathComponent:@"albumname.plist"]];
    _nsdictionaryAlbumName = nsmutabledictionaryRoot;

    NSFileManager *nsfilemanagerFileManager = [NSFileManager defaultManager];
    
    //宣告一NSArray來存放在沙盒內的所有Album Name
    NSArray *nsarrayAlbums = [nsfilemanagerFileManager contentsOfDirectoryAtPath:[_nsstringSandBox stringByAppendingPathComponent:@"Photo Comment"] error:NULL];
    
    NSMutableArray *nsmutablearrayAlbums = [NSMutableArray array];

    if ([self.nsstringAlbumName isEqualToString:@"Camera Roll"])
        {
        dispatch_async(dispatch_get_global_queue(0, 0), ^
            {
            BOOL boolIsDirectory;
            for (int i = 0; i < nsarrayAlbums.count; i++)
                {
                [nsfilemanagerFileManager fileExistsAtPath:[self.nsstringSandBox stringByAppendingPathComponent:[NSString stringWithFormat:@"Photo Comment/%@",nsarrayAlbums[i]]] isDirectory:&boolIsDirectory];
                if (boolIsDirectory)
                    [nsmutablearrayAlbums addObject:nsarrayAlbums[i]];
                }
            });
        }
    else
        {
        dispatch_async(dispatch_get_global_queue(0, 0), ^
            {
            [nsmutablearrayAlbums addObject:@"Camera Roll"];
            
            BOOL boolIsDirectory;
            for (int i = 0; i < nsarrayAlbums.count; i++)
                {
                [nsfilemanagerFileManager fileExistsAtPath:[self.nsstringSandBox stringByAppendingPathComponent:[NSString stringWithFormat:@"Photo Comment/%@",nsarrayAlbums[i]]] isDirectory:&boolIsDirectory];
                
                if (boolIsDirectory && ![self.nsstringAlbumName isEqualToString:nsarrayAlbums[i]])
                    [nsmutablearrayAlbums addObject:nsarrayAlbums[i]];
                }
            });
        }
    
    //NSArray放入全域變數
    self.nsarrayAlbumsFetchResults = nsmutablearrayAlbums;
    
    self.nsarrayCollectionsLocalizedTitles = @[NSLocalizedString(@"相片分享目錄", @""), NSLocalizedString(@"私用目錄", @"")];
}

//----------------------------------------------------------------------------------------

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    _nsstringSandBox = nil;
    _nsarrayAlbumsFetchResults = nil;
    _nsstringAlbumName = nil;
    _nsdataGlobalData = nil;
    _nsdictionaryAlbumName = nil;
    _nsarrayCollectionsLocalizedTitles = nil;
    
}

//----------------------------------------------------------------------------------------

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([_nsstringAlbumName isEqualToString:@"Camera Roll"])
        return 1;
    else
        return 2;
}

//----------------------------------------------------------------------------------------

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([_nsstringAlbumName isEqualToString:@"Camera Roll"])
        return _nsarrayAlbumsFetchResults.count;
    else
        {
        if (section == 0)
            return 1;
        else
            return _nsarrayAlbumsFetchResults.count - 1;
        }
}

//----------------------------------------------------------------------------------------

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *uitableviewCell = nil;
    NSString *nsstringLocalizedTitle = nil;
    
    uitableviewCell = [tableView dequeueReusableCellWithIdentifier:nsstringAlbumReuseIdentifier forIndexPath:indexPath];
        
    if ([_nsstringAlbumName isEqualToString:@"Camera Roll"])
        {
        NSString *nsstringAlbumNameTemp = _nsdictionaryAlbumName[_nsarrayAlbumsFetchResults[indexPath.row]];
        nsstringLocalizedTitle = nsstringAlbumNameTemp;
        }
    else
        nsstringLocalizedTitle = indexPath.section == 0 ?
            @"Camera Roll" : _nsdictionaryAlbumName[_nsarrayAlbumsFetchResults[indexPath.row + 1]];

    uitableviewCell.textLabel.text = nsstringLocalizedTitle;
    [uitableviewCell.textLabel setFont:[UIFont fontWithName:@"STKaiTi-TC-Regular" size:21]];

    //Set Theme
    switch (_nsuintegerTheme)
        {
        case 0:
            uitableviewCell.backgroundColor = [UIColor clearColor];
            [uitableviewCell.textLabel setTextColor:[UIColor whiteColor]];
            break;

        case 1:
            uitableviewCell.backgroundColor = [UIColor clearColor];
            [uitableviewCell.textLabel setTextColor:[UIColor blackColor]];
            break;

        default:
            break;
        }
    [tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    return uitableviewCell;
}

//----------------------------------------------------------------------------------------

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *nsstringTitle = nil;
    
    if ([_nsstringAlbumName isEqualToString:@"Camera Roll"])
        nsstringTitle = self.nsarrayCollectionsLocalizedTitles[1];
    else
        nsstringTitle = section == 0 ?
            self.nsarrayCollectionsLocalizedTitles[0] : self.nsarrayCollectionsLocalizedTitles[1];
    
    return nsstringTitle;
}

//----------------------------------------------------------------------------------------

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
    
    switch (_nsuintegerTheme)
        {
        case 0:
            [uilabelHeader setBackgroundColor:[UIColor clearColor]];
            [uilabelHeader setTextColor:[UIColor redColor]];
            break;

        case 1:
            [uilabelHeader setBackgroundColor:[UIColor clearColor]];
            [uilabelHeader setTextColor:[UIColor colorWithRed:0.294 green:0.294 blue:0.784 alpha:1]];
            break;

        default:
            [uilabelHeader setTextColor:[UIColor grayColor]];
            break;
        }
    [uiviewHeader addSubview:uilabelHeader];
    return uiviewHeader;
}

//----------------------------------------------------------------------------------------

#pragma mark- Table Delegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.nsstringAlbumName isEqualToString:@"Camera Roll"])
        [self performSelector:@selector(createPhotoToSandBox:) withObject:indexPath];
    else
        {
        if (indexPath.section == 0)
            {
            NSString *nsstringFileName = [self.nsstringSandBox stringByAppendingPathComponent:@"test.jpg"];
            
            //確認檔案是否已存在 如果以存在就直接覆寫 如果不存在就建立一個新的檔案
            if ([[NSFileManager defaultManager]fileExistsAtPath:nsstringFileName])
                [_nsdataGlobalData writeToFile:nsstringFileName atomically:YES];
            else
                [[NSFileManager defaultManager] createFileAtPath:nsstringFileName contents:_nsdataGlobalData attributes:nil];
            
            //建立一張照片
            [[PHPhotoLibrary sharedPhotoLibrary]
                performChanges:^
                    {
                    PHAssetChangeRequest *phassetchangerequest = [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:[NSURL URLWithString:nsstringFileName]];
                    _nsstringNew = phassetchangerequest.placeholderForCreatedAsset.localIdentifier;
                    
                    }
                completionHandler:^(BOOL success, NSError *error)
                    {
                    dispatch_async(dispatch_get_main_queue(), ^
                        {
                        [self.delegate sendNewPhAsset:_nsstringNew AlbumName:@"Camera Roll"];
                        [[self navigationController] popViewControllerAnimated:YES];
                        });
                    }
                ];
            
            }
        else
            [self performSelector:@selector(createPhotoToSandBox:) withObject:indexPath];
        }
}

//----------------------------------------------------------------------------------------

#pragma mark- Create Photo To SandBox

- (void)createPhotoToSandBox:(NSIndexPath *)indexPath
{
    NSString *nsstringAlbumNameTemp= [_nsstringAlbumName isEqualToString:@"Camera Roll"] ?
        self.nsarrayAlbumsFetchResults[indexPath.row] : self.nsarrayAlbumsFetchResults[indexPath.row + 1];
    
    NSString *nsstringPath = [self.nsstringSandBox stringByAppendingPathComponent:
        [NSString stringWithFormat:@"Photo Comment/%@",nsstringAlbumNameTemp]];
        
    uint uintName = 0;
    NSArray *nsarrayAssets = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: nsstringPath error:nil];

    for (uintName = 0; uintName < nsarrayAssets.count; uintName++)
        {
        if (![nsarrayAssets[uintName] isEqualToString:[NSString stringWithFormat:@"%i.JPG",uintName]])
                break;
        }
            
    [[NSFileManager defaultManager] createFileAtPath:[nsstringPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%i.JPG",uintName]] contents:_nsdataGlobalData attributes:nil];
    
    [self.delegate haveChangedViewAlbum:nsstringPath AlbumName:[_nsdictionaryAlbumName objectForKey:nsstringAlbumNameTemp] Asset:[NSString stringWithFormat:@"%i.JPG",uintName]];
    
    dispatch_async(dispatch_get_main_queue(), ^
        {
        [[self navigationController] popViewControllerAnimated:YES];
        });
}

//----------------------------------------------------------------------------------------

@end
