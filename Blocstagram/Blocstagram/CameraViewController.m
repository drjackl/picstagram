//
//  CameraViewController.m
//  Blocstagram
//
//  Created by Jack Li on 3/5/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import "CameraViewController.h"
#import <AVFoundation/AVFoundation.h> // new powerful framework
#import "CameraToolbar.h" // toolbar we made
#import "UIImage+ImageUtilities.h" // for image rotations, cropping

@interface CameraViewController () <CameraToolbarDelegate>

@property (nonatomic) UIView* imagePreview; // shows user image from camera


// coordinates data from inputs (cams/mics) to outputs (movie files/still images)
@property (nonatomic) AVCaptureSession* session;

// a layer that displays video from camera
@property (nonatomic) AVCaptureVideoPreviewLayer* captureVideoPreviewLayer;

// captures still images from capture session's input (camera)
@property (nonatomic) AVCaptureStillImageOutput* stillImageOutput;


// lines are thin, white UIViews for 3x3 grid over photo capture area
@property (nonatomic) NSArray* horizontalLines;
@property (nonatomic) NSArray* verticalLines;

// usually for displaying small buttons, but here just using unique translucency
@property (nonatomic) UIToolbar* topView;
@property (nonatomic) UIToolbar* bottomView;

// the view we created (camera toolbar)
@property (nonatomic) CameraToolbar* cameraToolbar;

@end

@implementation CameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // 4 steps
    [self createViews];
    [self addViewsToViewHierarchy];
    [self setupImageCapture]; // big and unique
    [self createCancelButton];
}

- (void) createViews {
    self.imagePreview = [UIView new];
    self.topView = [UIToolbar new];
    self.bottomView = [UIToolbar new];
    self.cameraToolbar = [[CameraToolbar alloc] initWithImageNames:@[@"rotate", @"road"]];
    self.cameraToolbar.delegate = self;
    UIColor* whiteBG = [UIColor colorWithWhite:1.0 alpha:.15];
    self.topView.barTintColor = whiteBG; // like background color,
    self.bottomView.barTintColor = whiteBG; // but will be translucent
    self.topView.alpha = 0.5;
    self.bottomView.alpha = 0.5;
}

// order is important
- (void) addViewsToViewHierarchy {
    NSMutableArray* views = [@[self.imagePreview, self.topView, self.bottomView] mutableCopy];
    [views addObjectsFromArray:self.horizontalLines];
    [views addObjectsFromArray:self.verticalLines];
    [views addObject:self.cameraToolbar];
    
    for (UIView* view in views) {
        [self.view addSubview:view];
    }
}

// nil so override getters with some white views
- (NSArray*) horizontalLines {
    if (!_horizontalLines) {
        _horizontalLines = [self newArrayOfFourWhiteViews];
    }
    return _horizontalLines;
}

- (NSArray*) verticalLines {
    if (!_verticalLines) {
        _verticalLines = [self newArrayOfFourWhiteViews];
    }
    return _verticalLines;
}

- (NSArray*) newArrayOfFourWhiteViews {
    NSMutableArray* array = [NSMutableArray array];
    
    for (int i = 0; i < 4; i++) {
        UIView* view = [UIView new];
        view.backgroundColor = [UIColor whiteColor];
        [array addObject:view];
    }
    
    return array;
}

- (void) setupImageCapture {
    // #1 create a capture session which mediates between camera and output layer
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = AVCaptureSessionPresetHigh;
    
    // #2 create self.captureVideoPreviewLayer to display cam content
    self.captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    self.captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill; // like UIImageView's contentMode = UIViewContentModeScaleAspectFill
    self.captureVideoPreviewLayer.masksToBounds = YES;
    [self.imagePreview.layer addSublayer:self.captureVideoPreviewLayer]; // same as UIView's addSubview:
    
    // #3 request cam access permission from user (async cuz reply may not be immediate)
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) { // #4 user has accepted,
                // #5 create a device
                AVCaptureDevice* device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
                
                // #6 device provides data to AVCaptureSession via AVCDeviceInput
                NSError* error = nil;
                AVCaptureDeviceInput* input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
                if (!input) {
                    
                    // refactored out
                    [self presentOKAlertWithError:error];
                    
//                    UIAlertController* alertVC = [UIAlertController alertControllerWithTitle:error.localizedDescription message:error.localizedRecoverySuggestion preferredStyle:UIAlertControllerStyleAlert];
//                    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK button") style:UIAlertActionStyleCancel handler:^(UIAlertAction*_Nonnull action) {
//                        [self.delegate cameraViewController:self didCompleteWithImage:nil];
//                    }]]; // end alertVC addAction:
//                    
//                    [self presentViewController:self animated:YES completion:nil];
                } else { // input exists
                    // #7 add input to capture session
                    [self.session addInput:input];
                    
                    // create still image output
                    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
                    
                    // that saves JPEG files
                    self.stillImageOutput.outputSettings = @{AVVideoCodecKey: AVVideoCodecJPEG};
                    
                    [self.session addOutput:self.stillImageOutput];
                    
                    // start running the session
                    [self.session startRunning];
                } // end else input exists
            } else { // not granted
                
                // refactored out
                [self presentCameraPermissionDeniedAlert];
                
//                UIAlertController* alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Camera Permission Denied", @"camera permission denied title") message:NSLocalizedString(@"This app doesn't have permission to use the camera; please update your privacy settings.", @"camera premission denied recovery suggestion") preferredStyle:UIAlertControllerStyleAlert];
//                [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK button") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
//                    [self.delegate cameraViewController:self didCompleteWithImage:nil];
//                }]];
//                
//                [self presentViewController:alertVC animated:YES completion:nil];
            } // end else not granted
        }); // end dispatch_async(dispatch_get_main_queue()
    }]; // end requestAccessForMedia
}

- (void) createCancelButton {
    UIImage* cancelImage = [UIImage imageNamed:@"x"];
    UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc] initWithImage:cancelImage style:UIBarButtonItemStyleDone target:self action:@selector(cancelPressed:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
}

// target method for cancel button
- (void) cancelPressed:(UIBarButtonItem*)sender {
    [self.delegate cameraViewController:self didCompleteWithImage:nil];
}

// VC delegate
- (void) cameraButtonPressedOnToolbar:(CameraToolbar*)toolbar {
    AVCaptureConnection* videoConnection;
    
    // #8 find right connection object, which represents input-session-out
    for (AVCaptureConnection* connection in self.stillImageOutput.connections) {
        for (AVCaptureInputPort* port in connection.inputPorts) {
            if ([port.mediaType isEqual:AVMediaTypeVideo]) {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) break;
    }
    
    // #9 connection passed to output object and image returned in completion block
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError* error) {
        if (imageDataSampleBuffer) {
            // #10 image is a bufferRef but we know it's JPEG so convert to NSImg
            NSData* imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage* image = [UIImage imageWithData:imageData scale:[UIScreen mainScreen].scale];
            
            // #11 fix image's orientation and resize it (two methods in convenience method now)
            
            // #12 calculate center of white square's rect and pass for final crop
            UIView* leftLine = self.verticalLines.firstObject;
            UIView* rightLine = self.verticalLines.lastObject;
            UIView* topLine = self.horizontalLines.firstObject;
            UIView* bottomLine = self.horizontalLines.lastObject;
            
            // don't get this setup, especially last two
            CGRect gridRect = CGRectMake(CGRectGetMinX(leftLine.frame),
                                         CGRectGetMinY(topLine.frame),
                                         CGRectGetMaxX(rightLine.frame),
                                         CGRectGetMinY(bottomLine.frame));
            
            CGRect cropRect = gridRect;
            cropRect.origin.x = (CGRectGetMinX(gridRect) +
                                 (image.size.width - CGRectGetWidth(gridRect)) / 2);
            
            // where third cropping method used to be
            
            image = [image imageByScalingToSize:self.captureVideoPreviewLayer.bounds.size andCroppingWithRect:cropRect];
            
            // #13 once cropped, call delegate method
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate cameraViewController:self didCompleteWithImage:image];
            });
        } else { // no sample buffer
            dispatch_async(dispatch_get_main_queue(), ^{
                
                // refactored out
                [self presentOKAlertWithError:error];
                
//                UIAlertController* alertVC = [UIAlertController alertControllerWithTitle:error.localizedDescription message:error.localizedRecoverySuggestion preferredStyle:UIAlertControllerStyleAlert];
//                [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK button") style:UIAlertActionStyleCancel handler:^(UIAlertAction*_Nonnull action) {
//                    [self.delegate cameraViewController:self didCompleteWithImage:nil];
//                    
//                }]]; // end alertVC addAction
//                
//                [self presentViewController:alertVC animated:YES completion:nil];
            }); // end dispatch_async
        } // end else no sample buffer
    }]; // end self.stillImageOutput captureStillImage
}

- (void) presentOKAlertWithError:(NSError*)error {
    UIAlertController* alertVC = [UIAlertController alertControllerWithTitle:error.localizedDescription message:error.localizedRecoverySuggestion preferredStyle:UIAlertControllerStyleAlert];
    [self addAlertActionAndPresentAlert:alertVC];
}

- (void) presentCameraPermissionDeniedAlert {
    UIAlertController* alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Camera Permission Denied", @"camera permission denied title") message:NSLocalizedString(@"This app doesn't have permission to use the camera; please update your privacy settings.", @"camera premission denied recovery suggestion") preferredStyle:UIAlertControllerStyleAlert];
    [self addAlertActionAndPresentAlert:alertVC];
}

- (void) addAlertActionAndPresentAlert:(UIAlertController*)alertVC {
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK button") style:UIAlertActionStyleCancel handler:^(UIAlertAction*_Nonnull action) {
        [self.delegate cameraViewController:self didCompleteWithImage:nil];
    }]]; // end alertVC addAction:
    
    [self presentViewController:self animated:YES completion:nil];
}

#pragma mark - Layout

// layout controller's views: top & bottom cover photo, 3x3 even, imagePreview fills
- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    // 1. top and bottom view: top and bottom span view's width
    CGFloat width = CGRectGetWidth(self.view.bounds);
    
    // topView has height of 44, y of the status bar offest (?)
    self.topView.frame = CGRectMake(0, self.topLayoutGuide.length, width, 44);
    
    // + width? (not 44?) (width must be related to square)
    // bottom of topView + width (square so ==height)
    CGFloat yOriginOfBottomView = CGRectGetMaxY(self.topView.frame) + width;
    
    // view frame height (full screen?) - y position of bottom view?
    CGFloat heightOfBottomView = CGRectGetHeight(self.view.frame) - yOriginOfBottomView;
    self.bottomView.frame = CGRectMake(0, yOriginOfBottomView, width, heightOfBottomView);
    
    
    // 2. 3x3 white lines
    CGFloat thirdOfWidth = width / 3;
    
    for (int i = 0; i < 4; i++) {
        UIView* horizontalLine = self.horizontalLines[i];
        UIView* verticalLine = self.verticalLines[i];
        
        horizontalLine.frame = CGRectMake(0, (i * thirdOfWidth) + CGRectGetMaxY(self.topView.frame), width, 0.5);
        
        CGRect verticalFrame = CGRectMake(i * thirdOfWidth, CGRectGetMaxY(self.topView.frame), 0.5, width);
        
        if (i == 3) {
            verticalFrame.origin.x -= 0.5;
        }
        
        verticalLine.frame = verticalFrame;
    }
    
    // 3. these fill VC's primary view
    self.imagePreview.frame = self.view.bounds;
    self.captureVideoPreviewLayer.frame = self.imagePreview.bounds;
    
    CGFloat cameraToolbarHeight = 100;
    self.cameraToolbar.frame = CGRectMake(0, CGRectGetHeight(self.view.bounds)-cameraToolbarHeight, width, cameraToolbarHeight);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - CameraToolbarDelegate (responding to 3 button taps)

// left button flips between front and rear cameras
- (void) leftButtonPressedOnToolbar:(CameraToolbar *)toolbar {
    AVCaptureDeviceInput* currentCameraInput = self.session.inputs.firstObject;
    
    // array of all possible video devices is typically 2
    NSArray* devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    if (devices.count > 1) {
        NSUInteger currentIndex = [devices indexOfObject:currentCameraInput];
        NSUInteger newIndex = 0;
        
        // if currentIndex is 0, newIndex is 1 (to flip)
        if (currentIndex < devices.count - 1) {
            newIndex = currentIndex + 1;
        }
        
        AVCaptureDevice* newCamera = devices[newIndex];
        AVCaptureDeviceInput* newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:newCamera error:nil];
        
        if (newVideoInput) { // if able to create input, make nice dissolve effect
            UIView* fakeView = [self.imagePreview snapshotViewAfterScreenUpdates:YES];
            fakeView.frame = self.imagePreview.frame;
            [self.view insertSubview:fakeView aboveSubview:self.imagePreview];
            
            [self.session beginConfiguration];
            [self.session removeInput:currentCameraInput];
            [self.session addInput:newVideoInput];
            [self.session commitConfiguration];
            
            [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                fakeView.alpha = 0;
            } completion:^(BOOL finished) {
                [fakeView removeFromSuperview];
            }];
        }
    }
}

- (void) rightButtonPressedOnToolbar:(CameraToolbar *)toolbar {
    NSLog(@"Photo library button pressed");
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
