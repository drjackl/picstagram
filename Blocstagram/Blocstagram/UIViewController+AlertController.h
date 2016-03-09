//
//  UIViewController+AlertController.h
//  Blocstagram
//
//  Created by Jack Li on 3/7/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import <UIKit/UIKit.h>

// need to reference in .h here
typedef void (^SetDelegateCompletionBlock) (UIAlertAction*_Nonnull action); // if typedef, no nullable?


@interface UIViewController (AlertController)

- (void) presentOKAlertWithError:(nullable NSError*)error withCompletionHandler:(nullable SetDelegateCompletionBlock)handler;
- (void) presentCameraPermissionDeniedAlertWithCompletionHandler:(nullable void(^)(UIAlertAction*_Nonnull action))handler;

// making public for PostToInstagramVC
- (void) addAlertActionAndPresentAlert:(nonnull UIAlertController*)alertVC withCompletionHandler:(nullable void(^)(UIAlertAction*_Nonnull action))handler;


// weird nullable can't follow *, also weird that _Nullable can't be placed before NSArray
- (void) shareItemsWithActivityController:(NSArray*_Nullable)itemsArray;

@end
