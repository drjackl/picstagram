//
//  UIViewController+AlertController.h
//  Blocstagram
//
//  Created by Jack Li on 3/7/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (AlertController)

//- (void) presentOKAlertWithError:(NSError*)error;
//- (void) presentCameraPermissionDeniedAlert;

- (void) shareItemsWithActivityController:(NSArray*)itemsArray;

@end
