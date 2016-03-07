//
//  PostToInstagramViewController.m
//  Blocstagram
//
//  Created by Jack Li on 3/5/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import "PostToInstagramViewController.h"
#import "FilterCollectionViewCell.h" // for custom cell

@interface PostToInstagramViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UIDocumentInteractionControllerDelegate>

@property (nonatomic) UIImage* sourceImage; // stores img passed to init
@property (nonatomic) UIImageView* previewImageView; // display img w current filter

@property (nonatomic) NSOperationQueue* photoFilterOperationQueue; // filter ops
@property (nonatomic) UICollectionView* filterCollectionView; // available filters

@property (nonatomic) NSMutableArray* filterImages; // holds filtered imgs
@property (nonatomic) NSMutableArray* filterTitles; // holds filtered titles

@property (nonatomic) UIButton* sendButton; // big purple "send to IG" button
@property (nonatomic) UIBarButtonItem* sendBarButton; // for short iPhones

@property (nonatomic) UIDocumentInteractionController* documentController; // IG

@end


@implementation PostToInstagramViewController

- (instancetype) initWithImage:(UIImage*)sourceImage {
    self = [super init];
    if (self) {
        self.sourceImage = sourceImage;
        self.previewImageView = [[UIImageView alloc] initWithImage:self.sourceImage];
        self.photoFilterOperationQueue = [[NSOperationQueue alloc] init];
        
        UICollectionViewFlowLayout* flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.itemSize = CGSizeMake(44, 64);
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        flowLayout.minimumInteritemSpacing = 10;
        flowLayout.minimumLineSpacing = 10;
        
        self.filterCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        self.filterCollectionView.dataSource = self; // not needed for CollectionVC
        self.filterCollectionView.delegate = self; // but this is UIViewVC
        self.filterCollectionView.showsHorizontalScrollIndicator = NO; // aesthetic
        
        // first item in each array is the unfiltered image
        self.filterImages = [NSMutableArray arrayWithObject:sourceImage];
        self.filterTitles = [NSMutableArray arrayWithObject:NSLocalizedString(@"None", @"Label for when no filter is applied to a photo")];
        
        self.sendButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.sendButton.backgroundColor = [UIColor colorWithRed:0.345 green:0.318 blue:0.424 alpha:1]; // #58516C
        self.sendButton.layer.cornerRadius = 5;
        
        // add text to button
        [self.sendButton setAttributedTitle:[self sendAttributedString] forState:UIControlStateNormal];
        
        [self.sendButton addTarget:self action:@selector(sendButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        // shows on short iPhones in nav bar where there's no room for a button
        self.sendBarButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Send", @"Send button") style:UIBarButtonItemStyleDone target:self action:@selector(sendButtonPressed:)];
        
        [self addFiltersToQueue]; // adds filters to queue
    }
    return self;
}

- (NSAttributedString*) sendAttributedString {
    NSString* baseString = NSLocalizedString(@"SEND TO INSTAGRAM", @"send to Instagram button text");
    NSRange entireRange = NSMakeRange(0, baseString.length);
    
    NSMutableAttributedString* commentString = [[NSMutableAttributedString alloc] initWithString:baseString];
    
    // runtime error cuz wrote Helvetica-Neue-Bold
    [commentString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Bold" size:13] range:entireRange];
    [commentString addAttribute:NSKernAttributeName value:@1.3 range:entireRange];
    [commentString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.933 green:0.933 blue:0.933 alpha:1] range:entireRange];
    
    return commentString;
}

// configure the view, add subviews, decide which button to use
- (void) viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.previewImageView];
    [self.view addSubview:self.filterCollectionView];
    
    if (CGRectGetHeight(self.view.frame) > 500) {
        [self.view addSubview:self.sendButton];
    } else {
        self.navigationItem.rightBarButtonItem = self.sendBarButton;
    }
    
    [self.filterCollectionView registerClass:[UICollectionViewCell class]forCellWithReuseIdentifier:@"cell"]; // original cell
    //[self.filterCollectionView registerClass:[FilterCollectionViewCell class] forCellWithReuseIdentifier:@"filterCell"]; // custom cell
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.filterCollectionView.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.title = NSLocalizedString(@"Apply Filter", @"apply filter view title");
}

// if view height > 500, add sendButton which pushes view up from bottom
- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGFloat edgeSize = MIN(CGRectGetWidth(self.view.frame),
                           CGRectGetHeight(self.view.frame));
    
    // iPad: on iPhone6+, popover too small, so adjust this
    if (CGRectGetHeight(self.view.bounds) < edgeSize*1.5) {
        edgeSize /= 1.5;
    }
    
    self.previewImageView.frame = CGRectMake(0, self.topLayoutGuide.length, edgeSize, edgeSize);
    
    CGFloat buttonHeight = 50;
    CGFloat buffer = 10;
    
    CGFloat filterViewYOrigin = CGRectGetMaxY(self.previewImageView.frame)+buffer;
    CGFloat filterViewHeight;
    
    if (CGRectGetHeight(self.view.frame) > 500) {
        self.sendButton.frame = CGRectMake(buffer, CGRectGetHeight(self.view.frame) - buffer - buttonHeight, CGRectGetWidth(self.view.frame) - 2*buffer, buttonHeight);
        filterViewHeight = CGRectGetHeight(self.view.frame) - filterViewYOrigin - buffer - buffer - CGRectGetHeight(self.sendButton.frame);
    } else {
        filterViewHeight = CGRectGetHeight(self.view.frame) - CGRectGetMaxY(self.previewImageView.frame) - buffer - buffer;
    }
    
    self.filterCollectionView.frame = CGRectMake(0, filterViewYOrigin, CGRectGetWidth(self.view.frame), filterViewHeight);
    
    UICollectionViewFlowLayout* flowLayout = (UICollectionViewFlowLayout*)self.filterCollectionView.collectionViewLayout;
    flowLayout.itemSize = CGSizeMake(CGRectGetHeight(self.filterCollectionView.frame) - 20, CGRectGetHeight(self.filterCollectionView.frame));
}

// target method of send button: check IG installed and ask if want to write caption
- (void) sendButtonPressed:(id)sender { // could be more specific than id right?
    
    // iOS apps can define own URL schemes as IG does, so easy way to check install
    NSURL* instagramURL = [NSURL URLWithString:@"instagram://location?id=1"];
    
    UIAlertController* alertVC;
    
    if ([[UIApplication sharedApplication] canOpenURL:instagramURL]) {
        alertVC = [UIAlertController alertControllerWithTitle:@"" message:NSLocalizedString(@"Add a caption and send your image in the Instagram app.", @"send image instructions") preferredStyle:UIAlertControllerStyleAlert];
        
        [alertVC addTextFieldWithConfigurationHandler:^(UITextField*_Nonnull textField) {
            textField.placeholder = NSLocalizedString(@"Caption", @"Caption");
        }];
        
        // add send and cancel buttons
        [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"cancel button") style:UIAlertActionStyleCancel handler:nil]];
        [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Send", @"send button") style:UIAlertActionStyleDefault handler:^(UIAlertAction*_Nonnull action) {
            UITextField* textField = alertVC.textFields[0];
            [self sendImageToInstagramWithCaption:textField.text];
        }]];
    } else { // IG not installed
        alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"No Instagram App", "no instagram app installed title") message:NSLocalizedString(@"Install Instagram to use this feature", @"install instagram instructions") preferredStyle:UIAlertControllerStyleAlert];
        
        [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK button") style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:alertVC animated:YES completion:nil];
    }
}

// more complex than UIActivityVC cuz need to write to disk and send to IG
- (void) sendImageToInstagramWithCaption:(NSString*)caption {
    // convert image to NSData
    NSData* imageData = UIImageJPEGRepresentation(self.previewImageView.image, 0.9f);
    
    // create file in temporary directory
    NSURL* tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    NSURL* fileURL = [[tmpDirURL URLByAppendingPathComponent:@"picstabloc"] URLByAppendingPathExtension:@"igo"]; // "IG only"
    
    BOOL success = [imageData writeToURL:fileURL atomically:YES];
    
    if (!success) {
        UIAlertController* alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Couldn't save image", @"couldn't save image header") message:NSLocalizedString(@"Your cropped and filtered photo couldn't be saved. Make sure you have enough disk space and try again", @"couldn't save image message and recommendation") preferredStyle:UIAlertControllerStyleAlert];
        [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK button") style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alertVC animated:YES completion:nil];
        return;
    }
    
    // initialize and present controller with that file
    self.documentController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
    self.documentController.UTI = @"com.instagram.exclusivegram";
    self.documentController.delegate = self;
    
    if (caption.length > 0) {
        self.documentController.annotation = @{@"InstagramCaption": caption};
    }
    
    if (self.sendButton.superview) {
        [self.documentController presentOpenInMenuFromRect:self.sendButton.bounds inView:self.sendButton animated:YES];
    } else {
        [self.documentController presentOpenInMenuFromBarButtonItem:self.sendBarButton animated:YES];
    }
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (void) documentInteractionController:(UIDocumentInteractionController*)controller didEndSendingToApplication:(NSString*)application {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UICollectionView delegate and data source

// collection view will always have only one section, so nix numberOfSections:

// number of items will always be euqal to number of filtered images available
- (NSInteger) collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.filterImages.count;
}

// when cell loads, make sure there's image view and label on it, and set content
- (UICollectionViewCell*) collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath*)indexPath {
    UICollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath]; // original cell
    //FilterCollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"filterCell" forIndexPath:indexPath]; // custom cell
    
    // original cell creation/assignment
    static NSInteger imageViewTag = 1000;
    static NSInteger labelTag = 1001;
    
    UIImageView* thumbnail = (UIImageView*)[cell.contentView viewWithTag:imageViewTag];
    UILabel* label = (UILabel*)[cell.contentView viewWithTag:labelTag];
    
    UICollectionViewFlowLayout* flowLayout = (UICollectionViewFlowLayout*)self.filterCollectionView.collectionViewLayout;
    CGFloat thumbnailEdgeSize = flowLayout.itemSize.width;

    // frames of items based on flow layout's itemSize property (set earlier in viewWillLayoutSubviews
    
    if (!thumbnail) {
        thumbnail = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, thumbnailEdgeSize, thumbnailEdgeSize)];
        thumbnail.contentMode = UIViewContentModeScaleAspectFill;
        thumbnail.tag = imageViewTag;
        thumbnail.clipsToBounds = YES;
        
        [cell.contentView addSubview:thumbnail];
    }
    
    if (!label) {
        label = [[UILabel alloc] initWithFrame:CGRectMake(0, thumbnailEdgeSize, thumbnailEdgeSize, 20)];
        label.tag = labelTag;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:10];
        [cell.contentView addSubview:label];
    }
    
    thumbnail.image = self.filterImages[indexPath.row];
    label.text = self.filterTitles[indexPath.row];
    // end original cell creation/assignment
    
//    // custom cells
//    cell.image = self.filterImages[indexPath.row];
//    cell.title = self.filterTitles[indexPath.row];
    
    return cell;
}

// if user taps a cell, update preview image to show images with that filter
- (void) collectionView:(UICollectionView*)collectionView didSelectItemAtIndexPath:(NSIndexPath*)indexPath {
    self.previewImageView.image = self.filterImages[indexPath.row];
}

#pragma mark - Photo Filters

- (void) addCIImageToCollectionView:(CIImage*)CIImage withFilterTitle:(NSString*)filterTitle {
    
    // converts CIImage to UIImage; because CIImage not fully rendered, UIImage slow
    UIImage* image = [UIImage imageWithCIImage:CIImage scale:self.sourceImage.scale orientation:self.sourceImage.imageOrientation];
    
    if (image) {
        // decompress image
        UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
        [image drawAtPoint:CGPointZero]; // force UIImage to draw
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        // on main thread, adds completed UIImage and filter title to arrays
        dispatch_async(dispatch_get_main_queue(), ^{
            NSUInteger newIndex = self.filterImages.count;
            
            [self.filterImages addObject:image];
            [self.filterTitles addObject:filterTitle];
            
            // tells the collection view that a new item is available
            [self.filterCollectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:newIndex inSection:0]]];
        });
    }
}

- (void) addFiltersToQueue {
    CIImage* sourceCIImage = [CIImage imageWithCGImage:self.sourceImage.CGImage];
    
    // kaleidoscope filter
    [self.photoFilterOperationQueue addOperationWithBlock:^{
        CIFilter* kaleidoscopeFilter = [CIFilter filterWithName:@"CIKaleidoscope"];
        
        if (kaleidoscopeFilter) {
            [kaleidoscopeFilter setValue:sourceCIImage forKey:kCIInputImageKey];
            [self addCIImageToCollectionView:kaleidoscopeFilter.outputImage withFilterTitle:NSLocalizedString(@"Kaleidoscope", @"Kaleidoscope Filter")];
        }
    }];
    
    // sunbeam is a generator that just generates an image (like random) and is usually just passed in to another filter

    [self.photoFilterOperationQueue addOperationWithBlock:^{
        CIFilter* monochromeFilter = [CIFilter filterWithName:@"CIColorMonochrome"];
        CIFilter* twirlFilter = [CIFilter filterWithName:@"CITwirlDistortion"];
        
        if (monochromeFilter && twirlFilter) {
            [monochromeFilter setValue:sourceCIImage forKey:kCIInputImageKey];
            
            CIImage* resultImage = monochromeFilter.outputImage;
            
            [twirlFilter setValue:resultImage forKey:kCIInputImageKey];
            [twirlFilter setValue:[CIVector vectorWithCGPoint:CGPointMake(CGRectGetMidX(resultImage.extent), CGRectGetMidY(resultImage.extent))] forKey:@"inputCenter"];
            [twirlFilter setValue:@(CGRectGetWidth(resultImage.extent)/2) forKey:@"inputRadius"];
            
            resultImage = twirlFilter.outputImage;
            
            [self addCIImageToCollectionView:resultImage withFilterTitle:NSLocalizedString(@"MonoTwirl", @"Monochrome Twirl Filter")];
        }
    }];
    
    // noir filter
    [self.photoFilterOperationQueue addOperationWithBlock:^{ // runs eventually
        CIFilter* noirFilter = [CIFilter filterWithName:@"CIPhotoEffectNoir"];
        
        if (noirFilter) {
            [noirFilter setValue:sourceCIImage forKey:kCIInputImageKey];
            [self addCIImageToCollectionView:noirFilter.outputImage withFilterTitle:NSLocalizedString(@"Noir", @"Noir Filter")];
        }
    }];
    
    // boom filter
    [self.photoFilterOperationQueue addOperationWithBlock:^{
        CIFilter* boomFilter = [CIFilter filterWithName:@"CIPhotoEffectProcess"];
        
        if (boomFilter) {
            [boomFilter setValue:sourceCIImage forKey:kCIInputImageKey];
            [self addCIImageToCollectionView:boomFilter.outputImage withFilterTitle:NSLocalizedString(@"Boom", @"Boom Filter")];
        }
    }];

    // warm filter
    [self.photoFilterOperationQueue addOperationWithBlock:^{
        CIFilter* warmFilter = [CIFilter filterWithName:@"CIPhotoEffectTransfer"];
        
        if (warmFilter) {
            [warmFilter setValue:sourceCIImage forKey:kCIInputImageKey];
            [self addCIImageToCollectionView:warmFilter.outputImage withFilterTitle:NSLocalizedString(@"Warm", @"Warm Filter")];
        }
    }];
    
    // pixel filter
    [self.photoFilterOperationQueue addOperationWithBlock:^{
        CIFilter* pixelFilter = [CIFilter filterWithName:@"CIPixellate"];
        
        if (pixelFilter) {
            [pixelFilter setValue:sourceCIImage forKey:kCIInputImageKey];
            [self addCIImageToCollectionView:pixelFilter.outputImage withFilterTitle:NSLocalizedString(@"Pixel", @"Pixel Filter")];
        }
    }];
    
    // moody filter
    [self.photoFilterOperationQueue addOperationWithBlock:^{
        CIFilter* moodyFilter = [CIFilter filterWithName:@"CISRGBToneCurveToLinear"];
        
        if (moodyFilter) {
            [moodyFilter setValue:sourceCIImage forKey:kCIInputImageKey];
            [self addCIImageToCollectionView:moodyFilter.outputImage withFilterTitle:NSLocalizedString(@"Moody", @"Moody Filter")];
        }
    }];
    
    // drunk filter (more complex)
    [self.photoFilterOperationQueue addOperationWithBlock:^{
        CIFilter* drunkFilter = [CIFilter filterWithName:@"CIConvolution5x5"];
        CIFilter* tiltFilter = [CIFilter filterWithName:@"CIStraightenFilter"];
        
        if (drunkFilter) {
            [drunkFilter setValue:sourceCIImage forKey:kCIInputImageKey];
            
            // different: set another value aside from source image, inputWeights
            CIVector* drunkVector = [CIVector vectorWithString: // 5x5 m convolution
                                     @"[0.5 0 0 0 0 0 0 0 0 0.05 0 0 0 0 0 0 0 0 0 0 0.05 0 0 0 0.5]"];
            // also note, forKeyPath:
            [drunkFilter setValue:drunkVector forKeyPath:@"inputWeights"];
            
            CIImage* result = drunkFilter.outputImage;
            
            if (tiltFilter) {
                // note both of these are forKeyPath
                [tiltFilter setValue:result forKeyPath:kCIInputImageKey];
                [tiltFilter setValue:@0.2 forKeyPath:kCIInputAngleKey]; // radians
                result = tiltFilter.outputImage;
            }
            
            [self addCIImageToCollectionView:result withFilterTitle:NSLocalizedString(@"Drunk", @"Drunk Filter")];
        }
    }];
    
    // film filter (even more complex)
    [self.photoFilterOperationQueue addOperationWithBlock:^{
        // #1 make sepia tone version of source image
        CIFilter* sepiaFilter = [CIFilter filterWithName:@"CISepiaTone"];
        [sepiaFilter setValue:@1 forKey:kCIInputIntensityKey];
        [sepiaFilter setValue:sourceCIImage forKey:kCIInputImageKey];
        
        // #2 make random image (looks like color TV static
        CIFilter* randomFilter = [CIFilter filterWithName:@"CIRandomGenerator"];
        CIImage* randomImage = [CIFilter filterWithName:@"CIRandomGenerator"].outputImage;
        
        // #3 in otherImage, stretch image a bit horizontally, a lot vertically
        CIImage* otherRandomImage = [randomImage imageByApplyingTransform:CGAffineTransformMakeScale(1.5, 25.0)];
        
        // #4 create two filters, 1. extract white specks from randomImage
        CIFilter* whiteSpecks = [CIFilter filterWithName:@"CIColorMatrix" keysAndValues:kCIInputImageKey, randomImage,
                                 @"inputRVector", [CIVector vectorWithX:0.0 Y:1.0 Z:0.0 W:0.0],
                                 @"inputGVector", [CIVector vectorWithX:0.0 Y:1.0 Z:0.0 W:0.0],
                                 @"inputBVector", [CIVector vectorWithX:0.0 Y:1.0 Z:0.0 W:0.0],
                                 @"inputAVector", [CIVector vectorWithX:0.0 Y:0.01 Z:0.0 W:0.0],
                                 @"inputBiasVector", [CIVector vectorWithX:0.0 Y:0.0 Z:0.0 W:0.0],
                                 nil];
        
        // 2. extract vertical scratches from otherImage
        CIFilter* darkScratches = [CIFilter filterWithName:@"CIColorMatrix" keysAndValues:kCIInputImageKey, otherRandomImage,
                                   @"inputRVector", [CIVector vectorWithX:3.659 Y:0.0 Z:0.0 W:0.0],
                                   @"inputGVector", [CIVector vectorWithX:0.0 Y:0.0 Z:0.0 W:0.0],
                                   @"inputBVector", [CIVector vectorWithX:0.0 Y:0.0 Z:0.0 W:0.0],
                                   @"inputAVector", [CIVector vectorWithX:0.0 Y:0.0 Z:0.0 W:0.0],
                                   @"inputBiasVector", [CIVector vectorWithX:0.0 Y:1.0 Z:1.0 W:1.0],
                                   nil];
        
        // #5 create minComponent and composite which will combine the layers
        CIFilter* minimumComponent = [CIFilter filterWithName:@"CIMinimumComponent"];
        CIFilter* composite = [CIFilter filterWithName:@"CIMultiplyCompositing"];
        
        // #6 ensure all filters exist
        if (sepiaFilter && randomFilter && whiteSpecks && darkScratches && minimumComponent && composite) {
            // #7 apply sepia filter
            CIImage* sepiaImage = sepiaFilter.outputImage;
            
            // #8 generate whiteSpecksImage, crop to source img since size infinite
            CIImage* whiteSpecksImage = [whiteSpecks.outputImage imageByCroppingToRect:sourceCIImage.extent];
            
            // #9 create sepiaPlus by overlaying whiteSpecks on top of sepia-toned
            CIImage* sepiaPlusWhiteSpecksImage = [CIFilter filterWithName:@"CISourceOverCompositing" keysAndValues:
                                                  kCIInputImageKey, whiteSpecksImage,
                                                  kCIInputBackgroundImageKey, sepiaImage,
                                                  nil].outputImage;
            
            // #10 create darkScratches and add on top of whiteSpecs
            CIImage* darkScratchesImage = [darkScratches.outputImage imageByCroppingToRect:sourceCIImage.extent];
            
            [minimumComponent setValue:darkScratchesImage forKey:kCIInputImageKey];
            darkScratchesImage = minimumComponent.outputImage; // get whole thing
            
            [composite setValue:sepiaPlusWhiteSpecksImage forKey:kCIInputImageKey];
            [composite setValue:darkScratchesImage forKey:kCIInputBackgroundImageKey];
            
            [self addCIImageToCollectionView:composite.outputImage withFilterTitle:NSLocalizedString(@"Film", @"Film Filter")];
        }
    }]; // end film filter
}

@end
