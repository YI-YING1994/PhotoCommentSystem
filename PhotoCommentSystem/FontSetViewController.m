//
//  FontSetViewController.m
//  PhotoCommentSystem
//
//  Created by CSIE on 2015/9/20.
//  Copyright © 2015年 CSIE. All rights reserved.
//

#import "FontSetViewController.h"
#import "FontSetTableViewCell.h"
#import "ViewController.h"


@interface FontSetViewController ()

//Theme Array
@property (strong) NSArray *nsarrayThemes;

@end

@implementation FontSetViewController

//-------------------------------------------------------------------------------------------

//Table View
@synthesize uitableviewFontSetTableView;
@synthesize uitableviewFontDetailTableView;

//-------------------------------------------------------------------------------------------

//data Array
@synthesize nsmutablearrayFontSettings;
@synthesize nsarrayFontSizes;
@synthesize nsarrayFontColors;
@synthesize nsarrayFontTypes;

//-------------------------------------------------------------------------------------------

//font value set
@synthesize nsstringFontTypeValue;
@synthesize nsstringFontColorValue;
@synthesize nsstringFontSizeValue;
@synthesize nsuintegerFontSizeValue_UInt;

//-------------------------------------------------------------------------------------------

//Detail View Select & Last IndexPath
@synthesize nsuintegerDetailViewSelect;
@synthesize nsindexpathFontSizeLastIndexPath;
@synthesize nsindexpathFontColorLastIndexPath;
@synthesize nsindexpathFontTypeLastIndexPath;

//-------------------------------------------------------------------------------------------

//Demo Text View
@synthesize uitextviewFontDemoView;

//-------------------------------------------------------------------------------------------

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //Set Theme
    UIImage *uiimageBackground = nil;
    NSString *nsstringThemeName;

    //Set Font size Color and type
    if (nsstringFontSizeValue == nil || nsstringFontColorValue == nil || nsstringFontTypeValue == nil)
        {
        NSArray *nsarrayPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *nsstringDocumentDirectory = [nsarrayPath objectAtIndex:0];
        NSString *nsstringPath = [nsstringDocumentDirectory stringByAppendingPathComponent:@"config.plist"];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:nsstringPath])
            {
            NSString *nsstringBundle = [[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"];
            [[NSFileManager defaultManager] copyItemAtPath:nsstringBundle toPath:nsstringPath error:nil];
            }
            
        NSMutableDictionary *nsmutabledictionaryRoot = [[NSMutableDictionary alloc] initWithContentsOfFile:nsstringPath];
        
        //初始化文字大小、顏色、字型
        nsstringFontSizeValue = [nsmutabledictionaryRoot objectForKey:@"FontSizeValue"];
        nsuintegerFontSizeValue_UInt = [[nsmutabledictionaryRoot objectForKey:@"FontSizeValue_Int"] unsignedIntegerValue];

        switch (nsuintegerFontSizeValue_UInt)
            {
            case 17:nsindexpathFontSizeLastIndexPath = [NSIndexPath indexPathForRow:0 inSection:1];
                break;
            case 25:nsindexpathFontSizeLastIndexPath = [NSIndexPath indexPathForRow:1 inSection:1];
                break;
            case 35:nsindexpathFontSizeLastIndexPath = [NSIndexPath indexPathForRow:2 inSection:1];
                break;
            }

        nsstringFontColorValue = [nsmutabledictionaryRoot objectForKey:@"FontColorValue"];
        NSUInteger nsuintegerFontColorValue = [[nsmutabledictionaryRoot objectForKey:@"FontColorValue_Int"] unsignedIntegerValue];
        nsindexpathFontColorLastIndexPath = [NSIndexPath indexPathForRow:nsuintegerFontColorValue inSection:1];

        nsstringFontTypeValue = [nsmutabledictionaryRoot objectForKey:@"FontTypeValue"];
        NSUInteger nsuintegerFontTypeValue = [[nsmutabledictionaryRoot objectForKey:@"FontTypeValue_Int"] unsignedIntegerValue];
        nsindexpathFontTypeLastIndexPath = [NSIndexPath indexPathForRow:nsuintegerFontTypeValue inSection:1];
        }

    switch (_nsuintegerTheme)
        {
        case 0:
            uiimageBackground = [UIImage imageNamed:@"MAINPAGE_BACKGROUND.png"];
//            [uitextviewFontDemoView setBackgroundColor:[UIColor clearColor]];
            [_uiimageBackground setImage:uiimageBackground];
            nsstringThemeName = @"紫黑";
            break;

        case 1:
            uiimageBackground = [UIImage imageNamed:@"MAINPAGE_BACKGROUND_White.png"];
            [_uiimageBackground setImage:uiimageBackground];
            nsstringThemeName = @"紫白";
            break;

        default:
            [_uiimageBackground setImage:nil];
            nsstringThemeName = @"無";
            break;
        }

    //設定uilabelUseless的Font
    [self.uilabelUseless setFont:[UIFont fontWithName:@"DFWaWaTC-W5" size:17.0]];
    
    //Data put in Array
    NSDictionary *nsdictionaryRow1 = [[NSDictionary alloc] initWithObjectsAndKeys:@"文字大小",@"name",nsstringFontSizeValue,@"attribute", nil];
    NSDictionary *nsdictionaryRow2 = [[NSDictionary alloc] initWithObjectsAndKeys:@"文字顏色",@"name",nsstringFontColorValue,@"attribute", nil];
    NSDictionary *nsdictionaryRow3 = [[NSDictionary alloc] initWithObjectsAndKeys:@"文字字型",@"name",nsstringFontTypeValue,@"attribute", nil];
    NSDictionary *nsdictionaryRow4 = [[NSDictionary alloc] initWithObjectsAndKeys:@"主題",@"name",nsstringThemeName,@"attribute", nil];
    
    self.nsmutablearrayFontSettings = [[NSMutableArray alloc] initWithObjects:nsdictionaryRow1,nsdictionaryRow2,nsdictionaryRow3,nsdictionaryRow4, nil];
    self.nsarrayFontSizes = [[NSArray alloc] initWithObjects:@"小",@"中",@"大", nil];
    self.nsarrayFontColors = [[NSArray alloc] initWithObjects:@"白",@"紅",@"藍", nil];
    self.nsarrayFontTypes = [[NSArray alloc] initWithObjects:@"娃娃體",@"翩翩體",@"魏碑", nil];
    self.nsarrayThemes = [[NSArray alloc] initWithObjects:@"紫黑",@"紫白",@"無", nil];
    
    
    //font Size Setting
    if ([nsstringFontSizeValue isEqualToString:@"小"])
        {
        nsuintegerFontSizeValue_UInt = 17;
        [uitextviewFontDemoView setFont:[UIFont systemFontOfSize:nsuintegerFontSizeValue_UInt]];
        }
    else if ([nsstringFontSizeValue isEqualToString:@"中"])
        {
        nsuintegerFontSizeValue_UInt = 25;
        [uitextviewFontDemoView setFont:[UIFont systemFontOfSize:nsuintegerFontSizeValue_UInt]];
        }
    else if ([nsstringFontSizeValue isEqualToString:@"大"])
        {
        nsuintegerFontSizeValue_UInt = 35;
        [uitextviewFontDemoView setFont:[UIFont systemFontOfSize:nsuintegerFontSizeValue_UInt]];
        }
    
    //font Color Setting
    if ([nsstringFontColorValue isEqualToString:@"白"])
        [uitextviewFontDemoView setTextColor:[UIColor whiteColor]];
    else if ([nsstringFontColorValue isEqualToString:@"紅"])
        [uitextviewFontDemoView setTextColor:[UIColor redColor]];
    else if ([nsstringFontColorValue isEqualToString:@"藍"])
        [uitextviewFontDemoView setTextColor:[UIColor cyanColor]];
    
    //font Type Setting
    if ([nsstringFontTypeValue isEqualToString:@"娃娃體"])
        [uitextviewFontDemoView setFont:[UIFont fontWithName:@"DFWaWaTC-W5" size:nsuintegerFontSizeValue_UInt]];
    else if ([nsstringFontTypeValue isEqualToString:@"翩翩體"])
        [uitextviewFontDemoView setFont:[UIFont fontWithName:@"HanziPenTC-W5" size:nsuintegerFontSizeValue_UInt]];
    else if ([nsstringFontTypeValue isEqualToString:@"魏碑"])
        [uitextviewFontDemoView setFont:[UIFont fontWithName:@"Weibei-TC-Bold" size:nsuintegerFontSizeValue_UInt]];
}

//-------------------------------------------------------------------------------------------

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//-------------------------------------------------------------------------------------------

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //[fonSetTableView reloadData];
}

//-------------------------------------------------------------------------------------------

- (void)viewDidUnload
{
    //table View Outlet
    self.uitableviewFontSetTableView = nil;
    self.uitableviewFontDetailTableView = nil;
    
    //data Array
    self.nsmutablearrayFontSettings = nil;
    self.nsarrayFontSizes = nil;
    self.nsarrayFontColors = nil;
    self.nsarrayFontTypes = nil;
    
    //font Value
    self.nsstringFontSizeValue = nil;
    self.nsstringFontColorValue = nil;
    self.nsstringFontTypeValue = nil;
    [super viewDidUnload];
    
    //Detail View Select & Last indexPath
    self.nsindexpathFontSizeLastIndexPath = nil;
    self.nsindexpathFontColorLastIndexPath = nil;
    self.nsindexpathFontTypeLastIndexPath = nil;
    
    //Theme Array
    self.nsarrayThemes = nil;
}

//-------------------------------------------------------------------------------------------

#pragma mark - Table Data Source Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([tableView isEqual:uitableviewFontSetTableView])
        return [self.nsmutablearrayFontSettings count];
    else
        {
        switch (nsuintegerDetailViewSelect)
            {
            case 0:
                return [self.nsarrayFontSizes count];
                break;
            case 1:
                return [self.nsarrayFontColors count];
                break;
            case 2:
                return [self.nsarrayFontTypes count];
                break;
            default:
                return [self.nsarrayThemes count];
            }
        }
}

//-------------------------------------------------------------------------------------------

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

//-------------------------------------------------------------------------------------------

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:uitableviewFontSetTableView])
        {
        static NSString *nsstringFontSetCellIdentifier = @"Cell";
    
        static BOOL boolNibRegistered = NO;
    
        if (!boolNibRegistered)
            {
            UINib *nib = [UINib nibWithNibName:@"FontSetTableViewCell" bundle:nil];
            [tableView registerNib:nib forCellReuseIdentifier:nsstringFontSetCellIdentifier];
            }
    
        FontSetTableViewCell *fontsettableviewcellCell = [tableView dequeueReusableCellWithIdentifier:nsstringFontSetCellIdentifier];
    
        NSUInteger nsuintegerRow = [indexPath row];
        NSDictionary *nsdictionaryRowData = [self.nsmutablearrayFontSettings objectAtIndex:nsuintegerRow];
    
        fontsettableviewcellCell.nsstringName = [nsdictionaryRowData objectForKey:@"name"];
        fontsettableviewcellCell.nsstringAttribute = [nsdictionaryRowData objectForKey:@"attribute"];
        [tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];

        switch (_nsuintegerTheme)
            {
            case 0:
                fontsettableviewcellCell.backgroundColor = [UIColor blackColor];
                [tableView setBackgroundColor:[UIColor blackColor]];
                break;

            case 1:
                fontsettableviewcellCell.backgroundColor = [UIColor blackColor];
                [tableView setBackgroundColor:[UIColor blackColor]];
                break;

            default:
                fontsettableviewcellCell.backgroundColor = [UIColor whiteColor];
                [tableView setBackgroundColor:[UIColor whiteColor]];
                break;
            }

        return fontsettableviewcellCell;
        }
    else
        {
        static NSString *nsstringDetailCellIdentifier = @"Detail";
        
        UITableViewCell *uitableviewcellCell = [tableView dequeueReusableCellWithIdentifier:nsstringDetailCellIdentifier];
        if (uitableviewcellCell == nil)
            uitableviewcellCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nsstringDetailCellIdentifier];
        
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [uitableviewcellCell.textLabel setFont:[UIFont fontWithName:@"DFWaWaTC-W5" size:25.0]];

        switch(nsuintegerDetailViewSelect)
            {
            case 0:
                {
                NSUInteger nsuintegerRow = [indexPath row];
                NSUInteger nsuintegerOldRow = [nsindexpathFontSizeLastIndexPath row];
                uitableviewcellCell.textLabel.text = nsarrayFontSizes[nsuintegerRow];
                uitableviewcellCell.accessoryType = (nsuintegerRow == nsuintegerOldRow)?UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                }
                break;
            case 1:
                {
                NSUInteger nsuintegerRow = [indexPath row];
                NSUInteger nsuintegerOldRow = [nsindexpathFontColorLastIndexPath row];
                uitableviewcellCell.textLabel.text = nsarrayFontColors[nsuintegerRow];
                uitableviewcellCell.accessoryType = (nsuintegerRow == nsuintegerOldRow)?UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                }
                break;
            case 2:
                {
                NSUInteger nsuintegerRow = [indexPath row];
                NSUInteger nsuintegerOldRow = [nsindexpathFontTypeLastIndexPath row];
                uitableviewcellCell.textLabel.text = nsarrayFontTypes[nsuintegerRow];
                uitableviewcellCell.accessoryType = (nsuintegerRow == nsuintegerOldRow)?UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                }
                break;
            case 3:
                {
                NSUInteger nsuintegerRow = [indexPath row];
                NSUInteger nsuintegerOldRow = _nsuintegerTheme;
                uitableviewcellCell.textLabel.text = _nsarrayThemes[nsuintegerRow];
                uitableviewcellCell.accessoryType = (nsuintegerRow == nsuintegerOldRow)?UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                }
                break;
            }
        [tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];

        switch (_nsuintegerTheme)
            {
            case 0:
                uitableviewcellCell.backgroundColor = [UIColor blackColor];
                [uitableviewcellCell.textLabel setTextColor:[UIColor blueColor]];
                
                [tableView setBackgroundColor:[UIColor blackColor]];
                break;

            case 1:
                uitableviewcellCell.backgroundColor = [UIColor blackColor];
                [uitableviewcellCell.textLabel setTextColor:[UIColor blueColor]];
                
                [tableView setBackgroundColor:[UIColor blackColor]];
                break;

            default:
                uitableviewcellCell.backgroundColor = [UIColor whiteColor];
                [uitableviewcellCell.textLabel setTextColor:[UIColor colorWithRed:0.043 green:0.418 blue:1 alpha:1]];

                [tableView setBackgroundColor:[UIColor whiteColor]];
                break;
            }

        return uitableviewcellCell;
        }
    
}

//-------------------------------------------------------------------------------------------

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:uitableviewFontSetTableView])
        return 60.0;
    else
        return 80.0;
}

//-------------------------------------------------------------------------------------------

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:uitableviewFontSetTableView])
        {
        NSUInteger nsuintegerRow = indexPath.row;
    
        switch(nsuintegerRow)
            {
            case 0:
                {
                nsuintegerDetailViewSelect = 0;
                [uitableviewFontDetailTableView reloadData];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                }
                break;
            case 1:
                {
                nsuintegerDetailViewSelect = 1;
                [uitableviewFontDetailTableView reloadData];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                }
                break;
            case 2:
                {
                nsuintegerDetailViewSelect = 2;
                [uitableviewFontDetailTableView reloadData];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                }
                break;
            case 3:
                {
                nsuintegerDetailViewSelect = 3;
                [uitableviewFontDetailTableView reloadData];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                }
            }
        //Set Theme
        UIImage *uiimageBackground = nil;

        switch (_nsuintegerTheme)
            {
            case 0:
                uiimageBackground = [UIImage imageNamed:@"MAINPAGE_BACKGROUND.png"];
                [_uiimageBackground setImage:uiimageBackground];
//                [self.view setBackgroundColor:[UIColor colorWithPatternImage:uiimageBackground]];
                break;

            case 1:
                uiimageBackground = [UIImage imageNamed:@"MAINPAGE_BACKGROUND_White.png"];
                [_uiimageBackground setImage:uiimageBackground];
                break;

            default:
                [_uiimageBackground setImage:nil];
                self.view.backgroundColor = [UIColor colorWithWhite:0.4 alpha:0.5];
                break;
            }
        uitableviewFontDetailTableView.hidden = NO;
        }
    else
        {
        NSArray *nsarrayPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *nsstringDocumentDirectory = [nsarrayPath objectAtIndex:0];
        NSString *nsstringPath = [nsstringDocumentDirectory stringByAppendingPathComponent:@"config.plist"];
        NSMutableDictionary *nsmutabledictionaryRoot = [[NSMutableDictionary alloc] initWithContentsOfFile:nsstringPath];
        
        switch(nsuintegerDetailViewSelect)
            {
            case 0:
                {
                NSUInteger nsuintegerNewRow = [indexPath row];
                NSUInteger nsuintegerOldRow = [nsindexpathFontSizeLastIndexPath row];
                
                if (nsuintegerNewRow != nsuintegerOldRow)
                    {
                    UITableViewCell *uitableviewcellNewCell = [tableView cellForRowAtIndexPath:indexPath];
                    
                    uitableviewcellNewCell.accessoryType = UITableViewCellAccessoryCheckmark;
                    
                    UITableViewCell *uitableviewcellOldCell = [tableView cellForRowAtIndexPath:nsindexpathFontSizeLastIndexPath];
                    uitableviewcellOldCell.accessoryType = UITableViewCellAccessoryNone;
                    
                    nsindexpathFontSizeLastIndexPath = indexPath;
                    switch(nsuintegerNewRow)
                        {
                        case 0:
                            {
                            nsstringFontSizeValue = @"小";
                            nsuintegerFontSizeValue_UInt = 17;
                            
                            NSDictionary *nsdictionaryNewData = [[NSDictionary alloc] initWithObjectsAndKeys:@"文字設定",@"name",@"小",@"attribute", nil];
                            [nsmutablearrayFontSettings setObject:nsdictionaryNewData atIndexedSubscript:0];
                            }
                            break;
                        case 1:
                            {
                            nsstringFontSizeValue = @"中";
                            nsuintegerFontSizeValue_UInt = 25;

                            NSDictionary *nsdictionaryNewData = [[NSDictionary alloc] initWithObjectsAndKeys:@"文字設定",@"name",@"中",@"attribute", nil];
                            [nsmutablearrayFontSettings setObject:nsdictionaryNewData atIndexedSubscript:0];
                            }
                            break;
                        case 2:
                            {
                            nsstringFontSizeValue = @"大";
                            nsuintegerFontSizeValue_UInt = 35;

                            NSDictionary *nsdictionaryNewData = [[NSDictionary alloc] initWithObjectsAndKeys:@"文字設定",@"name",@"大",@"attribute", nil];
                            [nsmutablearrayFontSettings setObject:nsdictionaryNewData atIndexedSubscript:0];
                            }
                            break;
                        }
                    [uitextviewFontDemoView setFont:[UIFont systemFontOfSize:nsuintegerFontSizeValue_UInt]];
                    
                    [nsmutabledictionaryRoot setValue:nsstringFontSizeValue forKey:@"FontSizeValue"];
                    [nsmutabledictionaryRoot setValue:[NSNumber numberWithUnsignedInteger:nsuintegerFontSizeValue_UInt] forKey:@"FontSizeValue_Int"];
                    }
                
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                
                [uitableviewFontSetTableView reloadData];
                }
                break;
            case 1:
                {
                NSUInteger nsuintegerNewRow = [indexPath row];
                NSUInteger nsuintegerOldRow = [nsindexpathFontColorLastIndexPath row];
                
                if (nsuintegerNewRow != nsuintegerOldRow)
                    {
                    UITableViewCell *uitableviewcellNewCell = [tableView cellForRowAtIndexPath:indexPath];
                    
                    uitableviewcellNewCell.accessoryType = UITableViewCellAccessoryCheckmark;
                    
                    UITableViewCell *uitableviewcellOldCell = [tableView cellForRowAtIndexPath:nsindexpathFontColorLastIndexPath];
                    uitableviewcellOldCell.accessoryType = UITableViewCellAccessoryNone;
                    
                    nsindexpathFontColorLastIndexPath = indexPath;
                    switch(nsuintegerNewRow)
                        {
                        case 0:
                            {
                            nsstringFontColorValue = @"白";
                            [uitextviewFontDemoView setTextColor:[UIColor whiteColor]];
                            
                            NSDictionary *nsdictionaryNewData = [[NSDictionary alloc] initWithObjectsAndKeys:@"文字顏色",@"name",@"白",@"attribute", nil];
                            [nsmutablearrayFontSettings setObject:nsdictionaryNewData atIndexedSubscript:1];
                            }
                            break;
                        case 1:
                            {
                            nsstringFontColorValue = @"紅";
                            [uitextviewFontDemoView setTextColor:[UIColor redColor]];
                            
                            NSDictionary *nsdictionaryNewData = [[NSDictionary alloc] initWithObjectsAndKeys:@"文字顏色",@"name",@"紅",@"attribute", nil];
                            [nsmutablearrayFontSettings setObject:nsdictionaryNewData atIndexedSubscript:1];
                            }
                            break;
                        case 2:
                            {
                            nsstringFontColorValue = @"藍";
                            [uitextviewFontDemoView setTextColor:[UIColor cyanColor]];
                            
                            NSDictionary *nsdictionaryNewData = [[NSDictionary alloc] initWithObjectsAndKeys:@"文字顏色",@"name",@"藍",@"attribute", nil];
                            [nsmutablearrayFontSettings setObject:nsdictionaryNewData atIndexedSubscript:1];
                            }
                            break;
                        }

                    [nsmutabledictionaryRoot setValue:nsstringFontColorValue forKey:@"FontColorValue"];
                    [nsmutabledictionaryRoot setValue:[NSNumber numberWithUnsignedInteger:nsuintegerNewRow] forKey:@"FontColorValue_Int"];

                    }
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                
                [uitableviewFontSetTableView reloadData];
                }
                break;
            case 2:
                {
                NSUInteger nsuintegerNewRow = [indexPath row];
                NSUInteger nsuintegerOldRow = [nsindexpathFontTypeLastIndexPath row];
                
                if (nsuintegerNewRow != nsuintegerOldRow)
                    {
                    UITableViewCell *uitableviewcellNewCell = [tableView cellForRowAtIndexPath:indexPath];
                    
                    uitableviewcellNewCell.accessoryType = UITableViewCellAccessoryCheckmark;
                    
                    UITableViewCell *uitableviewcellOldCell = [tableView cellForRowAtIndexPath:nsindexpathFontTypeLastIndexPath];
                    uitableviewcellOldCell.accessoryType = UITableViewCellAccessoryNone;
                    
                    nsindexpathFontTypeLastIndexPath = indexPath;
                    switch(nsuintegerNewRow)
                        {
                        case 0:
                            {
                            nsstringFontTypeValue = @"娃娃體";
                            [uitextviewFontDemoView setFont:[UIFont fontWithName:@"DFWaWaTC-W5" size:nsuintegerFontSizeValue_UInt]];
                            
                            NSDictionary *nsdictionaryNewData = [[NSDictionary alloc] initWithObjectsAndKeys:@"文字字型",@"name",@"娃娃體",@"attribute", nil];
                            [nsmutablearrayFontSettings setObject:nsdictionaryNewData atIndexedSubscript:2];
                            }
                            break;
                        case 1:
                            {
                            nsstringFontTypeValue = @"翩翩體";
                            [uitextviewFontDemoView setFont:[UIFont fontWithName:@"HanziPenTC-W5" size:nsuintegerFontSizeValue_UInt]];
                            
                            NSDictionary *nsdictionaryNewData = [[NSDictionary alloc] initWithObjectsAndKeys:@"文字字型",@"name",@"翩翩體",@"attribute", nil];
                            [nsmutablearrayFontSettings setObject:nsdictionaryNewData atIndexedSubscript:2];
                            }
                            break;
                        case 2:
                            {
                            nsstringFontTypeValue = @"魏碑";
                            [uitextviewFontDemoView setFont:[UIFont fontWithName:@"Weibei-TC-Bold" size:nsuintegerFontSizeValue_UInt]];
                            
                            NSDictionary *nsdictionaryNewData = [[NSDictionary alloc] initWithObjectsAndKeys:@"文字字型",@"name",@"魏碑",@"attribute", nil];
                            [nsmutablearrayFontSettings setObject:nsdictionaryNewData atIndexedSubscript:2];
                            }
                            break;
                        }

                    [nsmutabledictionaryRoot setValue:nsstringFontTypeValue forKey:@"FontTypeValue"];
                    [nsmutabledictionaryRoot setValue:[NSNumber numberWithUnsignedInteger:nsuintegerNewRow] forKey:@"FontTypeValue_Int"];
                    
                    }
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                
                [uitableviewFontSetTableView reloadData];
                }
                break;
            case 3:
                {
                NSUInteger nsuintegerNewRow = [indexPath row];
                NSUInteger nsuintegerOldRow = _nsuintegerTheme;
                
                if (nsuintegerNewRow != nsuintegerOldRow)
                    {
                    UITableViewCell *uitableviewcellNewCell = [tableView cellForRowAtIndexPath:indexPath];
                    
                    uitableviewcellNewCell.accessoryType = UITableViewCellAccessoryCheckmark;
                    
                    UITableViewCell *uitableviewcellOldCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_nsuintegerTheme inSection:0]];
                    uitableviewcellOldCell.accessoryType = UITableViewCellAccessoryNone;
                    
                    _nsuintegerTheme = nsuintegerNewRow;

                    UIImage *uiimageUpperBar = nil;
                    UIImage *uiimageBottomBar = nil;

                    switch(nsuintegerNewRow)
                        {
                        case 0:
                            {
//                            [uitextviewFontDemoView setBackgroundColor:[UIColor clearColor]];
                            uiimageBottomBar = [UIImage imageNamed:@"BOTTOM_BAR.png"];
                            uiimageUpperBar = [UIImage imageNamed:@"UPPER_BAR.png"];
                            
                            self.navigationController.navigationBar.barTintColor = [UIColor colorWithPatternImage:uiimageUpperBar];
                            [self.navigationController.toolbar setBarTintColor:[UIColor colorWithPatternImage:uiimageBottomBar]];
                            
                            [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:0.294 green:0.686 blue:0.49 alpha:1]];

                            [self.navigationController.navigationBar
                                setTitleTextAttributes:@
                                    {
                                    NSFontAttributeName:[UIFont fontWithName:@"DFWaWaTC-W5" size:20.0],
                                    NSForegroundColorAttributeName:[UIColor whiteColor]
                                    }];
                            
                            NSDictionary *nsdictionaryNewData = [[NSDictionary alloc] initWithObjectsAndKeys:@"主題",@"name",@"紫黑",@"attribute", nil];
                            [nsmutablearrayFontSettings setObject:nsdictionaryNewData atIndexedSubscript:3];
                            }
                            break;
                            
                        case 1:
                            {
//                            [uitextviewFontDemoView setBackgroundColor:[UIColor blackColor]];
                            uiimageBottomBar = [UIImage imageNamed:@"BOTTOM_BAR_White.png"];
                            uiimageUpperBar = [UIImage imageNamed:@"UPPER_BAR_White.png"];
                            
                            self.navigationController.navigationBar.barTintColor = [UIColor colorWithPatternImage:uiimageUpperBar];
                            [self.navigationController.toolbar setBarTintColor:[UIColor colorWithPatternImage:uiimageBottomBar]];
                            
                            [self.navigationController.navigationBar setTintColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:1]];

                            [self.navigationController.navigationBar
                                setTitleTextAttributes:@
                                    {
                                    NSFontAttributeName:[UIFont fontWithName:@"DFWaWaTC-W5" size:20.0],
                                    NSForegroundColorAttributeName:[UIColor colorWithRed:0.294 green:1 blue:1 alpha:1]
                                    }];
                                
                            NSDictionary *nsdictionaryNewData = [[NSDictionary alloc] initWithObjectsAndKeys:@"主題",@"name",@"紫白",@"attribute", nil];
                            [nsmutablearrayFontSettings setObject:nsdictionaryNewData atIndexedSubscript:3];
                            }
                            break;
                            
                        default:
                            {
//                            [uitextviewFontDemoView setBackgroundColor:[UIColor blackColor]];
                            self.navigationController.navigationBar.barTintColor = nil;
                            [self.navigationController.toolbar setBarTintColor:nil];
                            
                            [self.navigationController.navigationBar setTintColor:nil];

                            [self.navigationController.navigationBar
                                setTitleTextAttributes:@
                                    {
                                    NSFontAttributeName:[UIFont fontWithName:@"DFWaWaTC-W5" size:20.0],
                                    }];

                            NSDictionary *nsdictionaryNewData = [[NSDictionary alloc] initWithObjectsAndKeys:@"主題",@"name",@"無",@"attribute", nil];
                            [nsmutablearrayFontSettings setObject:nsdictionaryNewData atIndexedSubscript:3];
                            }
                            break;
                        }

                    [nsmutabledictionaryRoot setValue:[NSNumber numberWithUnsignedInteger:_nsuintegerTheme] forKey:@"Theme"];

                    [self.delegate setViewBackgroundWithTheme:_nsuintegerTheme];
                    }
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                
                [uitableviewFontSetTableView reloadData];
                }
                break;
            }
        //Set Theme
        UIImage *uiimageBackground = nil;
        switch (_nsuintegerTheme)
            {
            case 0:
                uiimageBackground = [UIImage imageNamed:@"MAINPAGE_BACKGROUND.png"];
                _uiimageBackground.image = uiimageBackground;
                break;
                
            case 1:
                uiimageBackground = [UIImage imageNamed:@"MAINPAGE_BACKGROUND_White.png"];
                _uiimageBackground.image = uiimageBackground;
                break;
                
            default:
                [_uiimageBackground setImage:nil];
                self.view.backgroundColor = [UIColor colorWithRed:0.2 green:0.7 blue:0.7 alpha:1.0];
                break;
            }
        tableView.hidden = YES;
        
        [nsmutabledictionaryRoot writeToFile:nsstringPath atomically:YES];
        }
    
    [self.delegate fontSettingPassToViewController:nsstringFontSizeValue ColorSet:nsstringFontColorValue TypeSet:nsstringFontTypeValue FontSizeLast:nsindexpathFontSizeLastIndexPath FontColorLast:nsindexpathFontColorLastIndexPath FontTypeLast:nsindexpathFontTypeLastIndexPath];
}

//------------------------------------------------------------------------------------------

#pragma mark- Background Touch Method
- (IBAction)backgroundTouch:(id)sender
{
    if (uitableviewFontDetailTableView.hidden)
        return;
        
    //Set Theme
    UIImage *uiimageBackground = nil;

    switch (_nsuintegerTheme)
        {
        case 0:
            [uitextviewFontDemoView setBackgroundColor:[UIColor clearColor]];
            uiimageBackground = [UIImage imageNamed:@"MAINPAGE_BACKGROUND.png"];
            [self.view setBackgroundColor:[UIColor colorWithPatternImage:uiimageBackground]];
            break;
            
        case 1:
            [uitextviewFontDemoView setBackgroundColor:[UIColor blackColor]];
            uiimageBackground = [UIImage imageNamed:@"MAINPAGE_BACKGROUND_White.png"];
            [self.view setBackgroundColor:[UIColor colorWithPatternImage:uiimageBackground]];
            break;
            
        default:
            [uitextviewFontDemoView setBackgroundColor:[UIColor blackColor]];
            self.view.backgroundColor = [UIColor colorWithRed:0.2 green:0.7 blue:0.7 alpha:1.0];
            break;
        }
    uitableviewFontDetailTableView.hidden = YES;

}

//-------------------------------------------------------------------------------------------

@end
