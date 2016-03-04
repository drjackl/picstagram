//
//  Media.m
//  Blocstagram
//
//  Created by Jack Li on 2/28/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import "Media.h"
#import "User.h" // apparently needed for later (way before chkpt 34)
#import "Comment.h"

@implementation Media

// interesting how image is not initially set here
- (instancetype) initWithDictionary:(NSDictionary*)mediaDictionary {
    self = [super init];
    if (self) {
        self.idNumber = mediaDictionary[@"id"];
        self.user = [[User alloc] initWithDictionary:mediaDictionary[@"user"]];
        
        // JSON gives a few rez options like for thumbnails; just use std_rez
        NSString* standardResolutionImageURLString = mediaDictionary[@"images"][@"standard_resolution"][@"url"];
        NSURL* standardResolutionImageURL = [NSURL URLWithString:standardResolutionImageURLString];
        if (standardResolutionImageURL) {
            self.mediaURL = standardResolutionImageURL;
            self.downloadState = MediaDownloadStateNeedsImage; // retry downloads
        } else { // needed in retry downloads
            self.downloadState = MediaDownloadStateNonRecoverableError;
        }
        
        // caption might be null if there's no caption (so may be an NSNull)
        NSDictionary* captionDictionary = mediaDictionary[@"caption"];
        if ([captionDictionary isKindOfClass:[NSDictionary class]]) {
            self.caption = captionDictionary[@"text"]; // crashes if cD is NSNull
        } else {
            self.caption = @"";
        }
        
        // iterate comments array, pull out dictionaries to pass to Comment to parse
        NSMutableArray* commentsArray = [NSMutableArray array];
        for (NSDictionary* commentDictionary in mediaDictionary[@"comments"][@"data"]) {
            Comment* comment = [[Comment alloc] initWithDictionary:commentDictionary];
            [commentsArray addObject:comment];
        }
        self.comments = commentsArray;
        
        
        // set like state based on whether user has already liked the image
        BOOL userHasLiked = [mediaDictionary[@"user_has_liked"] boolValue];
        self.likeState = userHasLiked ? LikeStateLiked : LikeStateNotLiked;
    }
    return self;
}

- (void) shareGivenViewController:(UIViewController*)viewController {
    NSMutableArray* itemsToShare = [NSMutableArray array];
    
    if (self.caption.length > 0) {
        [itemsToShare addObject:self.caption];
    }
    
    if (self.image) {
        [itemsToShare addObject:self.image];
    }
    
    if (itemsToShare.count > 0) {
        UIActivityViewController* activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:nil];
        [viewController presentViewController:activityVC animated:YES completion:nil];
    }

}


#pragma mark - NSCoding

- (void) encodeWithCoder:(NSCoder*)aCoder {
    [aCoder encodeObject:self.idNumber forKey:NSStringFromSelector(@selector(idNumber))];
    [aCoder encodeObject:self.user forKey:NSStringFromSelector(@selector(user))];
    [aCoder encodeObject:self.mediaURL forKey:NSStringFromSelector(@selector(mediaURL))];
    [aCoder encodeObject:self.image forKey:NSStringFromSelector(@selector(image))];
    [aCoder encodeObject:self.caption forKey:NSStringFromSelector(@selector(caption))];
    [aCoder encodeObject:self.comments forKey:NSStringFromSelector(@selector(comments))];
    
    // encode like state (note encodeInteger: not encodeObject:)
    [aCoder encodeInteger:self.likeState forKey:NSStringFromSelector(@selector(likeState))];
}

- (instancetype) initWithCoder:(NSCoder*)aDecoder {
    self = [super init];
    if (self) {
        self.idNumber = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(idNumber))];
        self.user = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(user))];
        self.mediaURL = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(mediaURL))];
        self.image = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(image))];
        
        // retry downloads: different way of determination, though other way ok too
        if (self.image) {
            self.downloadState = MediaDownloadStateHasImage;
        } else if (self.mediaURL) {
            self.downloadState = MediaDownloadStateNeedsImage;
        } else {
            self.downloadState = MediaDownloadStateNonRecoverableError;
        }
        
        self.caption = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(caption))];
        self.comments = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(comments))];
        
        
        // decode like state (also uses decodeIntegerForKey, not Object)
        self.likeState = [aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(likeState))];
    }
    return self;
}

@end
