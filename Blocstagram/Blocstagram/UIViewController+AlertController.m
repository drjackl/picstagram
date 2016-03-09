//
//  UIViewController+AlertController.m
//  Blocstagram
//
//  Created by Jack Li on 3/7/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import "UIViewController+AlertController.h"

@implementation UIViewController (AlertController)

- (void) presentOKAlertWithError:(NSError*)error withCompletionHandler:(nullable void(^)(UIAlertAction*_Nonnull action))handler {
    UIAlertController* alertVC = [UIAlertController alertControllerWithTitle:error.localizedDescription message:error.localizedRecoverySuggestion preferredStyle:UIAlertControllerStyleAlert];
    [self addAlertActionAndPresentAlert:alertVC withCompletionHandler:handler];
}

- (void) presentCameraPermissionDeniedAlertWithCompletionHandler:(SetDelegateCompletionBlock)handler; {
    UIAlertController* alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Camera Permission Denied", @"camera permission denied title") message:NSLocalizedString(@"This app doesn't have permission to use the camera; please update your privacy settings.", @"camera premission denied recovery suggestion") preferredStyle:UIAlertControllerStyleAlert];
    [self addAlertActionAndPresentAlert:alertVC withCompletionHandler:handler];
}


- (void) addAlertActionAndPresentAlert:(UIAlertController*)alertVC withCompletionHandler:(nullable void(^)(UIAlertAction*_Nonnull action))handler {
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK button") style:UIAlertActionStyleCancel handler:handler]]; // end alertVC addAction:
    
    // oops was sending self
    [self presentViewController:alertVC animated:YES completion:nil];
}

// Activity Controller
- (void) shareItemsWithActivityController:(NSArray *)itemsArray {
    if (itemsArray.count > 0) {
        UIActivityViewController* activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsArray applicationActivities:nil];
        [self presentViewController:activityVC animated:YES completion:nil];
    }
}

@end
