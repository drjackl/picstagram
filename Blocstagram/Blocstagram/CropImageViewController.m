//
//  CropImageViewController.m
//  Blocstagram
//
//  Created by Jack Li on 3/5/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import "CropImageViewController.h"
#import "CropBox.h"
#import "Media.h"
#import "UIImage+ImageUtilities.h"

@interface CropImageViewController ()

@property (nonatomic) CropBox* cropBox;
@property (nonatomic) BOOL hasLoadedOnce;

// toolbars for translucency just like camera VC
@property (nonatomic) UIToolbar* topView;
@property (nonatomic) UIToolbar* bottomView;

@end

@implementation CropImageViewController

- (instancetype) initWithImage:(UIImage*)sourceImage {
    self = [super init];
    if (self) {
        self.media = [[Media alloc] init];
        self.media.image = sourceImage;
        
        self.cropBox = [CropBox new];
    }
    return self;
}

// superclass method takes care of most of the work, except ...
- (void) viewDidLoad {
    [super viewDidLoad];
    
     // so crop image doesn't overlap other controllers during transitions
    self.view.clipsToBounds = YES;
    
    // add crop box to hierarchy
    [self.view addSubview:self.cropBox];
    
    // create crop image button in nav bar
    UIBarButtonItem* rightButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Crop", @"Crop command") style:UIBarButtonItemStyleDone target:self action:@selector(cropPressed:)];
    
    self.navigationItem.title = NSLocalizedString(@"Crop Image", nil);
    self.navigationItem.rightBarButtonItem = rightButton;
    
    // disable UINavC's behavior of auto adjusting scroll view insets (we do manual)
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
    
    
    // adding toolbars for translucency
    self.topView = [UIToolbar new];
    self.bottomView = [UIToolbar new];
    UIColor* whiteBG = [UIColor colorWithWhite:1.0 alpha:0.15];
    self.topView.barTintColor = whiteBG;
    self.bottomView.barTintColor = whiteBG;
    self.topView.alpha = 0.5;
    self.bottomView.alpha = 0.5;
    
    [self.view addSubview:self.topView];
    [self.view addSubview:self.bottomView];
}

// only lay out views we've added, cropbox, and how it affects other views
- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect cropRect = CGRectZero;
    
    CGFloat edgeSize = MIN(CGRectGetWidth(self.view.frame),
                           CGRectGetHeight(self.view.frame));
    cropRect.size = CGSizeMake(edgeSize, edgeSize);
    
    CGSize size = self.view.frame.size;
    
    // size and center cropbox
    self.cropBox.frame = cropRect;
    self.cropBox.center = CGPointMake(size.width/2, size.height/2);
    
    // reduces scroll view's frame to be same as cropbox's
    self.scrollView.frame = self.cropBox.frame;
    
    // disable so user can still see image outside cropbox's
    self.scrollView.clipsToBounds = NO;
    
    // after changing scroll view's frame, recalculate the zoom
    [self recalculateZoomScale]; // refactored out superclass method!
    
    // additionally on first load, zoom pic all the way out (superclass opposite)
    if (self.hasLoadedOnce == NO) {
        self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
        self.hasLoadedOnce = YES;
    }
    
    
    // adding toolbars for translucency (CameraVC calculated differently, so ...)
    CGFloat length = CGRectGetWidth(self.view.bounds);
    
    CGFloat yOriginOfBottomView = CGRectGetMaxY(self.cropBox.frame);
    CGFloat yMaxOfSelfView = CGRectGetHeight(self.view.bounds);
    CGFloat heightOfBottomView = yMaxOfSelfView - yOriginOfBottomView;
    self.bottomView.frame = CGRectMake(0, yOriginOfBottomView, length, heightOfBottomView);
    
    CGFloat heightOfTopView = yMaxOfSelfView - heightOfBottomView - length;
    self.topView.frame = CGRectMake(0, 0, length, heightOfTopView);
}

// target method of crop button, create rect based on scroll view's location
- (void) cropPressed:(UIBarButtonItem*)sender {
    CGRect visibleRect;
    float scale = 1.0f / self.scrollView.zoomScale / self.media.image.scale;
    visibleRect.origin.x = self.scrollView.contentOffset.x * scale;
    visibleRect.origin.y = self.scrollView.contentOffset.y * scale;
    visibleRect.size.width = self.scrollView.bounds.size.width * scale;
    visibleRect.size.height = self.scrollView.bounds.size.height * scale;
    
    UIImage* scrollViewCrop = [self.media.image imageWithFixedOrientation];
    scrollViewCrop = [scrollViewCrop imageCroppedToRect:visibleRect];
    
    [self.delegate cropControllerFinishedWithImage:scrollViewCrop];
}

@end
