//
//  ImageLibraryViewController.m
//  Blocstagram
//
//  Created by Jack Li on 3/5/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import "ImageLibraryViewController.h"
#import <Photos/Photos.h>
#import "CropImageViewController.h"

@interface ImageLibraryViewController () <CropImageViewControllerDelegate>

// high performance array of image assets
@property (nonatomic) PHFetchResult* result;

@end


@implementation ImageLibraryViewController

// create given flow layout and assign an item size (updated later)
- (instancetype) init {
    // calls a different super
    UICollectionViewFlowLayout* layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(100, 100); // updated once know device screen
    return [super initWithCollectionViewLayout:layout];
}

// register default classes for cells, set background color, make cancel button
- (void) viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    UIImage* cancelImage = [UIImage imageNamed:@"x"];
    UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc] initWithImage:cancelImage style:UIBarButtonItemStyleDone target:self action:@selector(cancelPressed:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
}

// target action for cancel button
- (void) cancelPressed:(UIBarButtonItem*)sender {
    [self.delegate imageLibraryViewController:self didCompleteWithImage:nil];
}

// calculate size of each cell, fit as many as can each row, header 30 pts?
- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGFloat width = CGRectGetWidth(self.view.frame); // oops was getting height, which was giving margins!
    CGFloat minWidth = 80; // won't go below 100 points
    NSInteger divisor = width / minWidth;
    CGFloat cellSize = width / divisor - 1; // width / (width / minWidth) == minWidth?
    
    UICollectionViewFlowLayout* flowLayout = (UICollectionViewFlowLayout*)self.collectionViewLayout;
    flowLayout.itemSize = CGSizeMake(cellSize, cellSize);
    flowLayout.minimumInteritemSpacing = 1;
    flowLayout.minimumLineSpacing = 1; // originally, no (0) spacing between cells
}

// private method for loading assets
- (void) loadAssets {
    // PHFetchOptions has wide variety of ways to retrieve phot entities
    PHFetchOptions* options = [[PHFetchOptions alloc] init];
    
    // just only specifying they be sorted by createDate here though
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    
    // result of fetch assigned to self.result
    self.result = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:options];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusNotDetermined) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self loadAssets];
                    [self.collectionView reloadData];
                });
            } // end if authorizationStatus == Authorized
        }]; // end requestAuthorization
    } else if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
        [self loadAssets];
    } // end else if authorizationStatus == NotDetermined, then Authorized
}

#pragma mark - Collecion View Delegate

// no boilerplate for numberOfSectionsInCollectionView:


// number of items in each section is the count of PHFetchResult (number of images)
- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.result.count;
}

// given a section and row, produce a cell that's one image view that fills cell
// also uses same pattern when downloading images from IG: return cell asap and update it when image arrives
- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSInteger imageViewTag = 54321;
    
    UICollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    
    UIImageView* imageView = (UIImageView*)[cell.contentView viewWithTag:imageViewTag];
    
    if (!imageView) { // if no image view, then create
        imageView = [[UIImageView alloc] initWithFrame:cell.contentView.bounds];
        imageView.tag = imageViewTag;
        imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        [cell.contentView addSubview:imageView];
    }
    
    if (cell.tag != 0) {
        [[PHImageManager defaultManager] cancelImageRequest:(PHImageRequestID)cell.tag];
    }
    
    UICollectionViewFlowLayout* flowLayout = (UICollectionViewFlowLayout*)self.collectionViewLayout;
    PHAsset* asset = self.result[indexPath.row];
    
    cell.tag = [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:flowLayout.itemSize contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage*_Nullable result, NSDictionary*_Nullable info) {
        UICollectionViewCell* cellToUpdate = [collectionView cellForItemAtIndexPath:indexPath];
        
        if (cellToUpdate) {
            UIImageView* imageView = (UIImageView*)[cellToUpdate.contentView viewWithTag:imageViewTag];
            imageView.image = result;
        }
    }];
    
    return cell;
}

// when user taps thumbnail, get full rez and pass to crop controller
- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PHAsset* asset = self.result[indexPath.row];
    
    // like PHFetchOptions but specific to requesting one image cf image collection
    PHImageRequestOptions* options = [[PHImageRequestOptions alloc] init];
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.synchronous = YES;
    
    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage*_Nullable result, NSDictionary*_Nullable info) {
        // once image obtained, create crop VC and push to nav stack
        CropImageViewController* cropVC = [[CropImageViewController alloc] initWithImage:result];
        cropVC.delegate = self;
        [self.navigationController pushViewController:cropVC animated:YES];
    }];
}

// when user crops, inform delegate
- (void) cropControllerFinishedWithImage:(UIImage *)croppedImage {
    [self.delegate imageLibraryViewController:self didCompleteWithImage:croppedImage];
}

@end
