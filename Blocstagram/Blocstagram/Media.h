//
//  Media.h
//  Blocstagram
//
//  Created by Jack Li on 2/28/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

//#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h> // includes all Foundation objects NSObject, NSString, NSURL
#import "LikeButton.h" // so can get LikeState and all possible states

//typedef enum {
//    MediaDownloadStateNeedsImage,
//    MediaDownloadStateDownloadInProgress,
//    MediaDownloadStateNonRecoverableError,
//    MediaDownloadStateHasImage
//} MediaDownloadState;

// better performance (according to NSHipster)
typedef NS_ENUM(NSInteger, MediaDownloadState) {
    MediaDownloadStateNeedsImage = 0, // this is default value since 0
    MediaDownloadStateDownloadInProgress = 1,
    MediaDownloadStateNonRecoverableError = 2,
    MediaDownloadStateHasImage = 3
};

@class User; // forward declare as generally bad to #import custom classes in .h

@interface Media : NSObject <NSCoding> // 1/2 of archiving (also NSKeyedArchiver)

@property (nonatomic) NSString* idNumber;
@property (nonatomic) User* user;
@property (nonatomic) NSURL* mediaURL;
@property (nonatomic) UIImage* image; // needs UIKit

@property (nonatomic) MediaDownloadState downloadState; // should default to assign

@property (nonatomic) NSString* caption;
@property (nonatomic) NSArray* comments;


@property (nonatomic) LikeState likeState; // keeps media item's like state

@property (nonatomic) int likeCount;


- (instancetype) initWithDictionary:(NSDictionary*)mediaDictionary;

- (void) shareGivenViewController:(UIViewController*)viewController;

@end
