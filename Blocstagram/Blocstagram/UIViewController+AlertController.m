//
//  UIViewController+AlertController.m
//  Blocstagram
//
//  Created by Jack Li on 3/7/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import "UIViewController+AlertController.h"

@implementation UIViewController (AlertController)

//- (void) presentOKAlertWithError:(NSError*)error {
//    UIAlertController* alertVC = [UIAlertController alertControllerWithTitle:error.localizedDescription message:error.localizedRecoverySuggestion preferredStyle:UIAlertControllerStyleAlert];
//    [self addAlertActionAndPresentAlert:alertVC];
//}
//
//- (void) presentCameraPermissionDeniedAlert {
//    UIAlertController* alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Camera Permission Denied", @"camera permission denied title") message:NSLocalizedString(@"This app doesn't have permission to use the camera; please update your privacy settings.", @"camera premission denied recovery suggestion") preferredStyle:UIAlertControllerStyleAlert];
//    [self addAlertActionAndPresentAlert:alertVC];
//}
//
//- (void) addAlertActionAndPresentAlert:(UIAlertController*)alertVC {
//    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK button") style:UIAlertActionStyleCancel handler:^(UIAlertAction*_Nonnull action) {
//        [self.delegate cameraViewController:self didCompleteWithImage:nil];
//    }]]; // end alertVC addAction:
//    
//    [self presentViewController:self animated:YES completion:nil];
//}

- (void) shareItemsWithActivityController:(NSArray *)itemsArray {
    if (itemsArray.count > 0) {
        UIActivityViewController* activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsArray applicationActivities:nil];
        [self presentViewController:activityVC animated:YES completion:nil];
    }
}

@end
