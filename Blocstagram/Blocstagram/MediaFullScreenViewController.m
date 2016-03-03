//
//  MediaFullScreenViewController.m
//  Blocstagram
//
//  Created by Jack Li on 3/2/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import "MediaFullScreenViewController.h"
#import "Media.h" // can't rely on @class declaration in .h

@interface MediaFullScreenViewController () <UIScrollViewDelegate> // protocol

@property (nonatomic) Media* media;

// for letting user dismiss VC by tapping out and alternative zooming
@property (nonatomic) UITapGestureRecognizer* tap;
@property (nonatomic) UITapGestureRecognizer* doubleTap;

@property (nonatomic) UIButton* shareButton;

@end

@implementation MediaFullScreenViewController

// initializer simply stores media item
- (instancetype) initWithMedia:(Media*)media {
    self = [super init];
    if (self) {
        self.media = media;
    }
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    // a scroll view can handle zoom, panning and this feature will handle all that
    self.scrollView = [UIScrollView new];
    self.scrollView.delegate = self;
    self.scrollView.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.scrollView];
    
    // after create scroll view, create image view
    self.imageView = [UIImageView new];
    self.imageView.image = self.media.image; // requires importing Media.h
    
    [self.scrollView addSubview:self.imageView];
    
    // scroll view's contentSize is new, just pass in its size
    self.scrollView.contentSize = self.media.image.size;
    
    
    // add share button
    UIButton* shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [shareButton setTitle:NSLocalizedString(@"Share", @"Share this media item") forState:UIControlStateNormal];
    [shareButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [shareButton setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.5]];
    shareButton.enabled = YES;
    [shareButton addTarget:self action:@selector(shareThisItem) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:shareButton];
    self.shareButton = shareButton;
    
    
    // initialize extra tap features
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapFired:)];
    
    self.doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapFired:)];
    self.doubleTap.numberOfTapsRequired = 2; // allows requiring > 1 tap to fire
    
    // allows a recognizer (doubleTap) to wait for another to fail before it succeeds
    // aka require this recognizer to fail before passed in recognizer succeeds
    [self.tap requireGestureRecognizerToFail:self.doubleTap];
    
    [self.scrollView addGestureRecognizer:self.tap];
    [self.scrollView addGestureRecognizer:self.doubleTap];
}

- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    // share button: account for putting it on top right
    //CGFloat buttonHeight = CGRectGetHeight(self.shareButton.bounds); // can't do this cuz height is not given yet
    CGFloat buttonHeight = 30;
    
    
    // sets scroll view to take up all of view's space
    self.scrollView.frame = self.view.bounds;
    
//    // calculating to allow for button on top
//    self.scrollView.frame = CGRectMake(0, buttonHeight, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds)-buttonHeight);
    
    // 2 ratios: scroll view w : image w and scroll view h : image h
    CGSize scrollViewFrameSize = self.scrollView.frame.size;
    CGSize scrollViewContentSize = self.scrollView.contentSize;
    
    // smaller of two ratios set as min so can't pinch too small
    CGFloat scaleWidth = scrollViewFrameSize.width / scrollViewContentSize.width;
    CGFloat scaleHeight = scrollViewFrameSize.height / scrollViewContentSize.width;
    CGFloat minScale = MIN(scaleWidth, scaleHeight);
    
    self.scrollView.minimumZoomScale = minScale;
    self.scrollView.maximumZoomScale = 1;
    
    
    // share button
    CGFloat viewMaxX = CGRectGetMaxX(self.view.bounds);
    CGFloat buttonWidth = 70; // CGRectGetWidth(self.shareButton.bounds); // can't do this as there's no button size yet
    CGFloat topMargin = 20;
    self.shareButton.frame = CGRectMake(viewMaxX-buttonWidth, topMargin, buttonWidth, buttonHeight);
}

// ensures image starts out centered
- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self centerScrollView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) shareThisItem {
    [self.media shareGivenViewController:self];
}

// if zoomed out all the way, will center image in middle with equal margin space
- (void) centerScrollView {
    [self.imageView sizeToFit];
    
    CGSize boundsSize = self.scrollView.bounds.size; // scroll bounds size
    CGRect contentsFrame = self.imageView.frame; // image frame
    
    if (contentsFrame.size.width < boundsSize.width) {
        contentsFrame.origin.x = (boundsSize.width - CGRectGetWidth(contentsFrame)) / 2;
    } else { // two widths should be the same, so image should start at left
        contentsFrame.origin.x = 0;
    }
    
    if (contentsFrame.size.height < boundsSize.height) {
        contentsFrame.origin.y = (boundsSize.height - CGRectGetHeight(contentsFrame)) / 2;
    } else { // two heights should be the same, so image should start at top
        contentsFrame.origin.y = 0;
    }
    
    self.imageView.frame = contentsFrame; // once location/origin set, set frame
}

#pragma mark - Gesture Recognizers

// single tap dismisses this VC
- (void) tapFired:(UITapGestureRecognizer*)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

// double tap adjusts zoom level
- (void) doubleTapFired:(UITapGestureRecognizer*)sender {
    // zoom in if at most zoomed out
    if (self.scrollView.zoomScale == self.scrollView.minimumZoomScale) {
        CGPoint locationPoint = [sender locationInView:self.imageView];
        
        CGSize scrollViewSize = self.scrollView.bounds.size;
        
        CGFloat width = scrollViewSize.width / self.scrollView.maximumZoomScale;
        CGFloat height = scrollViewSize.height / self.scrollView.maximumZoomScale;
        CGFloat x = locationPoint.x - width/2;
        CGFloat y = locationPoint.y - height/2;
        
        [self.scrollView zoomToRect:CGRectMake(x, y, width, height) animated:YES];
    } else { // zoom out to minimum scale
        [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:YES];
    }
}

#pragma mark - UIScrollViewDelegate

// tells scroll view which view to zoom in and out on
- (UIView*) viewForZoomingInScrollView:(UIScrollView*)scrollView {
    return self.imageView;
}

// called when user changes zoom level
- (void) scrollViewDidZoom:(UIScrollView*)scrollView {
    [self centerScrollView];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
