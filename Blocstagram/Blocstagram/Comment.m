//
//  Comment.m
//  Blocstagram
//
//  Created by Jack Li on 2/28/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import "Comment.h"
#import "User.h" // apparently needed for later

@implementation Comment

- (instancetype) initWithDictionary:(NSDictionary*)commentDictionary {
    self = [super init];
    if (self) {
        self.idNumber = commentDictionary[@"id"];
        self.text = commentDictionary[@"text"];
        self.from = [[User alloc] initWithDictionary:commentDictionary[@"from"]];
    }
    return self;
}

@end
