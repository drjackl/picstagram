//
//  UIViewController+AlertController.m
//  Blocstagram
//
//  Created by Jack Li on 3/7/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import "UIViewController+DialoguePresentation.h"

@implementation UIViewController (DialoguePresentation)

// Alert Controller
- (void) presentOKAlertWithError:(NSError*)error withCompletionHandler:(SetDelegateCompletionBlock)handler {
    [self okAlertWithTitle:error.localizedDescription message:error.localizedRecoverySuggestion completionHandler:handler];
}

- (void) presentCameraPermissionDeniedAlertWithCompletionHandler:(void (^)(UIAlertAction*_Nonnull))handler {
    [self okAlertWithTitle:NSLocalizedString(@"Camera Permission Denied", @"camera permission denied title") message:NSLocalizedString(@"This app doesn't have permission to use the camera; please update your privacy settings.", @"camera premission denied recovery suggestion") completionHandler:handler];
}

// designated custom alert
- (void) okAlertWithTitle:(NSString*)title message:(NSString*)message completionHandler:(SetDelegateCompletionBlock)handler {
    UIAlertController* alertVC = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK button") style:UIAlertActionStyleCancel handler:handler]];
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
