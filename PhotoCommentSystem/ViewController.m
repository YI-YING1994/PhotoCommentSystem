//
//  ViewController.m
//  PhotoCommentSystem
//
//  Created by CSIE on 2015/9/20.
//  Copyright © 2015年 CSIE. All rights reserved.
//

#import "ViewController.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "FontSetViewController.h"
#import "CreateToAlbumTableViewController.h"

//---------------------------------------------------------------------------------------

//限制 註解字數、密碼字數
#define commentTextLimit 500
#define passwardTextLimit 33

//全域變數：用來計算要儲存的資料有多少位元組
uint uintDataSize;

//用來寫入資料的結構
typedef struct structHeader
    {
    Byte byteMarker[4];
    Byte byteDataSize[2];
    }Header;

//---------------------------------------------------------------------------------------

//金鑰陣列、金鑰實際長度
Byte key[16 * (14 + 1)];
int iKeyLen = 32;

//金鑰轉換表
Byte AES_Sbox[] =
        {
        99,124,119,123,242,107,111,197,48,1,103,43,254,215,171,
        118,202,130,201,125,250,89,71,240,173,212,162,175,156,
        164,114,192,183,253,147,38,54,63,247,204,52,165,229,241,
        113,216,49,21,4,199,35,195,24,150,5,154,7,18,128,226,235,
        39,178,117,9,131,44,26,27,110,90,160,82,59,214,179,41,227,
        47,132,83,209,0,237,32,252,177,91,106,203,190,57,74,76,88,
        207,208,239,170,251,67,77,51,133,69,249,2,127,80,60,159,168,
        81,163,64,143,146,157,56,245,188,182,218,33,16,255,243,210,205,
        12,19,236,95,151,68,23,196,167,126,61,100,93,25,115,96,129,79,
        220,34,42,144,136,70,238,184,20,222,94,11,219,224,50,58,10,73,6,
        36,92,194,211,172,98,145,149,228,121,231,200,55,109,141,213,78,169,
        108,86,244,234,101,122,174,8,186,120,37,46,28,166,180,198,232,221,
        116,31,75,189,139,138,112,62,181,102,72,3,246,14,97,53,87,185,134,
        193,29,158,225,248,152,17,105,217,142,148,155,30,135,233,206,85,40,
        223,140,161,137,13,191,230,66,104,65,153,45,15,176,84,187,22
        };

//---------------------------------------------------------------------------------------

Byte AES_ShiftRowTab[] = {0,5,10,15,4,9,14,3,8,13,2,7,12,1,6,11};

Byte AES_Sbox_Inv[256];
Byte AES_ShiftRowTab_Inv[16];
Byte AES_xtime[256];

//---------------------------------------------------------------------------------------

//用sbox表替換明文
void AES_SubBytes(Byte state[], Byte sbox[])
{
    int i;
    for(i = 0; i < 16; i++)
        state[i] = sbox[state[i]];
}

//---------------------------------------------------------------------------------------

//將明文跟子金鑰做XOR運算
void AES_AddRoundKey(Byte state[], Byte rkey[])
{
    int i;
    for(i = 0; i < 16; i++)
        state[i] ^= rkey[i];
}

//---------------------------------------------------------------------------------------

//對明文做列位移
void AES_ShiftRows(Byte state[], Byte shifttab[])
{
    Byte h[16];
    memcpy(h, state, 16);
    int i;
    for(i = 0; i < 16; i++)
        state[i] = h[shifttab[i]];
}

//---------------------------------------------------------------------------------------

//將明文乘以一個多項式
void AES_MixColumns(Byte state[])
{
    int i;
    for(i = 0; i < 16; i += 4)
        {
        Byte s0 = state[i + 0], s1 = state[i + 1];
        Byte s2 = state[i + 2], s3 = state[i + 3];
        Byte h = s0 ^ s1 ^ s2 ^ s3;
        state[i + 0] ^= h ^ AES_xtime[s0 ^ s1];
        state[i + 1] ^= h ^ AES_xtime[s1 ^ s2];
        state[i + 2] ^= h ^ AES_xtime[s2 ^ s3];
        state[i + 3] ^= h ^ AES_xtime[s3 ^ s0];
        }
}

//---------------------------------------------------------------------------------------

//將密文反推回明文
void AES_MixColumns_Inv(Byte state[])
{
    int i;
    for(i = 0; i < 16; i += 4)
        {
        Byte s0 = state[i + 0], s1 = state[i + 1];
        Byte s2 = state[i + 2], s3 = state[i + 3];
        Byte h = s0 ^ s1 ^ s2 ^ s3;
        Byte xh = AES_xtime[h];
        Byte h1 = AES_xtime[AES_xtime[xh ^ s0 ^ s2]] ^ h;
        Byte h2 = AES_xtime[AES_xtime[xh ^ s1 ^ s3]] ^ h;
        state[i + 0] ^= h1 ^ AES_xtime[s0 ^ s1];
        state[i + 1] ^= h2 ^ AES_xtime[s1 ^ s2];
        state[i + 2] ^= h1 ^ AES_xtime[s2 ^ s3];
        state[i + 3] ^= h2 ^ AES_xtime[s3 ^ s0];
        }
}

//---------------------------------------------------------------------------------------

//初始化
void AES_Init()
{
    int i;
    
    for(i = 0; i < 256; i++)
        AES_Sbox_Inv[AES_Sbox[i]] = i;
   
    for(i = 0; i < 16; i++)
        AES_ShiftRowTab_Inv[AES_ShiftRowTab[i]] = i;
 
    for(i = 0; i < 128; i++)
        {
        AES_xtime[i] = i << 1;
        AES_xtime[128 + i] = (i << 1) ^ 0x1b;
        }
}

//---------------------------------------------------------------------------------------

//產生子金鑰
int AES_ExpandKey(Byte key[], int keyLen)
{
    int kl = keyLen, ks, Rcon = 1, i, j;
    Byte temp[4], temp2[4];
    switch (kl)
        {
        case 16: ks = 16 * (10 + 1); break;
        case 24: ks = 16 * (12 + 1); break;
        case 32: ks = 16 * (14 + 1); break;
        default:
            printf("AES_ExpandKey: Only key lengths of 16, 24 or 32 bytes allowed!");
        }
    for(i = kl; i < ks; i += 4)
        {
        memcpy(temp, &key[i-4], 4);
        if (i % kl == 0)
            {
            temp2[0] = AES_Sbox[temp[1]] ^ Rcon;
            temp2[1] = AES_Sbox[temp[2]];
            temp2[2] = AES_Sbox[temp[3]];
            temp2[3] = AES_Sbox[temp[0]];
            memcpy(temp, temp2, 4);
            if ((Rcon <<= 1) >= 256)
                Rcon ^= 0x11b;
            }
        else if ((kl > 24) && (i % kl == 16))
            {
            temp2[0] = AES_Sbox[temp[0]];
            temp2[1] = AES_Sbox[temp[1]];
            temp2[2] = AES_Sbox[temp[2]];
            temp2[3] = AES_Sbox[temp[3]];
            memcpy(temp, temp2, 4);
            }
        for(j = 0; j < 4; j++)
            key[i + j] = key[i + j - kl] ^ temp[j];
        }
    return ks;
}

//---------------------------------------------------------------------------------------

//實際加密
void AES_Encrypt(Byte block[], Byte key[], int keyLen)
{
    int l = keyLen, i;
  //printBytes(block, 16);
    AES_AddRoundKey(block, &key[0]);
    for(i = 16; i < l - 16; i += 16)
        {
        AES_SubBytes(block, AES_Sbox);
        AES_ShiftRows(block, AES_ShiftRowTab);
        AES_MixColumns(block);
        AES_AddRoundKey(block, &key[i]);
        }
    AES_SubBytes(block, AES_Sbox);
    AES_ShiftRows(block, AES_ShiftRowTab);
    AES_AddRoundKey(block, &key[i]);
}

//---------------------------------------------------------------------------------------

//實際解密
void AES_Decrypt(Byte block[], Byte key[], int keyLen)
{
    int l = keyLen, i;
    AES_AddRoundKey(block, &key[l - 16]);
    AES_ShiftRows(block, AES_ShiftRowTab_Inv);
    AES_SubBytes(block, AES_Sbox_Inv);
    for(i = l - 32; i >= 16; i -= 16)
        {
        AES_AddRoundKey(block, &key[i]);
        AES_MixColumns_Inv(block);
        AES_ShiftRows(block, AES_ShiftRowTab_Inv);
        AES_SubBytes(block, AES_Sbox_Inv);
        }
    AES_AddRoundKey(block, &key[0]);
}

//----------------------------------------------------------------------------------------

@interface ViewController () <PHPhotoLibraryChangeObserver>

//更新圖片
- (void)updateDisplay;

//選擇是否要保留原圖
- (void)choseWhetherSaveOriginalImage;

//選擇是否要在Photo Comment建立連結
- (void)choseWhereToSave;

//Font Setting
- (void)commentShowTextViewFontSet;

//判斷是新增照片還是加註解
@property BOOL boolAddToOrComment;

@end

@implementation ViewController

//----------------------------------------------------------------------------------------

//Display image
@synthesize uiimageviewImageView,nsdataGlobalData;

//----------------------------------------------------------------------------------------

//font set pass
@synthesize nsstringFontSizeValue,nsstringFontColorValue;
@synthesize nsstringFontTypeValue,nsuintegerFontSizeValue_ViewControll;
@synthesize nsindexpathFontSizeLastIndexPath,nsindexpathFontColorLastIndexPath;
@synthesize nsindexpathFontTypeLastIndexPath;

//----------------------------------------------------------------------------------------

//tool bar button
@synthesize uibarbuttonitemEditCommentButton,uibarbuttonitemEditFontButton;
@synthesize uibarbuttonitemTrashButton;

//----------------------------------------------------------------------------------------

//edit comment declares
@synthesize uitextviewCommentShow,uicontrolEditCommentView,uitextviewCommentTextView,uitextfieldPasswardTextField;
@synthesize uibarbuttonitemEditCommentCancelButton,uibarbutoonitemEditCommentEnsureButton;
@synthesize uiswitchPasswardSwitch,uintCnt;//,uintDataLen;

//----------------------------------------------------------------------------------------

//encode declares
@synthesize uicontrolEncodeView,uibarbuttonitemEncodeCancelButton;
@synthesize uibarbuttonitemEncodeSureButton,uitextfieldEncodeTextField,uilabelDecodeWrongAlert,boolHaveEncoded;

//----------------------------------------------------------------------------------------

#pragma mark- ViewLoad & Memory Controll

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
        nsuintegerFontSizeValue_ViewControll = [[nsmutabledictionaryRoot objectForKey:@"FontSizeValue_Int"] unsignedIntegerValue];
        switch (nsuintegerFontSizeValue_ViewControll)
            {
            case 17:nsindexpathFontSizeLastIndexPath = [NSIndexPath indexPathForRow:0 inSection:1];
                break;
            case 25:nsindexpathFontSizeLastIndexPath = [NSIndexPath indexPathForRow:1 inSection:1];
                break;
            case 35:nsindexpathFontSizeLastIndexPath = [NSIndexPath indexPathForRow:2 inSection:1];
                break;
            }
            
        nsstringFontColorValue = [nsmutabledictionaryRoot objectForKey:@"FontColorValue"];
        _nsuintegerFontColorValue = [[nsmutabledictionaryRoot objectForKey:@"FontColorValue_Int"] unsignedIntegerValue];
        nsindexpathFontColorLastIndexPath = [NSIndexPath indexPathForRow:_nsuintegerFontColorValue inSection:1];
            
        nsstringFontTypeValue = [nsmutabledictionaryRoot objectForKey:@"FontTypeValue"];
        _nsuintegerFontTypeValue = [[nsmutabledictionaryRoot objectForKey:@"FontTypeValue_Int"] unsignedIntegerValue];
        nsindexpathFontTypeLastIndexPath = [NSIndexPath indexPathForRow:_nsuintegerFontTypeValue inSection:1];
        
        [self commentShowTextViewFontSet];
        }
        
    //設定文字欄位的委派
    uitextviewCommentTextView.delegate = self;
    uitextfieldPasswardTextField.delegate = self;
    uitextfieldEncodeTextField.delegate = self;
    
    //設定uitextviewCommentShow Touch動作
    UITapGestureRecognizer *uitapgesturerecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(commentShowTouch)];
    [uitapgesturerecognizer setNumberOfTapsRequired:1];
    [self.uitextviewCommentShow addGestureRecognizer:uitapgesturerecognizer];

    //設定button字型
    [uibarbuttonitemEditCommentButton setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"DFWaWaTC-W5" size:15.0]} forState:UIControlStateNormal];
    [uibarbuttonitemEditFontButton setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"DFWaWaTC-W5" size:15.0]} forState:UIControlStateNormal];

    //新增Bar Button用來開啟選擇要新增到哪個相簿的畫面
    UIBarButtonItem *uibarbuttonItemCreate = [[UIBarButtonItem alloc] initWithTitle:@"新增到" style:UIBarButtonItemStylePlain target:self action:@selector(createToWhere:)];

    //set uitoolbarbuttonitem text color
    switch (_nsuintegerTheme)
        {
        case 0:
            [uibarbuttonitemEditCommentButton setTintColor:[UIColor colorWithRed:0.294 green:0.686 blue:0.49 alpha:1]];

            [uibarbuttonitemEditFontButton setTintColor:[UIColor colorWithRed:0.294 green:0.686 blue:0.49 alpha:1]];

            [uibarbuttonitemTrashButton setTintColor:[UIColor colorWithRed:0.294 green:0.686 blue:0.49 alpha:1]];
            break;

        case 1:
            [uibarbuttonitemEditCommentButton setTintColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:1]];

            [uibarbuttonitemEditFontButton setTintColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:1]];

            [uibarbuttonitemTrashButton setTintColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:1]];
            break;

        default:
            [uibarbuttonitemEditCommentButton setTintColor:nil];

            [uibarbuttonitemEditFontButton setTintColor:nil];

            [uibarbuttonitemTrashButton setTintColor:nil];
            break;
        }

    //設定Bar button字型
    [uibarbuttonItemCreate setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"DFWaWaTC-W5" size:17.0]} forState:UIControlStateNormal];
    [self.navigationItem.backBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"DFWaWaTC-W5" size:17.0]} forState:UIControlStateNormal];

    self.navigationItem.rightBarButtonItem = uibarbuttonItemCreate;
    
    //初始化AES所會用到的陣列
    AES_Init();

    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    
}

//----------------------------------------------------------------------------------------

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    Byte *byteTemp = (Byte *)[self.nsdataGlobalData bytes];

    uintDataSize = 0;
            
    for(uintCnt = 0; uintCnt < nsdataGlobalData.length; uintCnt+=2)
        {
        if (byteTemp[uintCnt]==0xFF && byteTemp[uintCnt+1]==0xE6)
            {
            uintCnt +=2;
            uintDataSize = byteTemp[uintCnt] * 0x100 + byteTemp[uintCnt+1];

            break;
            }
        }
                        
    NSLog(@"datasize: %d, uintCnt: %d", uintDataSize, uintCnt);
                        
    if (uintCnt < nsdataGlobalData.length)
        {
        NSString *nsstringTemp = [[NSString alloc] initWithData:[self.nsdataGlobalData subdataWithRange:NSMakeRange(uintCnt + 2, uintDataSize - 2)] encoding:NSUTF8StringEncoding];

        if (nsstringTemp != nil)
            {
            uitextviewCommentShow.text = nsstringTemp;
            uitextviewCommentShow.hidden = NO;
                                
            [self commentShowTextViewFontSet];
            }
        else
            {
            self.boolHaveEncoded = YES;
            uitextviewCommentShow.text = @"";
            uitextviewCommentShow.hidden = YES;
            }
        }
    else
        {
        uitextviewCommentShow.text = @"";
        uitextviewCommentShow.hidden = YES;
        }
}

//----------------------------------------------------------------------------------------

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.view layoutIfNeeded];

    //Set Navigationbar Title
    self.navigationItem.title = _nsstringAlbumName;

    [self updateDisplay];
}

//----------------------------------------------------------------------------------------

//- (void)viewWillLayoutSubviews
//{
//    [super viewWillLayoutSubviews];
//    
//    if (!CGSizeEqualToSize(self.uiimageviewImageView.bounds.size, self.cgsizeLastImageViewSize))
//        {
//        [self updateDisplay];
//        }
//}

//----------------------------------------------------------------------------------------

- (void)commentShowTouch
{
    self.uitextviewCommentShow.hidden = YES;
}

//----------------------------------------------------------------------------------------

- (void)updateDisplay
{
    self.cgsizeLastImageViewSize = self.uiimageviewImageView.bounds.size;
    
    CGFloat cgfloatScale = [UIScreen mainScreen].scale;
    CGSize cgsizeTargetSize = CGSizeMake(CGRectGetWidth(self.uiimageviewImageView.bounds) * cgfloatScale, CGRectGetHeight(self.uiimageviewImageView.bounds) * cgfloatScale);

    if (self.phassetAsset)
        {
        [[PHImageManager defaultManager] requestImageDataForAsset:self.phassetAsset options:nil resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info)
            {
            if (imageData)
                nsdataGlobalData = imageData;
            }];
        [[PHImageManager defaultManager] requestImageForAsset:self.phassetAsset targetSize:cgsizeTargetSize contentMode:PHImageContentModeAspectFit options:nil resultHandler:^(UIImage *result, NSDictionary *info)
                {
                if (result)
                    {
                    self.uiimageviewImageView.image = result;
                    }
                }];
        }
    else
        {
        __block UIImage *uiimageImage;
        
        dispatch_group_t group = dispatch_group_create();
        
        dispatch_group_async(group, dispatch_get_global_queue(0, 0),^
            {
            nsdataGlobalData = [NSData dataWithContentsOfFile:[self.nsstringAlbumPath stringByAppendingPathComponent:self.nsstringAsset]];
            uiimageImage = [UIImage imageWithData:nsdataGlobalData];
            });
            
        dispatch_group_notify(group, dispatch_get_global_queue(0, 0),^
            {
            dispatch_async(dispatch_get_main_queue(),^
                {
                uiimageviewImageView.image = uiimageImage;
                });
    
            
             });
        }
}

//----------------------------------------------------------------------------------------

- (void)dealloc
{
    //Display image
    self.uiimageviewImageView = nil;
    self.nsdataGlobalData = nil;

    //Asset and Album
    _phassetAsset = nil;
    _nsstringAsset = nil;
    _nsstringAlbumPath = nil;
    _nsstringAlbumName = nil;

    //Font set pass
    self.nsstringFontSizeValue = nil;
    self.nsstringFontColorValue = nil;
    self.nsstringFontTypeValue = nil;
    self.nsindexpathFontSizeLastIndexPath = nil;
    self.nsindexpathFontColorLastIndexPath = nil;
    self.nsindexpathFontTypeLastIndexPath = nil;

    //Edit comment
    self.uitextviewCommentShow = nil;
    self.uicontrolEditCommentView = nil;
    self.uitextviewCommentTextView = nil;
    self.uitextviewEncryptTextShow = nil;
    self.uitextfieldPasswardTextField = nil;
    self.uicontrolEditCommentView = nil;
    
    //Decode
    self.uicontrolEncodeView = nil;
    self.uitextfieldEncodeTextField = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:uitextviewCommentTextView];
    
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

//----------------------------------------------------------------------------------------

- (void)CommentViewSwitchTheme
{
    UIImage *uiimageBackground = nil;
    UIImage *uiimageUpperBar = nil;
            
    switch (_nsuintegerTheme)
        {
        case 0:
            uiimageBackground = [UIImage imageNamed:@"COMMEMT_BACKGROUND.png"];
            uiimageUpperBar = [UIImage imageNamed:@"COMMENT_UPPER_BAR.png"];
                
            [uicontrolEditCommentView setBackgroundColor:[UIColor colorWithPatternImage:uiimageBackground]];
            [_uitoolbarEditComment setBarTintColor:[UIColor colorWithPatternImage:uiimageUpperBar]];

            [_uibarbuttonitemNone setTintColor:[UIColor whiteColor]];
            [_uilabelEncode setTextColor:[UIColor whiteColor]];
            [_uilabelKey setTextColor:[UIColor whiteColor]];
            
            [uibarbutoonitemEditCommentEnsureButton setTintColor:[UIColor colorWithRed:0.294 green:1 blue:1 alpha:1]];
            
            [uibarbuttonitemEditCommentCancelButton setTintColor:[UIColor colorWithRed:0.294 green:1 blue:1 alpha:1]];
            
            [uiswitchPasswardSwitch setTintColor:[UIColor colorWithRed:0.294 green:0.568 blue:0.49 alpha:1]];
            [uiswitchPasswardSwitch setOnTintColor:[UIColor colorWithRed:0.294 green:0.568 blue:0.49 alpha:1]];
            [uiswitchPasswardSwitch setThumbTintColor:[UIColor whiteColor]];

//            [uitextviewCommentTextView setBackgroundColor:[UIColor whiteColor]];
//            [uitextfieldPasswardTextField setBackgroundColor:[UIColor whiteColor]];
//            [_uitextviewEncryptTextShow setBackgroundColor:[UIColor whiteColor]];
            break;

        case 1:
            uiimageBackground = [UIImage imageNamed:@"COMMEMT_BACKGROUND_White.png"];
            uiimageUpperBar = [UIImage imageNamed:@"COMMENT_UPPER_BAR_White.png"];
            [uicontrolEditCommentView setBackgroundColor:[UIColor colorWithPatternImage:uiimageBackground]];
            [_uitoolbarEditComment setBarTintColor:[UIColor colorWithPatternImage:uiimageUpperBar]];
            
            [_uibarbuttonitemNone setTintColor:[UIColor blackColor]];
            [_uilabelEncode setTextColor:[UIColor blackColor]];
            [_uilabelKey setTextColor:[UIColor blackColor]];
            
            [uibarbutoonitemEditCommentEnsureButton setTintColor:[UIColor redColor]];
            
            [uibarbuttonitemEditCommentCancelButton setTintColor:[UIColor redColor]];
            
            [uiswitchPasswardSwitch setTintColor:[UIColor colorWithRed:0.412 green:0 blue:1 alpha:1]];
            [uiswitchPasswardSwitch setOnTintColor:[UIColor colorWithRed:0.412 green:0 blue:1 alpha:1]];
            [uiswitchPasswardSwitch setThumbTintColor:[UIColor colorWithRed:0.823 green:0.823 blue:0.823 alpha:1]];
            
//            [uitextviewCommentTextView setBackgroundColor:[UIColor colorWithRed:0.823 green:0.823 blue:0.823 alpha:1]];
//            [uitextfieldPasswardTextField setBackgroundColor:[UIColor colorWithRed:0.823 green:0.823 blue:0.823 alpha:1]];
//            [_uitextviewEncryptTextShow setBackgroundColor:[UIColor colorWithRed:0.823 green:0.823 blue:0.823 alpha:1]];
            break;

        default:
            [uicontrolEditCommentView setBackgroundColor:[UIColor colorWithRed:0.84 green:0.92 blue:1 alpha:1]];
            [_uitoolbarEditComment setBarTintColor:[UIColor colorWithRed:0.41 green:0.5 blue:0.99 alpha:1]];
            
            [_uibarbuttonitemNone setTintColor:[UIColor blackColor]];
            [_uilabelEncode setTextColor:[UIColor blackColor]];
            [_uilabelKey setTextColor:[UIColor blackColor]];

            [uibarbutoonitemEditCommentEnsureButton setTintColor:[UIColor colorWithRed:0.784 green:0.137 blue:0.137 alpha:1]];
            
            [uibarbuttonitemEditCommentCancelButton setTintColor:[UIColor colorWithRed:0.784 green:0.137 blue:0.137 alpha:1]];

            [uiswitchPasswardSwitch setTintColor:[UIColor colorWithRed:0.137 green:0.235 blue:0.784 alpha:1]];
            [uiswitchPasswardSwitch setOnTintColor:nil];
            [uiswitchPasswardSwitch setThumbTintColor:[UIColor whiteColor]];

//            [uitextviewCommentTextView setBackgroundColor:[UIColor whiteColor]];
//            [uitextfieldPasswardTextField setBackgroundColor:[UIColor whiteColor]];
//            [_uitextviewEncryptTextShow setBackgroundColor:[UIColor whiteColor]];
            break;
        }
}

//----------------------------------------------------------------------------------------

#pragma mark- IBAction Methods
//顯示編輯的視窗
- (IBAction)editCommentViewShow:(id)sender
{
    //判斷標頭檔裡是否已經有我們所建立的資料
    if (uintCnt < nsdataGlobalData.length)
        {
        NSString *nsstringTemp = [[NSString alloc] initWithData:[self.nsdataGlobalData subdataWithRange:NSMakeRange(uintCnt + 2, uintDataSize - 2)] encoding:NSUTF8StringEncoding];

        //判斷是否有密碼
        if (nsstringTemp != nil)
            {
            uibarbuttonitemEditCommentButton.enabled = NO;
            uibarbuttonitemEditFontButton.enabled = NO;
            uibarbuttonitemTrashButton.enabled = NO;
            uiswitchPasswardSwitch.on = NO;
            uitextfieldPasswardTextField.hidden = YES;
            uitextfieldPasswardTextField.text = @"";
            self.uitextviewEncryptTextShow.hidden = YES;
            
            //將已有的註解顯示在可以進行編輯的文字框裡
            Byte *byteTemp = (Byte *)[nsdataGlobalData bytes];
            uint uintTextLen = uintCnt + 2;
            while(uintTextLen < uintCnt + uintDataSize)
                {
                if (byteTemp[uintTextLen] == 0x0)
                    break;
                uintTextLen++;
                }
            uintTextLen -= (uintCnt + 2);
            
            uitextviewCommentTextView.text = [[NSString alloc] initWithData:[self.nsdataGlobalData subdataWithRange:NSMakeRange(uintCnt + 2, uintTextLen)] encoding:NSUTF8StringEncoding];
            
            uitextviewCommentTextView.text = nsstringTemp;
            
            [self CommentViewSwitchTheme];
            
            uicontrolEditCommentView.hidden = NO;
            }
        else
            {
            UIAlertController *uialertcontroller = [UIAlertController alertControllerWithTitle:@"警告" message:@"" preferredStyle:UIAlertControllerStyleAlert];
            
            //Change uialertcontroller message font size
            NSMutableAttributedString *nsmutableattributedstring = [[NSMutableAttributedString alloc] initWithString:@"相片已存在一個秘密註解\n請問是否解密或進行覆蓋？"];
            [nsmutableattributedstring addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:16.0] range:[nsmutableattributedstring.string
                rangeOfString:@"相片已存在一個秘密註解\n請問是否解密或進行覆蓋？"]];
            [uialertcontroller setValue:nsmutableattributedstring forKey:@"attributedMessage"];
            
            UIAlertAction *uialertactionOverRide = [UIAlertAction actionWithTitle:@"覆蓋" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
                {
                uitextviewCommentTextView.text = @"";
                uitextfieldPasswardTextField.text = @"";
        
                uibarbuttonitemEditCommentButton.enabled = NO;
                uibarbuttonitemEditFontButton.enabled = NO;
                uibarbuttonitemTrashButton.enabled = NO;
                uiswitchPasswardSwitch.on = NO;
                uitextfieldPasswardTextField.hidden = YES;

                [self CommentViewSwitchTheme];
                    
                uicontrolEditCommentView.hidden = NO;
                }];
                
            UIAlertAction *uialertactionDecode = [UIAlertAction actionWithTitle:@"解密" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
                {
                self.uilabelDecodeWrongAlert.text = @"";
                uitextfieldEncodeTextField.text = @"";
                uibarbuttonitemEditCommentButton.enabled = NO;
                uibarbuttonitemEditFontButton.enabled = NO;
                uibarbuttonitemTrashButton.enabled = NO;
    
                UIImage *uiimageBackground = nil;
                UIImage *uiimageUpperBar = nil;
                UIImage *uiimageTextFieldBackground = nil;
        
                switch (_nsuintegerTheme)
                    {
                    case 0:
                        uiimageBackground = [UIImage imageNamed:@"DECRYPTION_BACKGROUND.png"];
                        uiimageUpperBar = [UIImage imageNamed:@"COMMENT_UPPER_BAR.png"];
                        [uicontrolEncodeView setBackgroundColor:[UIColor colorWithPatternImage:uiimageBackground]];
                        [_uitoolbarEncodeBar setBarTintColor:[UIColor colorWithPatternImage:uiimageUpperBar]];
                        
                        [_uibarbuttonitemDecodeNone setTintColor:[UIColor whiteColor]];
                        [_uilabelDecodeNone setTextColor:[UIColor whiteColor]];

                        [uibarbuttonitemEncodeCancelButton setTintColor:[UIColor colorWithRed:0.294 green:1 blue:1 alpha:1]];

                        [uibarbuttonitemEncodeSureButton setTintColor:[UIColor colorWithRed:0.294 green:1 blue:1 alpha:1]];

                        break;

                    case 1:
                        uiimageBackground = [UIImage imageNamed:@"DECRYPTION_BACKGROUND_White.png"];
                        uiimageUpperBar = [UIImage imageNamed:@"COMMENT_UPPER_BAR_White.png"];
                        uiimageTextFieldBackground = [UIImage imageNamed:@"DECRYPTION_EDITOR_BACKGROUND_White.png"];
                        [uicontrolEncodeView setBackgroundColor:[UIColor colorWithPatternImage:uiimageBackground]];
                        [_uitoolbarEncodeBar setBarTintColor:[UIColor colorWithPatternImage:uiimageUpperBar]];
                        
                        [_uibarbuttonitemDecodeNone setTintColor:[UIColor blackColor]];
                        [_uilabelDecodeNone setTextColor:[UIColor blackColor]];

                        [uibarbuttonitemEncodeCancelButton setTintColor:[UIColor redColor]];

                        [uibarbuttonitemEncodeSureButton setTintColor:[UIColor redColor]];
                        
//                        [uitextfieldEncodeTextField setBackgroundColor:[UIColor colorWithRed:0.823 green:0.823 blue:0.823 alpha:1]];
                        break;

                    default:
                        [uicontrolEncodeView setBackgroundColor:[UIColor colorWithRed:0.84 green:0.92 blue:1 alpha:1]];
                        [_uitoolbarEncodeBar setBarTintColor:[UIColor colorWithRed:0.41 green:0.5 blue:0.99 alpha:1]];

                        [_uibarbuttonitemDecodeNone setTintColor:[UIColor blackColor]];
                        [_uilabelDecodeNone setTextColor:[UIColor colorWithRed:0.137 green:0.235 blue:0.784 alpha:1]];

                        [uibarbuttonitemEncodeCancelButton setTintColor:[UIColor colorWithRed:0.784 green:0.137 blue:0.137 alpha:1]];

                        [uibarbuttonitemEncodeSureButton setTintColor:[UIColor colorWithRed:0.784 green:0.137 blue:0.137 alpha:1]];

//                        [uitextfieldEncodeTextField setBackgroundColor:[UIColor whiteColor]];
                        break;
                    }
                [uitextfieldEncodeTextField setBackground:uiimageTextFieldBackground];

                uicontrolEncodeView.hidden = NO;
                }];
                
            [uialertcontroller addAction:uialertactionOverRide];
            [uialertcontroller addAction:uialertactionDecode];
            
            [self presentViewController:uialertcontroller animated:YES completion:nil];
            
//            UIAlertView *uialertviewAlert = [[UIAlertView alloc] initWithTitle:@"警告" message:@"相片已存在一個秘密註解\n請問是否解密或進行覆蓋？" delegate:self cancelButtonTitle:@"覆蓋" otherButtonTitles:@"解密", nil];
//            [uialertviewAlert show];
            }
        }
    else
        {
        uitextviewCommentTextView.text = @"";
        uitextfieldPasswardTextField.text = @"";
        
        uibarbuttonitemEditCommentButton.enabled = NO;
        uibarbuttonitemEditFontButton.enabled = NO;
        uibarbuttonitemTrashButton.enabled = NO;
        uiswitchPasswardSwitch.on = NO;
        uitextfieldPasswardTextField.hidden = YES;
        self.uitextviewEncryptTextShow.hidden = YES;

        [self CommentViewSwitchTheme];

        uicontrolEditCommentView.hidden = NO;
        }
    
    
}

//----------------------------------------------------------------------------------------

//按下編輯視窗裡的取消後要執行的動作
- (IBAction)editCommentViewCancel:(id)sender
{
    uibarbuttonitemEditCommentButton.enabled = YES;
    uibarbuttonitemEditFontButton.enabled = YES;
    uibarbuttonitemTrashButton.enabled = YES;
    
    [uitextfieldPasswardTextField resignFirstResponder];
    [uitextviewCommentTextView resignFirstResponder];
    
    self.uicontrolEncrytTextView.hidden = YES;
    uicontrolEditCommentView.hidden = YES;
}

//----------------------------------------------------------------------------------------

//觸碰背景時要執行的動作
- (IBAction)backgroundTouch:(id)sender
{
    [uitextfieldPasswardTextField resignFirstResponder];
    [uitextviewCommentTextView resignFirstResponder];
    [uitextfieldEncodeTextField resignFirstResponder];
    
    if (self.uitextviewCommentShow.hidden)
        self.uitextviewCommentShow.hidden = NO;
}

//----------------------------------------------------------------------------------------

//打字時按下done後要執行的動作
- (IBAction)textFieldDone:(id)sender
{
    [sender resignFirstResponder];
}

//----------------------------------------------------------------------------------------

//在編輯註解視窗裡按下確定後要執行的動作
- (IBAction)editCommentViewEnsure:(id)sender
{
    //產生一個NSMutableData物件
    NSMutableData *nsmutabledataWriteData = [[NSMutableData alloc] init];
    
    //判斷是否標頭檔裡已經有我們所建立的資料
    if (uintCnt < nsdataGlobalData.length)
        {
        //判斷是否要加密
        if (uiswitchPasswardSwitch.on == YES && uitextfieldPasswardTextField.text.length != 0)
            {
            //用NSString暫存編輯好的文字以及要設定的密碼
            NSString *nsstringTempPassward = uitextfieldPasswardTextField.text;
            NSString *nsstringTempComment = uitextviewCommentTextView.text;
            
            if (![uitextviewCommentTextView.text isEqualToString:@""])
                {
                //將uitextviewCommentShow的text設為空字串然後把它隱藏
                uitextviewCommentShow.text = @"";
                uitextviewCommentShow.hidden = YES;
            
            
                //暫時的註解資料
                NSMutableData *nsmutabledataTempData = [[NSMutableData alloc] initWithData:[nsstringTempComment dataUsingEncoding:NSUTF8StringEncoding]];
            
                //計算註解長度 不是16的倍數 補0直到是16的倍數
                if (nsmutabledataTempData.length%16 != 0)
                    [nsmutabledataTempData increaseLengthBy:16 - (nsmutabledataTempData.length%16)];

                //暫時的密碼資料
                NSMutableData *nsmutabledataTempPasswardData = [[NSMutableData alloc] initWithData:[nsstringTempPassward dataUsingEncoding:NSUTF8StringEncoding]];

                //計算密碼長度不是32 補0直到是32
                if (nsmutabledataTempPasswardData.length < 32)
                    [nsmutabledataTempPasswardData increaseLengthBy:32 - nsmutabledataTempPasswardData.length];
                Byte *byteTempPassward = (Byte *)[nsmutabledataTempPasswardData bytes];

                //宣告一個struct來儲存marker
                Header headerTemp;
            
                headerTemp.byteMarker[0] = 0xFF;
                headerTemp.byteMarker[1] = 0xD8;
                headerTemp.byteMarker[2] = 0xFF;
                headerTemp.byteMarker[3] = 0xE6;
                headerTemp.byteDataSize[0] = (nsmutabledataTempData.length + 2)/256;
                headerTemp.byteDataSize[1] = (nsmutabledataTempData.length + 2)%256;
            
                //利用struct將marker寫入nsmutabledataWriteData
                [nsmutabledataWriteData appendBytes:&headerTemp length:sizeof(headerTemp)];

                //新增註解資料到nsmutabledataWriteData裡
                [nsmutabledataWriteData appendData:nsmutabledataTempData];

                //新增全域資料裡除了之前註解資料以外的所有資料到nsmutabledataWriteData裡
                [nsmutabledataWriteData appendData:[nsdataGlobalData subdataWithRange:NSMakeRange(uintCnt + uintDataSize, nsdataGlobalData.length - uintCnt -uintDataSize)]];
            
                //重設全域變數uintCnt、uintDataSize
                uintCnt = 4;
                uintDataSize = (uint)nsmutabledataTempData.length + 2;

                //使用AES Encrypt
                for (int i = 0; i < iKeyLen; i++)
                    key[i] = byteTempPassward[i];
                    
                int intExpendKeyLen = AES_ExpandKey(key, iKeyLen);
            
                for(int i = 0; i < uintDataSize - 2; i+=16)
                    {
                    Byte *byteEncrypt = (Byte *)[[nsmutabledataWriteData subdataWithRange:NSMakeRange(uintCnt + 2 + i, 16)] bytes];
                    AES_Encrypt(byteEncrypt, key, intExpendKeyLen);
            
                    [nsmutabledataWriteData replaceBytesInRange:NSMakeRange(uintCnt + 2 + i, 16) withBytes:byteEncrypt];
                    }
                    
                //將剛剛做好編輯的資料存回nsdataGlobalData
                nsdataGlobalData = nsmutabledataWriteData;

                //另外用沙盒內的資料夾創檔案並寫入 結果：可寫入
                NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentDirectory = [path objectAtIndex:0];
                NSString *fileName = [documentDirectory stringByAppendingPathComponent:@"test.jpg"];
                
                //確認檔案是否已存在 如果以存在就直接覆寫 如果不存在就建立一個新的檔案
                if ([[NSFileManager defaultManager]fileExistsAtPath:fileName])
                    NSLog([nsmutabledataWriteData writeToFile:fileName atomically:YES]?@"yes1":@"no1");
                else
                    NSLog([[NSFileManager defaultManager] createFileAtPath:fileName contents:nsmutabledataWriteData attributes:nil]?@"yes2":@"no2");

                dispatch_async(dispatch_get_main_queue(), ^
                    {
                    [self performSelector:@selector(choseWhetherSaveOriginalImage)];
                    });

                uibarbuttonitemEditCommentButton.enabled = YES;
                uibarbuttonitemEditFontButton.enabled = YES;
                uibarbuttonitemTrashButton.enabled = YES;
    
                [uitextfieldPasswardTextField resignFirstResponder];
                [uitextviewCommentTextView resignFirstResponder];
                
                self.uicontrolEncrytTextView.hidden = YES;
                uicontrolEditCommentView.hidden = YES;
                }
            else
                {
                UIAlertController *uialertcontrollerAlert = [UIAlertController alertControllerWithTitle:@"警告" message:@"要加密的註解不得為空\n請輸入註解" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *uialertactionCancel = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){}];
                [uialertcontrollerAlert addAction:uialertactionCancel];
                [self presentViewController:uialertcontrollerAlert animated:YES completion:nil];
                }
            }
        else
            {
            //用NSString暫存編輯好的文字
            NSString *nsstringTempComment = uitextviewCommentTextView.text;
            
            //將uitextviewCommentShow的text設為uitextviewCommentTextView裡的文字
            uitextviewCommentShow.text = uitextviewCommentTextView.text;
            
            if ([uitextviewCommentShow.text isEqualToString:@""])
                {
                uitextviewCommentShow.hidden = YES;
                
                Byte byteHeader[] = {0xFF,0xD8};
                
                [nsmutabledataWriteData appendBytes:byteHeader length:sizeof(byteHeader)];

                //新增全域資料裡除了之前註解資料以外的所有資料到nsmutabledataWriteData裡
                [nsmutabledataWriteData appendData:[nsdataGlobalData subdataWithRange:NSMakeRange(uintCnt+uintDataSize, nsdataGlobalData.length-uintCnt-uintDataSize)]];
            
                //重設全域變數uintCnt
                uintCnt = (uint)nsmutabledataWriteData.length + 1;

                //將剛剛做好編輯的資料存回nsdataGlobalData
                nsdataGlobalData = nsmutabledataWriteData;

                //另外用沙盒內的資料夾創檔案並寫入 結果：可寫入
                NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentDirectory = [path objectAtIndex:0];
                NSString *fileName = [documentDirectory stringByAppendingPathComponent:@"test.jpg"];
                
                //確認檔案是否已存在 如果以存在就直接覆寫 如果不存在就建立一個新的檔案
                if ([[NSFileManager defaultManager]fileExistsAtPath:fileName])
                    NSLog([nsmutabledataWriteData writeToFile:fileName atomically:YES]?@"yes1":@"no1");
                else
                    NSLog([[NSFileManager defaultManager] createFileAtPath:fileName contents:nsmutabledataWriteData attributes:nil]?@"yes2":@"no2");

                dispatch_async(dispatch_get_main_queue(), ^
                    {
                    [self performSelector:@selector(choseWhetherSaveOriginalImage)];
                    });
                }
            else
                {
                uitextviewCommentShow.hidden = NO;

                [self commentShowTextViewFontSet];
                
                //暫時的註解資料
                NSMutableData *nsmutabledataTempData = [[NSMutableData alloc] initWithData:[nsstringTempComment dataUsingEncoding:NSUTF8StringEncoding]];

                //宣告一個struct來儲存marker
                Header headerTemp;
            
                headerTemp.byteMarker[0] = 0xFF;
                headerTemp.byteMarker[1] = 0xD8;
                headerTemp.byteMarker[2] = 0xFF;
                headerTemp.byteMarker[3] = 0xE6;
                headerTemp.byteDataSize[0] = (nsmutabledataTempData.length + 2)/256;
                headerTemp.byteDataSize[1] = (nsmutabledataTempData.length + 2)%256;
            
                //利用struct將marker寫入nsmutabledataWriteData
                [nsmutabledataWriteData appendBytes:&headerTemp length:sizeof(headerTemp)];

                //新增註解資料到nsmutabledataWriteData裡
                [nsmutabledataWriteData appendData:nsmutabledataTempData];

                //新增全域資料裡除了之前註解資料以外的所有資料到nsmutabledataWriteData裡
                [nsmutabledataWriteData appendData:[nsdataGlobalData subdataWithRange:NSMakeRange(uintCnt + uintDataSize, nsdataGlobalData.length - uintCnt -uintDataSize)]];
            
                //重設全域變數uintCnt、uintDataSize
                uintCnt = 4;
                uintDataSize = (uint)nsmutabledataTempData.length + 2;

                //將剛剛做好編輯的資料存回nsdataGlobalData
                nsdataGlobalData = nsmutabledataWriteData;

                //另外用沙盒內的資料夾創檔案並寫入 結果：可寫入
                NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentDirectory = [path objectAtIndex:0];
                NSString *fileName = [documentDirectory stringByAppendingPathComponent:@"test.jpg"];
                
                //確認檔案是否已存在 如果以存在就直接覆寫 如果不存在就建立一個新的檔案
                if ([[NSFileManager defaultManager]fileExistsAtPath:fileName])
                    NSLog([nsmutabledataWriteData writeToFile:fileName atomically:YES]?@"yes1":@"no1");
                else
                    NSLog([[NSFileManager defaultManager] createFileAtPath:fileName contents:nsmutabledataWriteData attributes:nil]?@"yes2":@"no2");

                dispatch_async(dispatch_get_main_queue(), ^
                    {
                    [self performSelector:@selector(choseWhetherSaveOriginalImage)];
                    });
                }
            uibarbuttonitemEditCommentButton.enabled = YES;
            uibarbuttonitemEditFontButton.enabled = YES;
            uibarbuttonitemTrashButton.enabled = YES;
    
            [uitextfieldPasswardTextField resignFirstResponder];
            [uitextviewCommentTextView resignFirstResponder];
                
            self.uicontrolEncrytTextView.hidden = YES;
            uicontrolEditCommentView.hidden = YES;
            }
        }
    else
        {
        //判斷是否要加密
        if (uiswitchPasswardSwitch.on == YES && uitextfieldPasswardTextField.text.length != 0)
            {
            //用NSString暫存編輯好的文字以及要設定的密碼
            NSString *nsstringTempPassward = uitextfieldPasswardTextField.text;
            NSString *nsstringTempComment = uitextviewCommentTextView.text;
            
            if (![uitextviewCommentTextView.text isEqualToString:@""])
                {
                //將uitextviewCommentShow的text設為空字串然後把它隱藏
                uitextviewCommentShow.text = @"";
                uitextviewCommentShow.hidden = YES;
            
            
                //暫時的註解資料
                NSMutableData *nsmutabledataTempData = [[NSMutableData alloc] initWithData:[nsstringTempComment dataUsingEncoding:NSUTF8StringEncoding]];
            
                //計算註解長度 不是16的倍數 補0直到是16的倍數
                if (nsmutabledataTempData.length%16 != 0)
                    [nsmutabledataTempData increaseLengthBy:16 - (nsmutabledataTempData.length%16)];

                //暫時的密碼資料
                NSMutableData *nsmutabledataTempPasswardData = [[NSMutableData alloc] initWithData:[nsstringTempPassward dataUsingEncoding:NSUTF8StringEncoding]];

                //計算密碼長度不是32 補0直到是32
                if (nsmutabledataTempPasswardData.length < 32)
                    [nsmutabledataTempPasswardData increaseLengthBy:32 - nsmutabledataTempPasswardData.length];
                Byte *byteTempPassward = (Byte *)[nsmutabledataTempPasswardData bytes];

                //宣告一個struct來儲存marker
                Header headerTemp;
            
                headerTemp.byteMarker[0] = 0xFF;
                headerTemp.byteMarker[1] = 0xD8;
                headerTemp.byteMarker[2] = 0xFF;
                headerTemp.byteMarker[3] = 0xE6;
                headerTemp.byteDataSize[0] = (nsmutabledataTempData.length + 2)/256;
                headerTemp.byteDataSize[1] = (nsmutabledataTempData.length + 2)%256;
            
                //利用struct將marker寫入nsmutabledataWriteData
                [nsmutabledataWriteData appendBytes:&headerTemp length:sizeof(headerTemp)];

                //新增註解資料到nsmutabledataWriteData裡
                [nsmutabledataWriteData appendData:nsmutabledataTempData];

                //新增全域資料裡除了FFD8以外的所有資料到nsmutabledataWriteData裡
                [nsmutabledataWriteData appendData:[nsdataGlobalData subdataWithRange:NSMakeRange(2, nsdataGlobalData.length - 2)]];
            
                //重設全域變數uintCnt、uintDataSize
                uintCnt = 4;
                uintDataSize = (uint)nsmutabledataTempData.length + 2;
            
                //使用AES Encrypt
                for (int i = 0; i < iKeyLen; i++)
                    key[i] = byteTempPassward[i];
                    
                int intExpendKeyLen = AES_ExpandKey(key, iKeyLen);
            
                for(int i = 0; i < uintDataSize - 2; i+=16)
                    {
                    Byte *byteEncrypt = (Byte *)[[nsmutabledataWriteData subdataWithRange:NSMakeRange(uintCnt + 2 + i, 16)] bytes];
                    AES_Encrypt(byteEncrypt, key, intExpendKeyLen);
            
                    [nsmutabledataWriteData replaceBytesInRange:NSMakeRange(uintCnt + 2 + i, 16) withBytes:byteEncrypt];
                    }
                
                //將剛剛做好編輯的資料存回nsdataGlobalData
                nsdataGlobalData = nsmutabledataWriteData;

                //另外用沙盒內的資料夾創檔案並寫入 結果：可寫入
                NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentDirectory = [path objectAtIndex:0];
                NSString *fileName = [documentDirectory stringByAppendingPathComponent:@"test.jpg"];
                
                //確認檔案是否已存在 如果以存在就直接覆寫 如果不存在就建立一個新的檔案
                if ([[NSFileManager defaultManager]fileExistsAtPath:fileName])
                    NSLog([nsmutabledataWriteData writeToFile:fileName atomically:YES]?@"yes1":@"no1");
                else
                    NSLog([[NSFileManager defaultManager] createFileAtPath:fileName contents:nsmutabledataWriteData attributes:nil]?@"yes2":@"no2");
                
                dispatch_async(dispatch_get_main_queue(), ^
                    {
                    [self performSelector:@selector(choseWhetherSaveOriginalImage)];
                    });
                    
                uibarbuttonitemEditCommentButton.enabled = YES;
                uibarbuttonitemEditFontButton.enabled = YES;
                uibarbuttonitemTrashButton.enabled = YES;
    
                [uitextfieldPasswardTextField resignFirstResponder];
                [uitextviewCommentTextView resignFirstResponder];
                
                self.uicontrolEncrytTextView.hidden = YES;
                uicontrolEditCommentView.hidden = YES;
                }
            else
                {
                UIAlertController *uialertcontrollerAlert = [UIAlertController alertControllerWithTitle:@"警告" message:@"要加密的註解不得為空\n請輸入註解" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *uialertactionCancel = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){}];
                [uialertcontrollerAlert addAction:uialertactionCancel];
                [self presentViewController:uialertcontrollerAlert animated:YES completion:nil];
                }
            }
        else
            {
            //用NSString暫存編輯好的文字
            NSString *nsstringTempComment = uitextviewCommentTextView.text;
            
            //將uitextviewCommentShow的text設為uitextviewCommentTextView裡的文字
            uitextviewCommentShow.text = uitextviewCommentTextView.text;
            
            if ([uitextviewCommentShow.text isEqualToString:@""])
                {
                }
            else
                {
                uitextviewCommentShow.hidden = NO;
                
                [self commentShowTextViewFontSet];
                
                //暫時的註解資料
                NSMutableData *nsmutabledataTempData = [[NSMutableData alloc] initWithData:[nsstringTempComment dataUsingEncoding:NSUTF8StringEncoding]];
            
                //宣告一個struct來儲存marker
                Header headerTemp;
            
                headerTemp.byteMarker[0] = 0xFF;
                headerTemp.byteMarker[1] = 0xD8;
                headerTemp.byteMarker[2] = 0xFF;
                headerTemp.byteMarker[3] = 0xE6;
                headerTemp.byteDataSize[0] = (nsmutabledataTempData.length + 2)/256;
                headerTemp.byteDataSize[1] = (nsmutabledataTempData.length + 2)%256;
            
                //利用struct將marker寫入nsmutabledataWriteData
                [nsmutabledataWriteData appendBytes:&headerTemp length:sizeof(headerTemp)];

                //新增註解資料到nsmutabledataWriteData裡
                [nsmutabledataWriteData appendData:nsmutabledataTempData];

                //新增全域資料裡除了FFD8以外的所有資料到nsmutabledataWriteData裡
                [nsmutabledataWriteData appendData:[nsdataGlobalData subdataWithRange:NSMakeRange(2, nsdataGlobalData.length - 2)]];
            
                //重設全域變數uintCnt、uintDataSize
                uintCnt = 4;
                uintDataSize = (uint)nsmutabledataTempData.length + 2;
            
                //將剛剛做好編輯的資料存回nsdataGlobalData
                nsdataGlobalData = nsmutabledataWriteData;

                //另外用沙盒內的資料夾創檔案並寫入 結果：可寫入
                NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentDirectory = [path objectAtIndex:0];
                NSString *fileName = [documentDirectory stringByAppendingPathComponent:@"test.jpg"];
                
                //確認檔案是否已存在 如果以存在就直接覆寫 如果不存在就建立一個新的檔案
                if ([[NSFileManager defaultManager]fileExistsAtPath:fileName])
                    NSLog([nsmutabledataWriteData writeToFile:fileName atomically:YES]?@"yes1":@"no1");
                else
                    NSLog([[NSFileManager defaultManager] createFileAtPath:fileName contents:nsmutabledataWriteData attributes:nil]?@"yes2":@"no2");
                
                dispatch_async(dispatch_get_main_queue(), ^
                    {
                    [self performSelector:@selector(choseWhetherSaveOriginalImage)];
                    });
                }
            uibarbuttonitemEditCommentButton.enabled = YES;
            uibarbuttonitemEditFontButton.enabled = YES;
            uibarbuttonitemTrashButton.enabled = YES;
    
            [uitextfieldPasswardTextField resignFirstResponder];
            [uitextviewCommentTextView resignFirstResponder];
                
            self.uicontrolEncrytTextView.hidden = YES;
            uicontrolEditCommentView.hidden = YES;
            }
        }
    

}

//----------------------------------------------------------------------------------------

//按下解密視窗中的Cancel鍵後要執行的動作
- (IBAction)encodeViewCancel:(id)sender
{
    uibarbuttonitemEditCommentButton.enabled = YES;
    uibarbuttonitemEditFontButton.enabled = YES;
    uibarbuttonitemTrashButton.enabled = YES;
 
    [uitextfieldEncodeTextField resignFirstResponder];
    
    self.uicontrolEncrytTextView.hidden = YES;
    uicontrolEncodeView.hidden = YES;
}

//----------------------------------------------------------------------------------------

//按下解密視窗中確定鍵後要執行的動作
- (IBAction)encodeViewEnsure:(id)sender
{
    [uitextfieldEncodeTextField resignFirstResponder];
    
    //宣告一個NSMutableData Instance 用來讀取資料
    NSMutableData *nsmutabledataReadData = [[NSMutableData alloc] initWithData:nsdataGlobalData];
    
    //使用AES Decrypt

    //暫時密碼資料
    NSMutableData *nsmutabledataTempPasswardData = [[NSMutableData alloc] initWithData:[uitextfieldEncodeTextField.text dataUsingEncoding:NSUTF8StringEncoding]];
    
    //如果密碼長度不是32 補0直到32
    if (uitextfieldEncodeTextField.text.length < 32)
        [nsmutabledataTempPasswardData increaseLengthBy:32 - nsmutabledataTempPasswardData.length];
    Byte *byteTempPassward = (Byte *)[nsmutabledataTempPasswardData bytes];

    for (int i = 0; i < iKeyLen; i++)
        key[i] = byteTempPassward[i];
    
    int intExpendKeyLen = AES_ExpandKey(key, iKeyLen);
            
    for(int i = 0; i < uintDataSize - 2; i+=16)
        {
        Byte *byteDecrypt = (Byte *)[[nsmutabledataReadData subdataWithRange:NSMakeRange(uintCnt + 2 + i, 16)] bytes];
        AES_Decrypt(byteDecrypt, key, intExpendKeyLen);
        
        [nsmutabledataReadData replaceBytesInRange:NSMakeRange(uintCnt + 2 + i, 16) withBytes:byteDecrypt];
        }
    
    NSString *nsstringTempCommentText = [[NSString alloc] initWithData:[nsmutabledataReadData subdataWithRange:NSMakeRange(uintCnt + 2, uintDataSize - 2)] encoding:NSUTF8StringEncoding];
    
    //判斷密碼是否正確
    if (nsstringTempCommentText != nil)
        {
        Byte *byteTemp = (Byte *)[nsmutabledataReadData bytes];
        
        //將解密後的註解資料顯示出來
        uint uintTextLen = uintCnt + 2;
        while (uintTextLen < uintCnt + uintDataSize)
            {
            if (byteTemp[uintTextLen] == 0x0)
                break;
            uintTextLen++;
            }
        uintTextLen -= (uintCnt + 2);
        
        uitextviewCommentShow.text = [[NSString alloc] initWithData:[nsmutabledataReadData subdataWithRange:NSMakeRange(uintCnt + 2, uintTextLen)] encoding:NSUTF8StringEncoding];
        
        uitextviewCommentShow.hidden = NO;
        
        [self commentShowTextViewFontSet];
        
        //宣告一個NSMutableData Instance用來儲存資料
        NSMutableData *nsmutabledataWriteData = [[NSMutableData alloc] init];
        
        if (uintTextLen < uintDataSize - 2)
            {
            //宣告一個struct來儲存marker
            Header headerTemp;
            
            headerTemp.byteMarker[0] = 0xFF;
            headerTemp.byteMarker[1] = 0xD8;
            headerTemp.byteMarker[2] = 0xFF;
            headerTemp.byteMarker[3] = 0xE6;
            headerTemp.byteDataSize[0] = (uintTextLen + 2)/256;
            headerTemp.byteDataSize[1] = (uintTextLen + 2)%256;
            
            //利用struct將marker寫入nsmutabledataWriteData
            [nsmutabledataWriteData appendBytes:&headerTemp length:sizeof(headerTemp)];
            
            //將去除多餘零的註解資料放入nsmutabledataWriteData
            [nsmutabledataWriteData appendData:[nsmutabledataReadData subdataWithRange:NSMakeRange(uintCnt + 2, uintTextLen)]];
            
            //將除了FFD8以及我們的註解資料以外的資料放入nsmutabledataWrieData
            [nsmutabledataWriteData appendData:[nsmutabledataReadData subdataWithRange:NSMakeRange(uintCnt + uintDataSize, nsdataGlobalData.length - uintCnt - uintDataSize)]];
            
            //重設全域變數uintCnt、uintDataSize
            uintCnt = 4;
            uintDataSize = uintTextLen + 2;
            }
        else
            {
            nsmutabledataWriteData = nsmutabledataReadData;
            }
        
        //重設全域變數nsdataGlobalData
        nsdataGlobalData = nsmutabledataWriteData;
        
        //另外用沙盒內的資料夾創檔案並寫入 結果：可寫入
        NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentDirectory = [path objectAtIndex:0];
        NSString *fileName = [documentDirectory stringByAppendingPathComponent:@"test.jpg"];
                
        //確認檔案是否已存在 如果以存在就直接覆寫 如果不存在就建立一個新的檔案
        if ([[NSFileManager defaultManager]fileExistsAtPath:fileName])
            [nsmutabledataWriteData writeToFile:fileName atomically:YES];
        else
            [[NSFileManager defaultManager] createFileAtPath:fileName contents:nsmutabledataWriteData attributes:nil];
        
        UIAlertController *uialertcontroller = [UIAlertController alertControllerWithTitle:@"警告" message:@"" preferredStyle:UIAlertControllerStyleAlert];
        
        //Change uialertcontroller message text font size
        NSMutableAttributedString *nsmutableattributedstring = [[NSMutableAttributedString alloc] initWithString:@"是否另存一張含有\n明文註解的新照片"];
        [nsmutableattributedstring addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:16.0] range:[nsmutableattributedstring.string rangeOfString:@"是否另存一張含有\n明文註解的新照片"]];

        [uialertcontroller setValue:nsmutableattributedstring forKey:@"attributedMessage"];

        UIAlertAction *uialertactionYes = [UIAlertAction
            actionWithTitle:@"另存一張"
            style:UIAlertActionStyleDefault
            handler:^(UIAlertAction * _Nonnull action)
                {
                if (self.phassetAsset)
                    {
                    __block PHObjectPlaceholder *phobjectplaceholderPlaceholder;

                    //直接建立一張照片
                    [[PHPhotoLibrary sharedPhotoLibrary]
                        performChanges:^
                            {
                            PHAssetChangeRequest *phassetchangerequestCreate = [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:[NSURL URLWithString:fileName]];
                            phobjectplaceholderPlaceholder = [phassetchangerequestCreate placeholderForCreatedAsset];
                    
                            self.phassetAsset = [PHAsset fetchAssetsWithLocalIdentifiers:@[phobjectplaceholderPlaceholder.localIdentifier] options:nil].firstObject;
                    
                            self.nsstringAlbumPath = nil;
                            self.nsstringAsset = nil;
                            }
                        completionHandler:^(BOOL success, NSError * _Nullable error)
                            {
                            NSLog(@"%@",error);
                            }];
                    }
                else
                    {
                    uint uintName = 0;
                    NSArray *nsarrayAssets = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.nsstringAlbumPath error:nil];

                    for (uintName = 0; uintName < nsarrayAssets.count; uintName++)
                        {
                        if (![nsarrayAssets[uintName] isEqualToString:[NSString stringWithFormat:@"%i.JPG",uintName]])
                            break;
                        }
            
                    [[NSFileManager defaultManager] createFileAtPath:[self.nsstringAlbumPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%i.JPG",uintName]] contents:nsdataGlobalData attributes:nil];
            
                    self.nsstringAsset = [NSString stringWithFormat:@"%i.JPG",uintName];
                    self.phassetAsset = nil;
        
                    NSLog(@"%@",self.nsstringAsset);
        
                    [self.delegate haveChangeGridViewAsset:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.nsstringAlbumPath error:nil] AlbumName:nil AlbumPath:nil];
            
                    }
                [uialertcontroller dismissViewControllerAnimated:YES completion:nil];
                }];
            
        UIAlertAction *uialertactionNo = [UIAlertAction
            actionWithTitle:@"保持原樣"
            style:UIAlertActionStyleDefault
            handler:nil];
            
            
        [uialertcontroller addAction:uialertactionYes];
        [uialertcontroller addAction:uialertactionNo];
        [self  presentViewController:uialertcontroller animated:YES completion:nil];
            
        uibarbuttonitemEditCommentButton.enabled = YES;
        uibarbuttonitemEditFontButton.enabled = YES;
        uibarbuttonitemTrashButton.enabled = YES;
    
        uicontrolEncodeView.hidden = YES;
            
        }
    else
        {
        self.uilabelDecodeWrongAlert.text = @"密碼錯誤";
        }
}

//----------------------------------------------------------------------------------------

//註解視窗中的Switch值改變後要進行的動作
- (IBAction)switchChanged:(id)sender
{
    if (uiswitchPasswardSwitch.on == YES)
        {
        uitextfieldPasswardTextField.hidden = NO;

        UIImage *uiimageBackground = nil;
        UIImage *uiimageEdit = nil;
        
        switch (_nsuintegerTheme)
            {
            case 0:
                uiimageBackground = [UIImage imageNamed:@"ENCRYPTION_BACKGROUND.png"];
                [_uicontrolEncrytTextView setBackgroundColor:[UIColor colorWithPatternImage:uiimageBackground]];

                [_uitextviewEncryptTextShow setBackgroundColor:[UIColor whiteColor]];
                break;

            case 1:
                uiimageBackground = [UIImage imageNamed:@"COMMEMT_BACKGROUND2_White.png"];
                [uicontrolEditCommentView setBackgroundColor:[UIColor colorWithPatternImage:uiimageBackground]];
                
                uiimageBackground = [UIImage imageNamed:@"ENCRYPTION_BACKGROUND_White.png"];
                [_uicontrolEncrytTextView setBackgroundColor:[UIColor colorWithPatternImage:uiimageBackground]];
                
                uiimageEdit = [UIImage imageNamed:@"ENCRYPTION_EDITOR_BACKGROUND_White.png"];
                [_uitextviewEncryptTextShow setBackgroundColor:[UIColor colorWithPatternImage:uiimageEdit]];
                break;

            default:
                [_uicontrolEncrytTextView setBackgroundColor:[UIColor colorWithRed:0.84 green:0.92 blue:1 alpha:1]];

                [_uitextviewEncryptTextShow setBackgroundColor:[UIColor whiteColor]];
                break;
            }
//        //分派給不同執行緒
//        dispatch_async(dispatch_get_global_queue(0, 0),
//            ^{
//            __block NSMutableData *nsmutabledataTempData = [[NSMutableData alloc] initWithData:[uitextviewCommentTextView.text dataUsingEncoding:NSUTF8StringEncoding]];
//            
//            dispatch_group_t group = dispatch_group_create();
//            
//            dispatch_group_async(group, dispatch_get_global_queue(0, 0),
//                ^{
//                if (nsmutabledataTempData.length%16 !=0)
//                    [nsmutabledataTempData increaseLengthBy:16 - nsmutabledataTempData.length%16];
//
//                //使用AES Encrypt
//                int intExpendKeyLen = AES_ExpandKey(key, iKeyLen);
//            
//                for(int i = 0; i < nsmutabledataTempData.length; i+=16)
//                    {
//                    Byte *byteEncrypt = (Byte *)[[nsmutabledataTempData subdataWithRange:NSMakeRange(i, 16)] bytes];
//                    AES_Encrypt(byteEncrypt, key, intExpendKeyLen);
//                
//                    for(int j = 0; j < 16; j++)
//                        {
//                        if (byteEncrypt[j] <= 33 || byteEncrypt[j] > 126)
//                            byteEncrypt[j] = 0x2A;
//                        }
//                    [nsmutabledataTempData replaceBytesInRange:NSMakeRange(i, 16) withBytes:byteEncrypt];
//                    }
//                
//                  });
//            dispatch_group_notify(group, dispatch_get_main_queue(),
//                ^{
//                self.uitextviewEncryptTextShow.text = [[NSString alloc] initWithData:nsmutabledataTempData encoding:NSUTF8StringEncoding];
//                 });
//            
//             });
        self.uitextviewEncryptTextShow.hidden = NO;
        self.uicontrolEncrytTextView.hidden = NO;
        }
    else
        {
        [uitextfieldPasswardTextField resignFirstResponder];
        uitextfieldPasswardTextField.hidden = YES;
        
        UIImage *uiimageBackground = nil;

        switch (_nsuintegerTheme)
            {
            case 1:
                uiimageBackground = [UIImage imageNamed:@"COMMEMT_BACKGROUND_White.png"];
                [uicontrolEditCommentView setBackgroundColor:[UIColor colorWithPatternImage:uiimageBackground]];
                break;

            default:
                break;
            }
            
        self.uitextviewEncryptTextShow.hidden = YES;
        self.uicontrolEncrytTextView.hidden = YES;
        }
}

//----------------------------------------------------------------------------------------

//刪除照片
- (IBAction)deleteAsset:(id)sender
{
    if (self.phassetAsset)
        {
        void (^completionHandler)(BOOL, NSError *) = ^(BOOL success, NSError *error)
            {
            if (success)
                {
                dispatch_async(dispatch_get_main_queue(), ^
                    {
                    [[self navigationController] popViewControllerAnimated:YES];
                    });
                }
            else
                {
                NSLog(@"Error: %@", error);
                }
            };
        
        // Delete asset from library
        [[PHPhotoLibrary sharedPhotoLibrary]
            performChanges:^
                {
                [PHAssetChangeRequest deleteAssets:@[self.phassetAsset]];
                }
            completionHandler:completionHandler];
        }
    else
        {
        [[NSFileManager defaultManager] removeItemAtPath:[self.nsstringAlbumPath stringByAppendingPathComponent:self.nsstringAsset] error:NULL];

        dispatch_async(dispatch_get_main_queue(), ^
            {
            [self.delegate haveChangeGridViewAsset:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.nsstringAlbumPath error:nil] AlbumName:nil AlbumPath:nil];
            
            [[self navigationController] popViewControllerAnimated:YES];
            });
            
        }
}


//----------------------------------------------------------------------------------------

//Swipe change Image
- (IBAction)swipeRight:(id)sender
{
    if (!uicontrolEditCommentView.hidden || !uicontrolEncodeView.hidden)
        return;
    NSLog(@"%d",(unsigned int)_nsuintegerAssetNum);
}

//----------------------------------------------------------------------------------------

- (IBAction)swipeLeft:(id)sender
{
    if (!uicontrolEditCommentView.hidden || !uicontrolEncodeView.hidden)
        return;
    NSLog(@"%d",(unsigned int)_nsuintegerAssetNum);
}

//----------------------------------------------------------------------------------------

//#pragma mark- Image Shrink Method
//
//- (UIImage *)shrinkImage:(UIImage *)image
//{
//    int kMaxResolution = 640;
//
//    CGImageRef imgRef = image.CGImage;
//
//    CGFloat width = CGImageGetWidth(imgRef);
//    CGFloat height = CGImageGetHeight(imgRef);
//
//
//    CGAffineTransform transform = CGAffineTransformIdentity;
//    CGRect bounds = CGRectMake(0, 0, width, height);
//    if (width > kMaxResolution || height > kMaxResolution) {
//        CGFloat ratio = width/height;
//        if (ratio > 1) {
//            bounds.size.width = kMaxResolution;
//            bounds.size.height = bounds.size.width / ratio;
//        }
//        else {
//            bounds.size.height = kMaxResolution;
//            bounds.size.width = bounds.size.height * ratio;
//        }
//    }
//    CGFloat scaleRatio = bounds.size.width / width;
//    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
//    CGFloat boundHeight;
//    UIImageOrientation orient = image.imageOrientation;
//
//    NSLog(@"%ld",(long)orient);
//    
//    switch(orient) {
//
//        case UIImageOrientationUp: //EXIF = 1
//            transform = CGAffineTransformIdentity;
//            break;
//
//        case UIImageOrientationUpMirrored: //EXIF = 2
//            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
//            transform = CGAffineTransformScale(transform, -1.0, 1.0);
//            break;
//
//        case UIImageOrientationDown: //EXIF = 3
//            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
//            transform = CGAffineTransformRotate(transform, M_PI);
//            break;
//
//        case UIImageOrientationDownMirrored: //EXIF = 4
//            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
//            transform = CGAffineTransformScale(transform, 1.0, -1.0);
//            break;
//
//        case UIImageOrientationLeftMirrored: //EXIF = 5
//            boundHeight = bounds.size.height;
//            bounds.size.height = bounds.size.width;
//            bounds.size.width = boundHeight;
//            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
//            transform = CGAffineTransformScale(transform, -1.0, 1.0);
//            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
//            break;
//        case UIImageOrientationLeft: //EXIF = 6
//            boundHeight = bounds.size.height;
//            bounds.size.height = bounds.size.width;
//            bounds.size.width = boundHeight;
//            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
//            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
//            break;
//
//        case UIImageOrientationRightMirrored: //EXIF = 7
//            boundHeight = bounds.size.height;
//            bounds.size.height = bounds.size.width;
//            bounds.size.width = boundHeight;
//            transform = CGAffineTransformMakeScale(-1.0, 1.0);
//            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
//            break;
//
//        case UIImageOrientationRight: //EXIF = 8
//            boundHeight = bounds.size.height;
//            bounds.size.height = bounds.size.width;
//            bounds.size.width = boundHeight;
//            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
//            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
//            break;
//
//        default:
//            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
//
//    }
//    UIGraphicsBeginImageContext(bounds.size);
//
//    CGContextRef context = UIGraphicsGetCurrentContext();
//
//    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
//        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
//        CGContextTranslateCTM(context, -height, 0);
//    }
//    else {
//        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
//        CGContextTranslateCTM(context, 0, -height);
//    }
//
//    CGContextConcatCTM(context, transform);
//
//    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
//    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//
//    return imageCopy;
//}

//----------------------------------------------------------------------------------------

#pragma mark- Segue Prepare

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"fontSetViewShow"])
        {
        FontSetViewController *fontsetviewcontroller = [segue destinationViewController];
        fontsetviewcontroller.nsstringFontSizeValue = nsstringFontSizeValue;
        fontsetviewcontroller.nsstringFontColorValue = nsstringFontColorValue;
        fontsetviewcontroller.nsstringFontTypeValue = nsstringFontTypeValue;
        fontsetviewcontroller.nsuintegerFontSizeValue_UInt = nsuintegerFontSizeValue_ViewControll;
        fontsetviewcontroller.nsindexpathFontSizeLastIndexPath = nsindexpathFontSizeLastIndexPath;
        fontsetviewcontroller.nsindexpathFontColorLastIndexPath = nsindexpathFontColorLastIndexPath;
        fontsetviewcontroller.nsindexpathFontTypeLastIndexPath = nsindexpathFontTypeLastIndexPath;
        fontsetviewcontroller.nsuintegerTheme = _nsuintegerTheme;
        fontsetviewcontroller.delegate = self;
        }
    else
        {
        CreateToAlbumTableViewController *createToAlbumTableViewController = [segue destinationViewController];
        if (self.phassetAsset || _boolAddToOrComment)
            createToAlbumTableViewController.nsstringAlbumName = @"Camera Roll";
        else
            {
            NSArray *nsarrayPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *nsstringDocumentDirectory = [nsarrayPath objectAtIndex:0];
            nsstringDocumentDirectory = [nsstringDocumentDirectory stringByAppendingPathComponent:@"Photo Comment"];
            
            createToAlbumTableViewController.nsstringAlbumName = [self.nsstringAlbumPath substringFromIndex:nsstringDocumentDirectory.length + 1];
            }
            
        createToAlbumTableViewController.nsdataGlobalData = self.nsdataGlobalData;
        createToAlbumTableViewController.nsuintegerTheme = _nsuintegerTheme;
        createToAlbumTableViewController.delegate = self;
        }
}

//----------------------------------------------------------------------------------------

#pragma mark- FontSet Pass Data Delegate

- (void)fontSettingPassToViewController:(NSString *)fontSize ColorSet:(NSString *)fontColor TypeSet:(NSString *)fontType FontSizeLast:(NSIndexPath *)fontSizeIndexPath FontColorLast:(NSIndexPath *)fontColorIndexPath FontTypeLast:(NSIndexPath *)fontTypeIndexPath
{
    self.nsstringFontSizeValue = fontSize;
    self.nsstringFontColorValue = fontColor;
    self.nsstringFontTypeValue = fontType;
    
    self.nsindexpathFontSizeLastIndexPath = fontSizeIndexPath;
    self.nsindexpathFontColorLastIndexPath = fontColorIndexPath;
    self.nsindexpathFontTypeLastIndexPath = fontTypeIndexPath;
    
    NSLog(@"%@,%@,%@",self.nsstringFontSizeValue,self.nsstringFontColorValue,self.nsstringFontTypeValue);
    
    //font Size Setting
    
    if ([nsstringFontSizeValue isEqualToString:@"小"])
        {
        nsuintegerFontSizeValue_ViewControll = 17;
        [uitextviewCommentShow setFont:[UIFont systemFontOfSize:nsuintegerFontSizeValue_ViewControll]];
        }
    else if ([nsstringFontSizeValue isEqualToString:@"中"])
        {
        nsuintegerFontSizeValue_ViewControll = 25;
        [uitextviewCommentShow setFont:[UIFont systemFontOfSize:nsuintegerFontSizeValue_ViewControll]];
        }
    else if ([nsstringFontSizeValue isEqualToString:@"大"])
        {
        nsuintegerFontSizeValue_ViewControll = 35;
        [uitextviewCommentShow setFont:[UIFont systemFontOfSize:nsuintegerFontSizeValue_ViewControll]];
        }
    
    //font Color Setting
    
    if ([nsstringFontColorValue isEqualToString:@"白"])
        {
        self.nsuintegerFontColorValue = 0;
        [uitextviewCommentShow setTextColor:[UIColor whiteColor]];
        }
    else if ([nsstringFontColorValue isEqualToString:@"紅"])
        {
        self.nsuintegerFontColorValue = 1;
        [uitextviewCommentShow setTextColor:[UIColor redColor]];
        }
    else if ([nsstringFontColorValue isEqualToString:@"藍"])
        {
        self.nsuintegerFontColorValue = 2;
        [uitextviewCommentShow setTextColor:[UIColor cyanColor]];
        }
    
    //font Type Setting
    
    if ([nsstringFontTypeValue isEqualToString:@"娃娃體"])
        {
        self.nsuintegerFontTypeValue = 0;
        [uitextviewCommentShow setFont:[UIFont fontWithName:@"DFWaWaTC-W5" size:nsuintegerFontSizeValue_ViewControll]];
        }
    else if ([nsstringFontTypeValue isEqualToString:@"翩翩體"])
        {
        self.nsuintegerFontTypeValue = 1;
        [uitextviewCommentShow setFont:[UIFont fontWithName:@"HanziPenTC-W5" size:nsuintegerFontSizeValue_ViewControll]];
        }
    else if ([nsstringFontTypeValue isEqualToString:@"魏碑"])
        {
        self.nsuintegerFontTypeValue = 2;
        [uitextviewCommentShow setFont:[UIFont fontWithName:@"Weibei-TC-Bold" size:nsuintegerFontSizeValue_ViewControll]];
        }
        
}

//----------------------------------------------------------------------------------------

- (void)setViewBackgroundWithTheme:(NSUInteger)Theme
{
    _nsuintegerTheme = Theme;
    
    //set uitoolbarbuttonitem text color
    switch (_nsuintegerTheme)
        {
        case 0:
            [uibarbuttonitemEditCommentButton setTintColor:[UIColor colorWithRed:0.294 green:0.686 blue:0.49 alpha:1]];

            [uibarbuttonitemEditFontButton setTintColor:[UIColor colorWithRed:0.294 green:0.686 blue:0.49 alpha:1]];

            [uibarbuttonitemTrashButton setTintColor:[UIColor colorWithRed:0.294 green:0.686 blue:0.49 alpha:1]];
            break;

        case 1:
            [uibarbuttonitemEditCommentButton setTintColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:1]];

            [uibarbuttonitemEditFontButton setTintColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:1]];

            [uibarbuttonitemTrashButton setTintColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:1]];
            break;

        default:
            [uibarbuttonitemEditCommentButton setTintColor:nil];

            [uibarbuttonitemEditFontButton setTintColor:nil];

            [uibarbuttonitemTrashButton setTintColor:nil];
            break;
        }
    
    [self.delegate setGridViewBackgroundWithTheme:_nsuintegerTheme];
}
//----------------------------------------------------------------------------------------

#pragma mark- TextField Delegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *nsstringTemp;
    NSData *nsdataTemp;
    
    if ([textField isEqual:uitextfieldPasswardTextField])
        {
        nsstringTemp = [[textField text] stringByReplacingCharactersInRange:range withString:string];
        nsdataTemp = [nsstringTemp dataUsingEncoding:NSUTF8StringEncoding];
        
        if (self.uitextviewEncryptTextShow.hidden != YES &&
            ![uitextviewCommentTextView.text isEqualToString:@""] &&
            nsdataTemp.length != 0)
            {
            dispatch_async(dispatch_get_global_queue(0, 0),
                ^{
                //暫時的註解資料
                __block NSMutableData *nsmutabledataTempData = [[NSMutableData alloc] initWithData:[uitextviewCommentTextView.text dataUsingEncoding:NSUTF8StringEncoding]];
            
                //暫時的密碼資料
                __block NSMutableData *nsmutabledataTempPasswardData = [NSMutableData dataWithData:nsdataTemp];

                dispatch_group_t group = dispatch_group_create();
            
                dispatch_group_async(group, dispatch_get_global_queue(0, 0),
                    ^{
                    //註解資料長度不是16的倍數 補0直到是16的倍數
                    if (nsmutabledataTempData.length%16 !=0)
                        [nsmutabledataTempData increaseLengthBy:16 - nsmutabledataTempData.length%16];

                    //計算密碼長度不是32 補0直到是32
                    if (nsmutabledataTempPasswardData.length < 32)
                        [nsmutabledataTempPasswardData increaseLengthBy:32 - nsmutabledataTempPasswardData.length];
                    Byte *byteTempPassward = (Byte *)[nsmutabledataTempPasswardData bytes];

                    //使用AES Encrypt
                    for (int i = 0; i < iKeyLen; i++)
                        key[i] = byteTempPassward[i];

                    int intExpendKeyLen = AES_ExpandKey(key, iKeyLen);
            
                    for (int i = 0; i < nsmutabledataTempData.length; i+=16)
                        {
                        Byte *byteEncrypt = (Byte *)[[nsmutabledataTempData subdataWithRange:NSMakeRange(i, 16)] bytes];
                        AES_Encrypt(byteEncrypt, key, intExpendKeyLen);
                
                        for (int j = 0; j < 16; j++)
                            {
                            if (byteEncrypt[j] <= 33 || byteEncrypt[j] > 126)
                                byteEncrypt[j] = 0x2A;
                            }
                        [nsmutabledataTempData replaceBytesInRange:NSMakeRange(i, 16) withBytes:byteEncrypt];
                        }
                
                    });
                dispatch_group_notify(group, dispatch_get_main_queue(),
                    ^{
                    self.uitextviewEncryptTextShow.text = [[NSString alloc] initWithData:nsmutabledataTempData encoding:NSUTF8StringEncoding];
                    });
                });
            }
        else
            self.uitextviewEncryptTextShow.text = @"";
            
        if (nsdataTemp.length < passwardTextLimit)
            return YES;
        else
            return NO;
        }
    else
        {
        nsstringTemp = [[textField text] stringByReplacingCharactersInRange:range withString:string];
        nsdataTemp = [nsstringTemp dataUsingEncoding:NSUTF8StringEncoding];
        
        self.uilabelDecodeWrongAlert.text = @"";

        if (nsdataTemp.length < passwardTextLimit)
            return YES;
        else
            return NO;
        }
    
    
}

//----------------------------------------------------------------------------------------

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if ([textField isEqual:uitextfieldPasswardTextField])
        {
        [UIView animateWithDuration:0.3 delay:0
            options:UIViewAnimationOptionBeginFromCurrentState
            animations:^
                {
                [self.view setFrame:CGRectMake(0,-110,320,480)];
                }
            completion:nil];
        }
    return YES;
}

//----------------------------------------------------------------------------------------

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    if ([textField isEqual:uitextfieldPasswardTextField])
        {
        [UIView animateWithDuration:0.3 delay:0
            options:UIViewAnimationOptionBeginFromCurrentState
            animations:^
                {
                [self.view setFrame:CGRectMake(0,0,320,480)];
                }
            completion:nil];
        
        }
    return YES;
}

//----------------------------------------------------------------------------------------

#pragma mark- UITextView Delegate Method

- (void)textViewDidChange:(UITextView *)textView
{
    if (textView.text.length > commentTextLimit)
        {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"警告" message:@"超過最大字數不能輸入" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];

        textView.text = [textView.text substringToIndex:commentTextLimit];
        }
    
    if (self.uitextviewEncryptTextShow.hidden != YES &&
        ![uitextviewCommentTextView.text isEqualToString:@""] &&
        ![uitextfieldPasswardTextField.text isEqualToString:@""])
        {
        dispatch_async(dispatch_get_global_queue(0, 0),
            ^{
            //暫時的註解資料
            __block NSMutableData *nsmutabledataTempData = [[NSMutableData alloc] initWithData:[textView.text dataUsingEncoding:NSUTF8StringEncoding]];
            
            //暫時的密碼資料
            __block NSMutableData *nsmutabledataTempPasswardData = [[NSMutableData alloc] initWithData:[uitextfieldPasswardTextField.text dataUsingEncoding:NSUTF8StringEncoding]];

            dispatch_group_t group = dispatch_group_create();
            
            dispatch_group_async(group, dispatch_get_global_queue(0, 0),
                ^{
                //註解資料長度不是16的倍數 補0直到是16的倍數
                if (nsmutabledataTempData.length%16 !=0)
                    [nsmutabledataTempData increaseLengthBy:16 - nsmutabledataTempData.length%16];

                //計算密碼長度不是32 補0直到是32
                if (nsmutabledataTempPasswardData.length < 32)
                    [nsmutabledataTempPasswardData increaseLengthBy:32 - nsmutabledataTempPasswardData.length];
                Byte *byteTempPassward = (Byte *)[nsmutabledataTempPasswardData bytes];

                //使用AES Encrypt
                for (int i = 0; i < iKeyLen; i++)
                    key[i] = byteTempPassward[i];

                int intExpendKeyLen = AES_ExpandKey(key, iKeyLen);
            
                for (int i = 0; i < nsmutabledataTempData.length; i+=16)
                    {
                    Byte *byteEncrypt = (Byte *)[[nsmutabledataTempData subdataWithRange:NSMakeRange(i, 16)] bytes];
                    AES_Encrypt(byteEncrypt, key, intExpendKeyLen);
                
                    for (int j = 0; j < 16; j++)
                        {
                        if (byteEncrypt[j] <= 33 || byteEncrypt[j] > 126)
                                byteEncrypt[j] = 0x2A;
                        }
                    [nsmutabledataTempData replaceBytesInRange:NSMakeRange(i, 16) withBytes:byteEncrypt];
                    }
                
                });
            dispatch_group_notify(group, dispatch_get_main_queue(),
                ^{
                self.uitextviewEncryptTextShow.text = [[NSString alloc] initWithData:nsmutabledataTempData encoding:NSUTF8StringEncoding];
                });
            });
        }
    else
        self.uitextviewEncryptTextShow.text = @"";
}

//----------------------------------------------------------------------------------------

#pragma mark- UIAlertView Delegate Method

//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//    switch (buttonIndex)
//        {
//        case 0:
//            {
//            uitextviewCommentTextView.text = @"";
//            uitextfieldPasswardTextField.text = @"";
//        
//            uibarbuttonitemEditCommentButton.enabled = NO;
//            uibarbuttonitemEditFontButton.enabled = NO;
//            uibarbuttonitemTrashButton.enabled = NO;
//            uiswitchPasswardSwitch.on = NO;
//            uitextfieldPasswardTextField.hidden = YES;
//
//            uicontrolEditCommentView.hidden = NO;
//            }
//            break;
//        case 1:
//            {
//            self.uilabelDecodeWrongAlert.text = @"";
//            uitextfieldEncodeTextField.text = @"";
//            uibarbuttonitemEditCommentButton.enabled = NO;
//            uibarbuttonitemEditFontButton.enabled = NO;
//            uibarbuttonitemTrashButton.enabled = NO;
//    
//            uicontrolEncodeView.hidden = NO;
//            }
//            break;
//        }
//}

//----------------------------------------------------------------------------------------
#pragma mark- Perform Yes Method | No Method

- (void)choseWhetherSaveOriginalImage
{
    //建立詢問視窗用以詢問是否要保留原始照片
    UIAlertController *uialertcontrollerAlert1 = [UIAlertController alertControllerWithTitle:@"警告" message:@"是否要保留原照片" preferredStyle:UIAlertControllerStyleAlert];
                
    //建立Yes的詢問按鈕以及被按下後所要執行的動作
    UIAlertAction *uialertactionYes1 = [UIAlertAction
        actionWithTitle:@"Yes"
        style:UIAlertActionStyleDefault
        handler:^(UIAlertAction * _Nonnull action)
            {
            //執行第二個選擇視窗
            dispatch_async(dispatch_get_main_queue(), ^
                {
                [self performSelector:@selector(choseWhereToSave)];
                });

            }];

    //建立No的詢問按鈕以及被按下後所要執行的動作
    UIAlertAction *uialertactionNo1 = [UIAlertAction
        actionWithTitle:@"No"
        style:UIAlertActionStyleDefault
        handler:^(UIAlertAction * _Nonnull action)
            {
            //刪除原始照片
            if (self.phassetAsset)
                {
                void (^completionHandler)(BOOL, NSError *) = ^(BOOL success, NSError *error)
                    {
                    dispatch_async(dispatch_get_main_queue(), ^
                        {
                        //刪除完畢執行第二個選擇視窗
                        [self performSelector:@selector(choseWhereToSave)];
                        });
                    };
        
                // Delete asset from library
                [[PHPhotoLibrary sharedPhotoLibrary]
                    performChanges:^
                        {
                        [PHAssetChangeRequest deleteAssets:@[self.phassetAsset]];
                        }
                    completionHandler:completionHandler];
                }
            else
                {
                [[NSFileManager defaultManager] removeItemAtPath:[self.nsstringAlbumPath stringByAppendingPathComponent:self.nsstringAsset] error:NULL];
        
                [self.delegate haveChangeGridViewAsset:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.nsstringAlbumPath error:nil] AlbumName:nil AlbumPath:nil];

                dispatch_async(dispatch_get_main_queue(), ^
                    {
                    //刪除完畢執行第二個選擇視窗
                    [self performSelector:@selector(choseWhereToSave)];
                    });
                    
                }
                [uialertcontrollerAlert1 dismissViewControllerAnimated:YES completion:nil];
            }];
                
    [uialertcontrollerAlert1 addAction:uialertactionYes1];
    [uialertcontrollerAlert1 addAction:uialertactionNo1];
                
    [self presentViewController:uialertcontrollerAlert1 animated:YES completion:nil];
    
}
//----------------------------------------------------------------------------------------

- (void)choseWhereToSave
{
    //取得沙盒內路徑
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [path objectAtIndex:0];
    NSString *fileName = [documentDirectory stringByAppendingPathComponent:@"test.jpg"];
    
    //建立詢問視窗用以詢問要在Photo Comment建立照片還是Camera Roll
    UIAlertController *uialertcontrollerAlert2 = [UIAlertController alertControllerWithTitle:@"提醒" message:@"要建立在私用目錄\n還是分享目錄？" preferredStyle:UIAlertControllerStyleAlert];
                                        
    //建立Camera Roll的詢問按鈕以及被按下後所要執行的動作
    UIAlertAction *uialertactionCameraRoll = [UIAlertAction actionWithTitle:@"分享目錄" style:UIAlertActionStyleDefault
        handler:^(UIAlertAction * _Nonnull action)
            {
            __block PHObjectPlaceholder *phobjectplaceholderPlaceholder;

            //直接建立一張照片
            [[PHPhotoLibrary sharedPhotoLibrary]
                performChanges:^
                    {
                    PHAssetChangeRequest *phassetchangerequestCreate = [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:[NSURL URLWithString:fileName]];
                    phobjectplaceholderPlaceholder = [phassetchangerequestCreate placeholderForCreatedAsset];
                    
                    
                    }
                completionHandler:^(BOOL success, NSError * _Nullable error)
                    {
                    self.phassetAsset = [PHAsset fetchAssetsWithLocalIdentifiers:@[phobjectplaceholderPlaceholder.localIdentifier] options:nil].firstObject;
                    self.nsstringAlbumName = @"Camera Roll";
                    
                    dispatch_async(dispatch_get_main_queue(),
                        ^{
                        //Set Navigationbar Title
                        self.navigationItem.title = _nsstringAlbumName;
                        });

                    // Fetch all assets, sorted by date created.
                    PHFetchOptions *options = [[PHFetchOptions alloc] init];
                    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
                    [self.delegate haveChangeGridViewPhAsset:[PHAsset fetchAssetsWithOptions:options] AlbumName:_nsstringAlbumName];
                    
                    self.nsstringAlbumPath = nil;
                    self.nsstringAsset = nil;
                    }];
            [uialertcontrollerAlert2 dismissViewControllerAnimated:YES completion:nil];
            }];
                                        
    //建立Photo Comment的詢問按鈕以及被按下後所要執行的動作
    UIAlertAction *uialertactionPhotoComment = [UIAlertAction actionWithTitle:@"私用目錄" style:UIAlertActionStyleDefault
    handler:^(UIAlertAction * _Nonnull action)
        {
        _boolAddToOrComment = YES;
        
        [self performSegueWithIdentifier:@"CreateTo" sender:nil];
            
        [uialertcontrollerAlert2 dismissViewControllerAnimated:YES completion:nil];
        }];
    
    //建立兩者皆存的詢問按鈕以及被按下後所要執行的動作
//    UIAlertAction *uialertactionBoth = [UIAlertAction
//        actionWithTitle:@"兩者皆存"
//        style:UIAlertActionStyleDefault
//        handler:^(UIAlertAction * _Nonnull action)
//            {
//            //直接建立一張照片
//            [[PHPhotoLibrary sharedPhotoLibrary]
//                performChanges:^
//                    {
//                    [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:[NSURL URLWithString:fileName]];
//                    }
//                completionHandler:^(BOOL success, NSError * _Nullable error)
//                    {
////                    NSLog(@"%@",error);
//                    }];
    
//            if (!self.nsstringAlbumPath)
//                self.nsstringAlbumPath = [documentDirectory stringByAppendingPathComponent:@"Photo Comment"];
//            uint uintName = 0;
//            NSArray *nsarrayAssets = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.nsstringAlbumPath error:nil];
//
//            for (uintName = 0; uintName < nsarrayAssets.count; uintName++)
//                {
//                if (![nsarrayAssets[uintName] isEqualToString:[NSString stringWithFormat:@"%i.JPG",uintName]])
//                    break;
//                }
//            
//            [[NSFileManager defaultManager] createFileAtPath:[self.nsstringAlbumPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%i.JPG",uintName]] contents:nsdataGlobalData attributes:nil];
//            
//            self.nsstringAsset = [NSString stringWithFormat:@"%i.JPG",uintName];
//            self.phassetAsset = nil;
//        
////            NSLog(@"%@",self.nsstringAsset);
//        
//            [self.delegate createAsset:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.nsstringAlbumPath error:nil]];
//            }];
    
    [uialertcontrollerAlert2 addAction:uialertactionCameraRoll];
    [uialertcontrollerAlert2 addAction:uialertactionPhotoComment];
//    [uialertcontrollerAlert2 addAction:uialertactionBoth];
    
    [self presentViewController:uialertcontrollerAlert2 animated:YES completion:nil];
}

//----------------------------------------------------------------------------------------

#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    // Call might come on any background queue. Re-dispatch to the main queue to handle it.
    dispatch_async(dispatch_get_main_queue(), ^
        {
        
        // check if there are changes to the album we're interested on (to its metadata, not to its collection of assets)
        PHObjectChangeDetails *phobjectchangeDetails = [changeInstance changeDetailsForObject:self.phassetAsset];
        
        if (phobjectchangeDetails)
            {
            // it changed, we need to fetch a new one
            self.phassetAsset = [phobjectchangeDetails objectAfterChanges];
            
            if ([phobjectchangeDetails assetContentChanged])
                [self updateDisplay];
            }
        });
}

//----------------------------------------------------------------------------------------

#pragma mark- Comment Show TextView Font Set Method

- (void)commentShowTextViewFontSet
{
    //Font Setting
    switch(self.nsuintegerFontColorValue)
        {
        case 0:[uitextviewCommentShow setTextColor:[UIColor whiteColor]];
            break;
        case 1:[uitextviewCommentShow setTextColor:[UIColor redColor]];
            break;
        case 2:[uitextviewCommentShow setTextColor:[UIColor cyanColor]];
            break;
        }
    switch(self.nsuintegerFontTypeValue)
        {
        case 0:[uitextviewCommentShow setFont:[UIFont fontWithName:@"DFWaWaTC-W5" size:nsuintegerFontSizeValue_ViewControll]];
                break;
        case 1:[uitextviewCommentShow setFont:[UIFont fontWithName:@"HanziPenTC-W5" size:nsuintegerFontSizeValue_ViewControll]];
                break;
        case 2:[uitextviewCommentShow setFont:[UIFont fontWithName:@"Weibei-TC-Bold" size:nsuintegerFontSizeValue_ViewControll]];
                break;
        }
}

//----------------------------------------------------------------------------------------

//開啟選擇要新增照片到哪個相簿的畫面
#pragma mark- Create To Where

- (void)createToWhere:(id)sender
{
    _boolAddToOrComment = NO;
    
    [uitextfieldPasswardTextField resignFirstResponder];
    [uitextviewCommentTextView resignFirstResponder];
    [uitextfieldEncodeTextField resignFirstResponder];
    
    uicontrolEncodeView.hidden = YES;
    uicontrolEditCommentView.hidden = YES;
    _uicontrolEncrytTextView.hidden = YES;

    uibarbuttonitemEditCommentButton.enabled = YES;
    uibarbuttonitemEditFontButton.enabled = YES;
    uibarbuttonitemTrashButton.enabled = YES;

    [self performSegueWithIdentifier:@"CreateTo" sender:sender];
}
//----------------------------------------------------------------------------------------

#pragma mark- AlbumChangeDelegate Method

- (void)haveChangedViewAlbum:(NSString *)AlbumPath AlbumName:(NSString *)AlbumName
    Asset:(NSString *)Asset
{
    if ([_nsstringAlbumPath isEqualToString:AlbumPath])
        {
        [self.delegate haveChangeGridViewAsset:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:AlbumPath error:nil] AlbumName:nil AlbumPath:nil];
        self.nsstringAsset = Asset;
        }
    else
        {
        self.nsstringAlbumPath = AlbumPath;
        self.nsstringAlbumName = AlbumName;
        self.phassetAsset = nil;
        self.nsstringAsset = Asset;
        [self.delegate haveChangeGridViewAsset:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:AlbumPath error:nil] AlbumName:AlbumName AlbumPath:AlbumPath];
        }
}

//----------------------------------------------------------------------------------------

- (void)sendNewPhAsset:(NSString *)Asset AlbumName:(NSString *)AlbumName
{
    if ([_nsstringAlbumName isEqualToString:AlbumName])
        self.phassetAsset = [PHAsset fetchAssetsWithLocalIdentifiers:@[Asset] options:nil].firstObject;
    else
        {
        self.nsstringAlbumName = AlbumName;
        self.phassetAsset = [PHAsset fetchAssetsWithLocalIdentifiers:@[Asset] options:nil].firstObject;
        
        self.nsstringAlbumPath = nil;
        self.nsstringAsset = nil;

        // Fetch all assets, sorted by date created.
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
        
        [self.delegate haveChangeGridViewPhAsset:[PHAsset fetchAssetsWithOptions:options] AlbumName:AlbumName];
        }
}
//----------------------------------------------------------------------------------------

//deprecated

//取得圖片
//- (void)getMediaFromSource:(UIImagePickerControllerSourceType)sourceType;

//image picker
//@synthesize uiimageImage,nsurlImageURL,nsstringLastChosenMediaType,
//uibuttonPickPictureButton,cgrectImageFrame;

//判斷是否能拍照？顯示拍照按鈕 ：隱藏拍照按鈕
//    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
//        self.uibuttonTakePictureButton.hidden = YES;
//    
    
//取圖片
//    [self getMediaFromSource:UIImagePickerControllerSourceTypePhotoLibrary];
    
//----------------------------------------------------------------------------------------

//註冊notification
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textviewEditChanged:) name:UITextViewTextDidChangeNotification object:uitextviewCommentTextView];
    
//查看字型的真實名稱
//    NSString *nsstringFontFamilyName;
//    NSString *nsstringFontName;
//    
//    for(nsstringFontFamilyName in [UIFont familyNames])
//        {
//        NSLog(@"--%@--",nsstringFontFamilyName);
//        for(nsstringFontName in [UIFont fontNamesForFamilyName:nsstringFontFamilyName])
//            NSLog(@"%@",nsstringFontName);
//        }

//設定Label
//    uibuttonPickPictureButton.titleLabel.font = [UIFont fontWithName:@"DFWaWaTC-W5" size:15.0];

//如果目前沒有圖片 就跳到選擇圖片的畫面
//    if (uiimageImage == nil)
//        [self getMediaFromSource:UIImagePickerControllerSourceTypePhotoLibrary];

//----------------------------------------------------------------------------------------

//設定Label行數不限制
//                                uilabelCommentShow.numberOfLines = 0;
//                                uilabelCommentShow.lineBreakMode = NSLineBreakByWordWrapping;
                                //[uitextviewCommentShow sizeToFit];
//    if ([nsstringLastChosenMediaType isEqualToString:(NSString *)kUTTypeImage])
//        {
//        }

    //Image Picker
//    self.uiimageImage = nil;
//    self.nsurlImageURL = nil;
//    self.nsurlMovieURL = nil;
//    self.mpmovieplayercontrollerMoviePlayerController = nil;

//----------------------------------------------------------------------------------------

//#pragma mark- IBAction Methods

//從剛拍的照片裡取圖片
//- (IBAction)shootPictureOrVideo:(id)sender
//{
//    [self getMediaFromSource:UIImagePickerControllerSourceTypeCamera];
//}

//----------------------------------------------------------------------------------------

//從Camera Roll裡取圖片
//- (IBAction)selectExistingPictureOrVideo:(id)sender
//{
//    [self getMediaFromSource:UIImagePickerControllerSourceTypePhotoLibrary];
//}

//----------------------------------------------------------------------------------------
//                PHFetchResult *phfetchresultResult = [PHAsset fetchAssetsWithALAssetURLs:@[nsurlImageURL] options:nil];
//                if (phfetchresultResult.count > 0)
//                    {
//                    PHAsset *phassetPhAsset = phfetchresultResult.firstObject;
//
//                    if (phassetPhAsset!=nil && [phassetPhAsset canPerformEditOperation:PHAssetEditOperationContent])
//                        {
//                        [phassetPhAsset requestContentEditingInputWithOptions:nil completionHandler:^(PHContentEditingInput *contentEditingInput, NSDictionary *info)
//                                {
//                                [nsmutabledataWriteData writeToURL:[contentEditingInput fullSizeImageURL] atomically:YES];
//                                }];
//                        }
//                    }

//----------------------------------------------------------------------------------------

//                //計算註解長度 不是16的倍數 補0直到是16的倍數
//                if (nsmutabledataTempData.length%16 != 0)
//                    [nsmutabledataTempData increaseLengthBy:16 - (nsmutabledataTempData.length%16)];

//----------------------------------------------------------------------------------------

//                            PHAdjustmentData *phadjustmentDataTemp = [[PHAdjustmentData alloc] initWithFormatIdentifier:@"com.example.myApp" formatVersion:@"1.0" data:[@"Edit comment" dataUsingEncoding:NSUTF8StringEncoding]];
//                            
//                            PHContentEditingOutput *phcontenteditingouputOutput = [[PHContentEditingOutput alloc] initWithContentEditingInput:contentEditingInput];
//                            //NSData *nsdataTest = UIImageJPEGRepresentation(uiimageImage, 1);
//                            
//                            [phcontenteditingouputOutput setAdjustmentData:phadjustmentDataTemp];
//                            
//                            BOOL boolWrote = [nsmutabledataWriteData writeToURL:[phcontenteditingouputOutput renderedContentURL] options:NSDataWritingAtomic error:nil];
//                    
//                            if (boolWrote)
//                                {
//                                [[PHPhotoLibrary sharedPhotoLibrary]
//                                    performChanges:
//                                        ^{
//                                        PHAssetChangeRequest *phassetchangerequestRequest = [PHAssetChangeRequest changeRequestForAsset:phassetPhAsset];
//                                        phassetchangerequestRequest.contentEditingOutput = phcontenteditingouputOutput;
//                                        
//                                         }
//                                    completionHandler:
//                                        ^(BOOL success, NSError *error)
//                                            {
////                                            NSLog(@"success : %@",@(success));
////                                            NSLog(@"error : %@",error);
//                                            }];
//                                }

//----------------------------------------------------------------------------------------

//                uitextviewCommentShow.hidden = YES;
//                Byte byteHeader[] = {0xFF,0xD8};
//                
//                [nsmutabledataWriteData appendBytes:byteHeader length:sizeof(byteHeader)];
//
//                //新增全域資料裡除了之前註解資料以外的所有資料到nsmutabledataWriteData裡
//                [nsmutabledataWriteData appendData:[nsdataGlobalData subdataWithRange:NSMakeRange(2, nsdataGlobalData.length - 2)]];
//            
//                //重設全域變數uintCnt
//                uintCnt = (uint)nsmutabledataWriteData.length + 1;
//
//                //將剛剛做好編輯的資料存回nsdataGlobalData
//                nsdataGlobalData = nsmutabledataWriteData;
//
//                PHFetchResult *phfetchresultResult = [PHAsset fetchAssetsWithALAssetURLs:@[nsurlImageURL] options:nil];
//                if (phfetchresultResult.count > 0)
//                    {
//                    PHAsset *phassetPhAsset = phfetchresultResult.firstObject;
//
//                    if (phassetPhAsset!=nil && [phassetPhAsset canPerformEditOperation:PHAssetEditOperationContent])
//                        {
//                        [phassetPhAsset requestContentEditingInputWithOptions:nil completionHandler:^(PHContentEditingInput *contentEditingInput, NSDictionary *info)
//                                {
//                                [nsmutabledataWriteData writeToURL:[contentEditingInput fullSizeImageURL] atomically:YES];
//                                }];
//                        }
//                    }

//----------------------------------------------------------------------------------------

//                [[[ALAssetsLibrary alloc] init]assetForURL:nsurlImageURL
//                    resultBlock:^(ALAsset *asset)
//                        {
//                        [asset writeModifiedImageDataToSavedPhotosAlbum:nsmutabledataWriteData
//                            metadata:nil
//                            completionBlock:^(NSURL *assetURL, NSError *error)
//                                {
//                                NSLog(@"%@",error);
//                                }];
//                        }
//                    failureBlock:^(NSError *error)
//                        {
//                    
//                        }];

//----------------------------------------------------------------------------------------

//                PHFetchResult *phfetchresultResult = [PHAsset fetchAssetsWithALAssetURLs:@[nsurlImageURL] options:nil];
//                if (phfetchresultResult.count > 0)
//                    {
//                    PHAsset *phassetPhAsset = phfetchresultResult.firstObject;
//
//                    if (phassetPhAsset!=nil && [phassetPhAsset canPerformEditOperation:PHAssetEditOperationContent])
//                        {
//                        [phassetPhAsset requestContentEditingInputWithOptions:nil completionHandler:^(PHContentEditingInput *contentEditingInput, NSDictionary *info)
//                                {
//                            NSLog([[NSFileManager defaultManager] fileExistsAtPath:[contentEditingInput.fullSizeImageURL path]]?@"yes":@"no");

//                            NSLog(@"%@",[contentEditingInput.fullSizeImageURL path]);
                                

//                    NSArray *nsarrayPhassetresource = [PHAssetResource assetResourcesForAsset:phassetPhAsset];
//                    PHAssetResource *phassetresource = nsarrayPhassetresource.firstObject;
//                    [[PHAssetResourceManager defaultManager] writeDataForAssetResource:phassetresource toFile:[contentEditingInput fullSizeImageURL] options:nil completionHandler:^(NSError * _Nullable error) {
//                        NSLog(@"%@",error);
//                    }];
//                            [[ALAssetsLibrary alloc] writeImageDataToSavedPhotosAlbum:nsmutabledataWriteData metadata:nil completionBlock:^(NSURL *url, NSError *error)
//                                    {
//                                    NSLog(@"%@",error);
//                                    }];
//                            CGImageDestinationRef myImageDest = CGImageDestinationCreateWithURL((CFURLRef)[[NSURL alloc] initWithString:[contentEditingInput.fullSizeImageURL path]], kUTTypeImage, 1, NULL);
//                            CGImageDestinationAddImage(myImageDest, (CGImageRef)[UIImage imageWithData:nsmutabledataWriteData], NULL);
//                            bool success = CGImageDestinationFinalize(myImageDest);
//                            
//                            if(!success)
//                                {
//                                NSLog(@"***Could not create data from image destination ***");
//                                }


//另外用沙盒內的資料夾創檔案並寫入 結果：可寫入
//                                NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//                                NSString *documentDirectory = [path objectAtIndex:0];
//                                NSString *fileName = [documentDirectory stringByAppendingPathComponent:@"test.jpg"];
//                                if ([[NSFileManager defaultManager]fileExistsAtPath:fileName])
//                                    NSLog([nsmutabledataWriteData writeToFile:fileName atomically:YES]?@"yes1":@"no1");
//                                else
//                                    NSLog([[NSFileManager defaultManager] createFileAtPath:fileName contents:nsmutabledataWriteData attributes:nil]?@"yes2":@"no2");
                        
                                
//查看相簿存取權限後在寫入 結果：失敗
//                        ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
//
//                        if(status == ALAuthorizationStatusNotDetermined)
//                            {
//                            //UNDETERMINED
//                            }
//                        else if(status == ALAuthorizationStatusRestricted)
//                            {
//                            //RESTRICTED
//                            }
//                        else if(status == ALAuthorizationStatusDenied)
//                            {
//                            //DENIED
//                            }
//                        else if(status == ALAuthorizationStatusAuthorized)
//                            {
//                            //GRANTED
//                            }

//利用fopen、fwrite方式寫入 結果：失敗
//                                FILE *test = fopen([contentEditingInput.fullSizeImageURL.path UTF8String], "r+b");
//                                
//                                fwrite([nsmutabledataWriteData bytes], sizeof(Byte), nsmutabledataWriteData.length, test);
//                                    
//                                fclose(test);
//
//                                }];
//                        }
//                    }

//----------------------------------------------------------------------------------------

//改變uicontrolEditCommentView的視窗高度
//        uicontrolEditCommentView.frame = CGRectMake(uicontrolEditCommentView.frame.origin.x, uicontrolEditCommentView.frame.origin.y, uicontrolEditCommentView.frame.size.width, uicontrolEditCommentView.frame.size.height + 130);

//----------------------------------------------------------------------------------------

//    PHFetchResult *phfetchresultResult = [PHAsset fetchAssetsWithALAssetURLs:@[nsurlImageURL] options:nil];
//    if (phfetchresultResult.count > 0)
//        {
//        PHAsset *phassetPhAsset = phfetchresultResult.firstObject;
//        [[PHPhotoLibrary sharedPhotoLibrary]
//            performChanges:
//               ^{
//                [PHAssetChangeRequest deleteAssets:@[phassetPhAsset]];
//                }
//            completionHandler:
//                ^(BOOL success, NSError *error)
//                {
//                if (success)
//                    {
//                    uiimageImage = nil;
//                    [self getMediaFromSource:UIImagePickerControllerSourceTypePhotoLibrary];
//                    }
//                }];
//        }

//----------------------------------------------------------------------------------------

//選完照片後要執行的動作
//#pragma mark- UIImagePickerController delegate methods
//- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
//{
//    self.nsstringLastChosenMediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
//    if ([nsstringLastChosenMediaType isEqualToString:(NSString *)kUTTypeImage])
//        {
//        UIImage *chosenImage = [info objectForKey:UIImagePickerControllerOriginalImage];
//        
//        nsurlImageURL = [info objectForKey:UIImagePickerControllerReferenceURL];
//        
//        PHFetchResult *phfetchresultResult = [PHAsset fetchAssetsWithALAssetURLs:@[nsurlImageURL] options:nil];
//        if (phfetchresultResult.count > 0)
//            {
//            PHAsset *phassetPhAsset = [phfetchresultResult firstObject];
    
//            if (phassetPhAsset != nil && [phassetPhAsset canPerformEditOperation:PHAssetEditOperationContent])
//                {
//                [phassetPhAsset requestContentEditingInputWithOptions:nil completionHandler:^(PHContentEditingInput *contentEditingInput,NSDictionary *info)
//                        {
//                        nsdataGlobalData = [[NSData alloc] initWithContentsOfURL:[contentEditingInput fullSizeImageURL]];

                        //NSLog(@"%@",[contentEditingInput fullSizeImageURL]);

//                        UIImage *shrunkenImage = shrinkImage([UIImage imageWithData:self.nsdataGlobalData], cgrectImageFrame.size);
//
//                        self.uiimageImage = shrunkenImage;
    

//                        }];
//                }
//            }
//        }
//        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//        [library assetForURL:imageURL resultBlock:^(ALAsset *asset)
//            {
//            ALAssetRepresentation *rep = [asset defaultRepresentation];
//            
//            //NSLog(@"%@",[[rep url] absoluteString]);
//            
//            Byte *buffer = (Byte *)malloc(rep.size);
//            NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:rep.size error:nil];
//            
//            self.nsdataGlobalData = [NSData dataWithBytesNoCopy:buffer length:buffered  freeWhenDone:YES];
//            self.globalMetaData = [rep metadata];
//            
//            Byte *byteTemp = (Byte *)[self.nsdataGlobalData bytes];
//            
//            for(uintCnt = 0; uintCnt < nsdataGlobalData.length; uintCnt+=2)
//                {
//                if(byteTemp[uintCnt]==0xFF && byteTemp[uintCnt+1]==0xE6)
//                    {
//                    uintCnt +=2;
//                    len = byteTemp[uintCnt]*0x100+byteTemp[uintCnt+1];
//                    //NSLog(@"%lX",len);
//                    break;
//                    }
//                }
//            
//            if(uintCnt < nsdataGlobalData.length)
//                {
//                if(byteTemp[uintCnt+38]==0x0)
//                    {
//                    uitextviewCommentShow.text = [[NSString alloc] initWithData:[self.nsdataGlobalData subdataWithRange:NSMakeRange(uintCnt+2, len-16)] encoding:NSUTF8StringEncoding];
//                    NSLog(@"%@",uitextviewCommentShow.text);
//                    }
//                else
//                    {
//                    self.haveEncoded = YES;
//                    uitextviewCommentShow.text = @"請解密";
//                    }
//                }
//            else
//                uitextviewCommentShow.text = @"";
//            
//            self.image = [UIImage imageWithData:self.nsdataGlobalData];
//            }
//            failureBlock:^(NSError *error)
//                {
//                NSLog(@"Error : %@",[error localizedDescription]);
//                }];
//        
//        //self.image = shrunkenImage;
//    else if ([nsstringLastChosenMediaType isEqualToString:(NSString *)kUTTypeMovie])
//        {
//        self.nsurlMovieURL = [info objectForKey:UIImagePickerControllerMediaURL];
//        }

//    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentDirectory = [path objectAtIndex:0];
//    NSLog(@"%@",documentDirectory);
    
//    [picker dismissViewControllerAnimated:YES completion:nil];
//}

//----------------------------------------------------------------------------------------

//- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
//{
//    if (uiimageImage == nil)
//        return ;
    
//    [picker dismissViewControllerAnimated:YES completion:nil];
//}

//----------------------------------------------------------------------------------------

//- (void)getMediaFromSource:(UIImagePickerControllerSourceType)sourceType
//{
//    NSArray *nsarrayMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:sourceType];
//    
//    if ([UIImagePickerController isSourceTypeAvailable:sourceType] && [nsarrayMediaTypes count] > 0)
//        {
//        //NSArray *nsarrayMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:sourceType];
//        
//        UIImagePickerController *uiimagepickercontrollerPicker = [[UIImagePickerController alloc] init];
//        uiimagepickercontrollerPicker.mediaTypes = nsarrayMediaTypes;
//        uiimagepickercontrollerPicker.delegate = self;
//        //uiimagepickercontrollerPicker.allowsEditing = NO;
//        uiimagepickercontrollerPicker.sourceType = sourceType;
//        [self presentViewController:uiimagepickercontrollerPicker animated:NO completion:nil];
//        }
//    else
//        {
//        UIAlertView *uialertviewAlert = [[UIAlertView alloc]
//                                initWithTitle:@"Error accessing media"
//                                message:@"Device doesn't support that media source."
//                                delegate:nil
//                                cancelButtonTitle:@"Drat!"
//                                otherButtonTitles:nil, nil];
//        [uialertviewAlert show];
//        }
//}

//----------------------------------------------------------------------------------------

//- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
//{
    
//}

//----------------------------------------------------------------------------------------

//    if ([textField isEqual:uitextviewCommentTextView])
//        {
//        nsstringTemp = [[uitextviewCommentTextView text] stringByReplacingCharactersInRange:range withString:string];
//        nsdataTemp = [nsstringTemp dataUsingEncoding:NSUTF8StringEncoding];
//        
//        //NSLog(@"%@",@"comment have been execute");
//        
//        if (nsdataTemp.length < commentTextLimit)
//            return YES;
//        else
//            return NO;
//        }
//    else

//----------------------------------------------------------------------------------------

//- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
//{
//    NSData *nsdataTemp = [uitextviewCommentTextView.text dataUsingEncoding:NSUTF8StringEncoding];
//    NSLog(@"%lu",nsdataTemp.length);
//    return YES;
//}

//#pragma UITextView EditChanged Method
//- (void)textviewEditChanged:(NSNotification *)obj
//{
//    UITextView *uitextviewTemp = (UITextView *)obj.object;
//    NSString *nsstringTextViewText = uitextviewTemp.text;
//    NSString *nsstringLang = [[UIApplication sharedApplication] textInputMode].primaryLanguage;
//    NSLog(@"%@",nsstringLang);
//    if ([nsstringLang isEqualToString:@"zh-Hans"])
//        {
//        UITextRange *uitextrangeSelectRange = [uitextviewTemp markedTextRange];
//        
//        UITextPosition *uitextpositionPosition = [uitextviewTemp positionFromPosition:uitextrangeSelectRange.start offset:0];
//        if (!uitextpositionPosition)
//            {
//            NSData *nsdataTemp = [nsstringTextViewText dataUsingEncoding:NSUTF8StringEncoding];
//            if (nsdataTemp.length > commentTextLimit)
//                NSLog(@"%lu",nsdataTemp.length);
//                uitextviewTemp.text = [nsstringTextViewText substringToIndex:nsstringTextViewText.length];
//            }
//        }
//    else
//        {
//        if(nsstringTextViewText.length > commentTextLimit)
//            uitextviewTemp.text = [nsstringTextViewText substringToIndex:commentTextLimit];
//        }
//}

//----------------------------------------------------------------------------------------

//                        [self performSelectorOnMainThread:@selector(choseWhetherConnetToPhotoComment) withObject:nil waitUntilDone:YES];

//----------------------------------------------------------------------------------------

//            //宣告PHAssetCollection、PHObjectPlaceholder、PHFetchOptions變數
//            __block PHAssetCollection *phassetcollectionAlubm;
//            PHFetchOptions *phfetchoptionsOption = [[PHFetchOptions alloc] init];
//                
//            //設定希望抓取到的相簿的名字
//            phfetchoptionsOption.predicate = [NSPredicate predicateWithFormat:@"title = %@",@"Photo Comment"];
//                
//            //抓取相簿並把它放入PHAssetCollection
//            phassetcollectionAlubm = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:phfetchoptionsOption].firstObject;
//                
//            //如果沒有Photo Comment這個相簿就建立一個
//            if (!phassetcollectionAlubm)
//                {
//                [[PHPhotoLibrary sharedPhotoLibrary]
//                    performChanges:^
//                        {
//                        //創立相簿
//                        PHAssetCollectionChangeRequest *phassetcollectionchangerequestCreate = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:@"Photo Comment"];
//                        phobjectplaceholderPlaceholder = [phassetcollectionchangerequestCreate placeholderForCreatedAssetCollection];
//                        }
//                    completionHandler:^(BOOL success, NSError * _Nullable error)
//                        {
//                        if (success)
//                            {
//                            //再找一次相簿
//                            PHFetchResult *phfetchresultCollection = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[phobjectplaceholderPlaceholder.localIdentifier] options:nil];
//                            phassetcollectionAlubm = phfetchresultCollection.firstObject;
//                                
//                            //建立一張有註解的照片並將他連結到Photo Comment相簿裡
//                            [[PHPhotoLibrary sharedPhotoLibrary]
//                                performChanges:^
//                                    {
//                                    PHAssetChangeRequest *phassetchangerequestCreate =[PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:[NSURL URLWithString:fileName]];
//                                    phobjectplaceholderPlaceholder = [phassetchangerequestCreate placeholderForCreatedAsset];
//                                    
//                                    PHAssetCollectionChangeRequest *phassetcollectionchangerequestChange = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:phassetcollectionAlubm];
//                                    [phassetcollectionchangerequestChange addAssets:@[phobjectplaceholderPlaceholder]];
//                                    }
//                                completionHandler:^(BOOL success, NSError *error)
//                                    {
//                                    NSLog(@"success : %@",@(success));
//                                    NSLog(@"error : %@",error);
//                                    }];
//                            }
//                        else
//                            NSLog(@"%@",error);
//                        }];
//                }
//            else
//                {
                //建立一張有註解的照片並將他連結到Photo Comment相簿裡
//                [[PHPhotoLibrary sharedPhotoLibrary]
//                    performChanges:^
//                        {
//                        PHAssetChangeRequest *phassetchangerequestCreate =[PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:[NSURL URLWithString:fileName]];
//                        phobjectplaceholderPlaceholder = [phassetchangerequestCreate placeholderForCreatedAsset];
//                        
//                        PHAssetCollectionChangeRequest *phassetcollectionchangerequestChange = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:phassetcollectionAlubm];
//                        [phassetcollectionchangerequestChange addAssets:@[phobjectplaceholderPlaceholder]];
//                        }
//                    completionHandler:^(BOOL success, NSError *error)
//                        {
//                        NSLog(@"success : %@",@(success));
//                        NSLog(@"error : %@",error);
//                        }];
//                }

//----------------------------------------------------------------------------------------

//@implementation CIImage (Convenience)
//- (NSData *)aapl_jpegRepresentationWithCompressionQuality:(CGFloat)compressionQuality {
//	static CIContext *ciContext = nil;
//	if (!ciContext) {
//		EAGLContext *eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
//		ciContext = [CIContext contextWithEAGLContext:eaglContext];
//	}
//	CGImageRef outputImageRef = [ciContext createCGImage:self fromRect:[self extent]];
//	UIImage *uiImage = [[UIImage alloc] initWithCGImage:outputImageRef scale:1.0 orientation:UIImageOrientationUp];
//	if (outputImageRef) {
//		CGImageRelease(outputImageRef);
//	}
//	NSData *jpegRepresentation = UIImageJPEGRepresentation(uiImage, compressionQuality);
//	return jpegRepresentation;
//}
//@end

//----------------------------------------------------------------------------------------

//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
//    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

//----------------------------------------------------------------------------------------

//#pragma mark- Keyboard Show Or Hide Methods
//
//- (void)keyboardWillShow:(NSNotification *)note
//{
//    NSDictionary *userInfo = note.userInfo;
//    NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
//    UIViewAnimationCurve curve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
//
//    CGRect keyboardFrameEnd = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
//    keyboardFrameEnd = [self.view convertRect:keyboardFrameEnd fromView:nil];

//    CGRect newRect = [self.uicontrolTest convertRect:self.uitextview1.frame toView:self.view];

//}

//----------------------------------------------------------------------------------------

//- (void)keyboardWillHide:(NSNotification *)note
//{
//    NSDictionary *userInfo = note.userInfo;
//    NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
//    UIViewAnimationCurve curve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
//
//    CGRect keyboardFrameEnd = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
//    keyboardFrameEnd = [self.view convertRect:keyboardFrameEnd fromView:nil];
//
//}

//----------------------------------------------------------------------------------------

//        if (!self.nsstringAlbumPath)
//            self.nsstringAlbumPath = [documentDirectory stringByAppendingPathComponent:@"Photo Comment"];
//        uint uintName = 0;
//        NSArray *nsarrayAssets = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.nsstringAlbumPath error:nil];
//
//        for (uintName = 0; uintName < nsarrayAssets.count; uintName++)
//            {
//            if (![nsarrayAssets[uintName] isEqualToString:[NSString stringWithFormat:@"%i.JPG",uintName]])
//                    break;
//            }
//            
//        [[NSFileManager defaultManager] createFileAtPath:[self.nsstringAlbumPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%i.JPG",uintName]] contents:nsdataGlobalData attributes:nil];
//            
//        self.nsstringAsset = [NSString stringWithFormat:@"%i.JPG",uintName];
//        self.phassetAsset = nil;
//        
//        NSLog(@"%@",self.nsstringAsset);
//        
//        [self.delegate createAsset:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.nsstringAlbumPath error:nil]];

//----------------------------------------------------------------------------------------

@end
