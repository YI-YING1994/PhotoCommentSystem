//
//  GridViewCollectionViewController.m
//  PhotoCommentSystem
//
//  Created by CSIE on 2015/10/8.
//  Copyright © 2015年 CSIE. All rights reserved.
//

#import "GridViewCollectionViewController.h"

#import "GridViewCellCollectionViewCell.h"
#import "ViewController.h"

@import Photos;

//----------------------------------------------------------------------------------------

@implementation NSIndexSet (Convenience)

- (NSArray *)aapl_indexPathsFromIndexesWithSection:(NSUInteger)section
{
	NSMutableArray *nsmutablearrayIndexPaths = [NSMutableArray arrayWithCapacity:self.count];
	[self enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop)
        {
		[nsmutablearrayIndexPaths addObject:[NSIndexPath indexPathForItem:idx inSection:section]];
        }];
	return nsmutablearrayIndexPaths;
}

@end

//----------------------------------------------------------------------------------------

@implementation UICollectionView (Convenience)

- (NSArray *)aapl_indexPathsForElementsInRect:(CGRect)rect
    {
	NSArray *nsarrayAllLayoutAttributes = [self.collectionViewLayout layoutAttributesForElementsInRect:rect];
    
	if (nsarrayAllLayoutAttributes.count == 0)
        {
        return nil;
        }
	
    NSMutableArray *nsmutableArrayIndexPaths = [NSMutableArray arrayWithCapacity:nsarrayAllLayoutAttributes.count];
    
	for (UICollectionViewLayoutAttributes *layoutAttributes in nsarrayAllLayoutAttributes) {
		NSIndexPath *nsindexpathIndex = layoutAttributes.indexPath;
		[nsmutableArrayIndexPaths addObject:nsindexpathIndex];
	}
	return nsmutableArrayIndexPaths;
}

@end

//----------------------------------------------------------------------------------------

@interface GridViewCollectionViewController () <PHPhotoLibraryChangeObserver>

@property (strong) PHCachingImageManager *phcachingimagemanager;
@property CGRect cgrectPreviousPreheatRect;
@property BOOL boolHaveScrolled;

@end

//----------------------------------------------------------------------------------------

@implementation GridViewCollectionViewController

static NSString * const nsstringCellReuseIdentifier = @"Cell";
static CGSize cgsizeAssetGridThumbnailSize;

//----------------------------------------------------------------------------------------

- (void)viewDidLoad
{
    //Set Theme
    UIImage *uiimageBackground = nil;

    switch (_nsuintegerTheme)
        {
        case 0:
            uiimageBackground = [UIImage imageNamed:@"MAINPAGE_BACKGROUND.png"];
            [self.collectionView setBackgroundView:[[UIImageView alloc] initWithImage:uiimageBackground]];
            break;

        case 1:
            uiimageBackground = [UIImage imageNamed:@"MAINPAGE_BACKGROUND_White.png"];
            [self.collectionView setBackgroundView:[[UIImageView alloc] initWithImage:uiimageBackground]];
            break;

        default:
            break;
        }
    
}

//----------------------------------------------------------------------------------------

- (void)awakeFromNib
{
    [super awakeFromNib];
    //改變導覽列Back Button字型與大小，
    [self.navigationItem.backBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"DFWaWaTC-W5" size:17.0]} forState:UIControlStateNormal];
    
    _boolHaveScrolled = NO;
    self.phcachingimagemanager = [[PHCachingImageManager alloc] init];
    [self resetCachedAssets];
    
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

//----------------------------------------------------------------------------------------

- (void)dealloc
{
    _phfetchresultFetchAssets = nil;
    _nsarrayFetchAssets = nil;
    _nsstringAlbumPath = nil;
    _phcachingimagemanager = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

//----------------------------------------------------------------------------------------

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationItem.title = _nsstringAlbumName;
	CGFloat cgfloatScale = [UIScreen mainScreen].scale;
	CGSize cgsizeCellSize = ((UICollectionViewFlowLayout *)self.collectionViewLayout).itemSize;
	cgsizeAssetGridThumbnailSize = CGSizeMake(cgsizeCellSize.width * cgfloatScale, cgsizeCellSize.height * cgfloatScale);

}

//----------------------------------------------------------------------------------------

- (void)viewDidAppear:(BOOL)animated
{

    [super viewDidAppear:animated];
    [self updateCachedAssets];

}

//----------------------------------------------------------------------------------------

#pragma mark- UIViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *nsindexpathIndex = [self.collectionView indexPathForCell:sender];
    ViewController *viewcontroller = segue.destinationViewController;
    
    if (self.phfetchresultFetchAssets)
        {
        viewcontroller.phassetAsset = self.phfetchresultFetchAssets[nsindexpathIndex.item];
        viewcontroller.nsstringAlbumName = @"Camera Roll";
        }
    else
        {
        viewcontroller.nsstringAsset = self.nsarrayFetchAssets[nsindexpathIndex.item];
        viewcontroller.nsstringAlbumPath = self.nsstringAlbumPath;
        viewcontroller.nsstringAlbumName = _nsstringAlbumName;
        }
    viewcontroller.nsuintegerTheme = _nsuintegerTheme;
    viewcontroller.nsuintegerAssetNum = nsindexpathIndex.item;

    viewcontroller.delegate = self;
}

//----------------------------------------------------------------------------------------

#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    // Call might come on any background queue. Re-dispatch to the main queue to handle it.
    dispatch_async(dispatch_get_main_queue(), ^
        {
        
        // check if there are changes to the assets (insertions, deletions, updates)
        PHFetchResultChangeDetails *phfetchresultchangedetailsChange = [changeInstance changeDetailsForFetchResult:self.phfetchresultFetchAssets];
        
        if (phfetchresultchangedetailsChange)
            {
            
            // get the new fetch result
            self.phfetchresultFetchAssets = [phfetchresultchangedetailsChange fetchResultAfterChanges];
            
            UICollectionView *uicollectionView = self.collectionView;
            
//            if (![phfetchresultchangedetailsChange hasIncrementalChanges] || [phfetchresultchangedetailsChange hasMoves])
//                {
                // we need to reload all if the incremental diffs are not available
                [uicollectionView reloadData];
                
//                }
//            else
//                {
//                // if we have incremental diffs, tell the collection view to animate insertions and deletions
//                [uicollectionView
//                    performBatchUpdates:^
//                        {
//                        NSIndexSet *nsindexsetRemovedIndexes = [phfetchresultchangedetailsChange removedIndexes];
//                    
//                        if ([nsindexsetRemovedIndexes count] < self.phfetchresultFetchAssets.count)
//                            {
//                            [uicollectionView deleteItemsAtIndexPaths:[nsindexsetRemovedIndexes aapl_indexPathsFromIndexesWithSection:0]];
//                            }
//                        
//                        NSIndexSet *nsindexsetInsertedIndexes = [phfetchresultchangedetailsChange insertedIndexes];
//                    
//                        if ([nsindexsetInsertedIndexes count])
//                            {
//                            [uicollectionView insertItemsAtIndexPaths:[nsindexsetInsertedIndexes aapl_indexPathsFromIndexesWithSection:0]];
//                            }
//                    
//                        NSIndexSet *nsindexsetChangedIndexes = [phfetchresultchangedetailsChange changedIndexes];
//                    
//                        if ([nsindexsetChangedIndexes count])
//                            {
//                            [uicollectionView reloadItemsAtIndexPaths:[nsindexsetChangedIndexes aapl_indexPathsFromIndexesWithSection:0]];
//                            }
//                        }
//                    completion:NULL];
//                }
            [self resetCachedAssets];
            }
        });
}

//----------------------------------------------------------------------------------------

#pragma mark- <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger nsintegerCount;
    
    if (self.phfetchresultFetchAssets)
        nsintegerCount = self.phfetchresultFetchAssets.count;
    else
        nsintegerCount = self.nsarrayFetchAssets.count;
    
    return nsintegerCount;
}

//----------------------------------------------------------------------------------------

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //由最新的照片顯示
    if (!self.boolHaveScrolled)
        {
        CGFloat cgfloatContentHeight = self.collectionView.contentSize.height;
        CGFloat cgfloatFrameHeight = self.collectionView.frame.size.height;
        CGFloat cgfloatToolBarHeight = self.navigationController.toolbar.frame.size.height;
    
        if (cgfloatContentHeight > cgfloatFrameHeight)
            {
            CGFloat cgfloatScroll = cgfloatContentHeight - cgfloatFrameHeight + cgfloatToolBarHeight;
            CGPoint cgpointPoint = CGPointMake(0, cgfloatScroll);
            [self.collectionView setContentOffset:cgpointPoint];
            }
        _boolHaveScrolled = YES;
        }

    GridViewCellCollectionViewCell *gridviewcellcollectionviewcell = [collectionView dequeueReusableCellWithReuseIdentifier:nsstringCellReuseIdentifier forIndexPath:indexPath];

    //Increment the cell's tag
    NSInteger nsintegerCurrentTag = gridviewcellcollectionviewcell.tag + 1;
    gridviewcellcollectionviewcell.tag = nsintegerCurrentTag;
    
    if (self.phfetchresultFetchAssets)
        {
        PHAsset *phassetAsset = self.phfetchresultFetchAssets[indexPath.item];
        
        [self.phcachingimagemanager
            requestImageForAsset:phassetAsset
            targetSize:cgsizeAssetGridThumbnailSize
            contentMode:PHImageContentModeAspectFill
            options:nil
            resultHandler:^(UIImage * result, NSDictionary * info)
                {
                // Only update the thumbnail if the cell tag hasn't changed. Otherwise, the cell has been re-used.
                if (gridviewcellcollectionviewcell.tag == nsintegerCurrentTag)
                    {
                    gridviewcellcollectionviewcell.uiimageThumbnailImage = result;
                    }
                }];
        }
    else
        {
        UIImage *uiimageImage = [UIImage imageWithContentsOfFile:[self.nsstringAlbumPath stringByAppendingPathComponent:self.nsarrayFetchAssets[indexPath.item]]];

        if (gridviewcellcollectionviewcell.tag == nsintegerCurrentTag)
            gridviewcellcollectionviewcell.uiimageThumbnailImage = uiimageImage;
        }
    
    return gridviewcellcollectionviewcell;
}

//----------------------------------------------------------------------------------------

#pragma mark- UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self updateCachedAssets];
}

//----------------------------------------------------------------------------------------

#pragma mark - Asset Caching

- (void)resetCachedAssets
{
    [self.phcachingimagemanager stopCachingImagesForAllAssets];
    self.cgrectPreviousPreheatRect = CGRectZero;
}

//----------------------------------------------------------------------------------------

- (void)updateCachedAssets
{
    BOOL boolIsViewVisible = [self isViewLoaded] && [[self view] window] != nil;
    if (!boolIsViewVisible) { return; }
    
    // The preheat window is twice the height of the visible rect
    CGRect cgrectPreheatRect = self.collectionView.bounds;
    cgrectPreheatRect = CGRectInset(cgrectPreheatRect, 0.0f, -0.5f * CGRectGetHeight(cgrectPreheatRect));
    
    // If scrolled by a "reasonable" amount...
    CGFloat cgfloatDelta = ABS(CGRectGetMidY(cgrectPreheatRect) - CGRectGetMidY(self.cgrectPreviousPreheatRect));
    
    if (cgfloatDelta > CGRectGetHeight(self.collectionView.bounds) / 3.0f)
        {
        // Compute the assets to start caching and to stop caching.
        NSMutableArray *addedIndexPaths = [NSMutableArray array];
        NSMutableArray *removedIndexPaths = [NSMutableArray array];
        
        [self computeDifferenceBetweenRect:self.cgrectPreviousPreheatRect
            andRect:cgrectPreheatRect
            removedHandler:^(CGRect removedRect)
                {
                NSArray *indexPaths = [self.collectionView aapl_indexPathsForElementsInRect:removedRect];
                [removedIndexPaths addObjectsFromArray:indexPaths];
                }
            addedHandler:^(CGRect addedRect)
                {
                NSArray *indexPaths = [self.collectionView aapl_indexPathsForElementsInRect:addedRect];
                [addedIndexPaths addObjectsFromArray:indexPaths];
                }];
        
        NSArray *assetsToStartCaching = [self assetsAtIndexPaths:addedIndexPaths];
        NSArray *assetsToStopCaching = [self assetsAtIndexPaths:removedIndexPaths];
        
        if (self.phfetchresultFetchAssets)
            {
            [self.phcachingimagemanager startCachingImagesForAssets:assetsToStartCaching
											targetSize:cgsizeAssetGridThumbnailSize
										   contentMode:PHImageContentModeAspectFill
											   options:nil];
            [self.phcachingimagemanager stopCachingImagesForAssets:assetsToStopCaching
										   targetSize:cgsizeAssetGridThumbnailSize
										  contentMode:PHImageContentModeAspectFill
											  options:nil];

            self.cgrectPreviousPreheatRect = cgrectPreheatRect;
            }
        }
}

//----------------------------------------------------------------------------------------

- (void)computeDifferenceBetweenRect:(CGRect)oldRect andRect:(CGRect)newRect removedHandler:(void (^)(CGRect removedRect))removedHandler addedHandler:(void (^)(CGRect addedRect))addedHandler
{
    if (CGRectIntersectsRect(newRect, oldRect)) {
        CGFloat oldMaxY = CGRectGetMaxY(oldRect);
        CGFloat oldMinY = CGRectGetMinY(oldRect);
        CGFloat newMaxY = CGRectGetMaxY(newRect);
        CGFloat newMinY = CGRectGetMinY(newRect);
        if (newMaxY > oldMaxY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY));
            addedHandler(rectToAdd);
        }
        if (oldMinY > newMinY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY));
            addedHandler(rectToAdd);
        }
        if (newMaxY < oldMaxY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY));
            removedHandler(rectToRemove);
        }
        if (oldMinY < newMinY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY));
            removedHandler(rectToRemove);
        }
    } else {
        addedHandler(newRect);
        removedHandler(oldRect);
    }
}

//----------------------------------------------------------------------------------------

- (NSArray *)assetsAtIndexPaths:(NSArray *)indexPaths
{
    if (indexPaths.count == 0) { return nil; }
    
    NSMutableArray *nsmutablearrayAssets = [NSMutableArray arrayWithCapacity:indexPaths.count];
    
    if (self.phfetchresultFetchAssets)
        {
        
        for (NSIndexPath *indexPath in indexPaths)
            {
            PHAsset *phassetAsset = self.phfetchresultFetchAssets[indexPath.item];
            [nsmutablearrayAssets addObject:phassetAsset];
            }
        }
    else
        {
        for (NSIndexPath *indexPath in indexPaths)
            {
            NSString *nsstringAsset = self.nsarrayFetchAssets[indexPath.item];
            [nsmutablearrayAssets addObject:nsstringAsset];
            }
        }
    
    return nsmutablearrayAssets;
}

//----------------------------------------------------------------------------------------

#pragma mark- Asset Change Delegate

- (void)haveChangeGridViewAsset:(NSArray *)FetchAssets AlbumName:(NSString *)AlbumName AlbumPath:(NSString *)AlbumPath
{
    self.nsarrayFetchAssets = FetchAssets;
    self.phfetchresultFetchAssets = nil;

    if (AlbumPath != nil && AlbumName != nil)
        {
        self.nsstringAlbumName = AlbumName;
        self.nsstringAlbumPath = AlbumPath;
        }
    
    [self.collectionView reloadData];
}

//----------------------------------------------------------------------------------------

- (void)haveChangeGridViewPhAsset:(PHFetchResult *)FetchAssets AlbumName:(NSString *)AlbumName
{
    self.phfetchresultFetchAssets = FetchAssets;
    self.nsstringAlbumName = AlbumName;
    self.nsarrayFetchAssets = nil;
    self.nsstringAlbumPath = nil;
    
    [self.collectionView reloadData];
}

//----------------------------------------------------------------------------------------

- (void)setGridViewBackgroundWithTheme:(NSUInteger)Theme
{
    _nsuintegerTheme = Theme;

    //Set Theme
    UIImage *uiimageBackground = nil;

    switch (_nsuintegerTheme)
        {
        case 0:
            uiimageBackground = [UIImage imageNamed:@"MAINPAGE_BACKGROUND.png"];
            [self.collectionView setBackgroundView:[[UIImageView alloc] initWithImage:uiimageBackground]];
            break;

        case 1:
            uiimageBackground = [UIImage imageNamed:@"MAINPAGE_BACKGROUND_White.png"];
            [self.collectionView setBackgroundView:[[UIImageView alloc] initWithImage:uiimageBackground]];
            break;

        default:
            [self.collectionView setBackgroundView:nil];
            break;
        }
    [self.delegate setRootViewBackgroundWithTheme:_nsuintegerTheme];
}

//----------------------------------------------------------------------------------------

//#pragma mark- Image Shrink Method
//
//- (UIImage *)shrinkImage:(UIImage *)image
//{
//    int kMaxResolution = 320;
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
//    CGFloat scale = [UIScreen mainScreen].scale;
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//    
//    CGContextRef context = CGBitmapContextCreate(NULL, size.width * scale, size.height * scale,
//        8, 0, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedFirst);
//    
//    CGContextDrawImage(context, CGRectMake(0, 0, size.width * scale, size.height * scale), original.CGImage);
//    CGImageRef shrunken = CGBitmapContextCreateImage(context);
//    UIImage *final = [UIImage imageWithCGImage:shrunken];
//    
//    NSLog(@"%ld",(long)final.imageOrientation);
//    
//    CGContextRelease(context);
//    CGImageRelease(shrunken);
    
//    return final;
//}

//----------------------------------------------------------------------------------------

@end
