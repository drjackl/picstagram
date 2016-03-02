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
    }
    return self;
}

@end
