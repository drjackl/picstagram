//
//  LoginViewController.h
//  Blocstagram
//
//  Created by Jack Li on 3/1/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController

// all objects needing to be notified when access token obtained uses this (possibly random but constant) string
extern NSString* const LoginViewControllerDidGetAccessTokenNotification;

@end
