//
//  AppDelegate.m
//  Blocstagram
//
//  Created by Jack Li on 2/27/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import "AppDelegate.h"
//#import "ViewController.h" // default root VC to set
#import "ImagesTableViewController.h" // new root VC for a newsfeed (table)
#import "LoginViewController.h"
#import "DataSource.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // need to manually create and assign a VC as app's root VC
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor cyanColor];
    
//    // app logic initial: root VC for showing a newsfeed (table)
//    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[ImagesTableViewController alloc] init]];//[[ViewController alloc] init]];
    
    // app logic: at launch show login VC, register for *longname* notification, on notification post switch root VC
    [DataSource sharedInstance]; // create data source to receive accessToken nots
    
//    // show login VC (always show if no keychain)
//    UINavigationController* navVC = [[UINavigationController alloc] init];
//    LoginViewController* loginVC = [[LoginViewController alloc] init];
//    [navVC setViewControllers:@[loginVC] animated:YES];
//    
//    // switch to images table VC once access token obtained (forgot this!)
//    [[NSNotificationCenter defaultCenter] addObserverForName:LoginViewControllerDidGetAccessTokenNotification object:nil queue:nil usingBlock:^(NSNotification* _Nonnull note) {
//        ImagesTableViewController* imagesVC = [[ImagesTableViewController alloc] init];
//        [navVC setViewControllers:@[imagesVC] animated:YES];
//    }];
    
    // keychain: only show login VC if no access token, else skip to feed/table
    UINavigationController* navVC = [[UINavigationController alloc] init];
    if (![DataSource sharedInstance].accessToken) {
        LoginViewController* loginVC = [[LoginViewController alloc] init];
        [navVC setViewControllers:@[loginVC] animated:YES];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:LoginViewControllerDidGetAccessTokenNotification object:nil queue:nil usingBlock:^(NSNotification* _Nonnull note) {
            ImagesTableViewController* imagesVC = [[ImagesTableViewController alloc] init];
            [navVC setViewControllers:@[imagesVC] animated:YES];
        }];
    } else { // set the ImagesTableVC
        ImagesTableViewController* imagesVC = [[ImagesTableViewController alloc] init];
        [navVC setViewControllers:@[imagesVC] animated:YES];
    }
    
    self.window.rootViewController = navVC;
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
