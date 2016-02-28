//
//  DataSource.m
//  Blocstagram
//
//  Created by Jack Li on 2/28/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import "DataSource.h"
#import "User.h"
#import "Media.h"
#import "Comment.h"

@interface DataSource () // extension for ensuring mediaItems readonly to others

@property (nonatomic) NSMutableArray* mediaItems; // redefined without readonly, mutable for delete

@end

@implementation DataSource

+ (instancetype) sharedInstance {
    static dispatch_once_t once; // part of GCD dispatch snippet
    static id sharedInstance;
    dispatch_once(&once, ^{ // dispatch_once ensures a block only run the first time
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

+ (void) deleteItemAtIndex:(NSInteger)row {
    [[DataSource sharedInstance].mediaItems removeObjectAtIndex:row];
}

- (instancetype) init {
    self = [super init];
    if (self) {
        [self addRandomData]; // adds placeholder data
    }
    return self;
}

- (void) addRandomData {
    NSMutableArray* randomMediaItems = [NSMutableArray array];
    
    for (int i = 1; i <= 10; i++) {
        NSString* imageName = [NSString stringWithFormat:@"%d.jpg", i];
        UIImage* image = [UIImage imageNamed:imageName];
        
        if (image) {
            Media* media = [[Media alloc] init];
            media.user = [self randomUser];
            media.image = image;
            media.caption = [self randomSentence];
            
            NSUInteger commentCount = arc4random_uniform(10) + 2;
            NSMutableArray* randomComments = [NSMutableArray array];
            
            for (int i = 0; i <= commentCount; i++) {
                Comment* randomComment = [self randomComment];
                [randomComments addObject:randomComment];
            }
            
            media.comments = randomComments;
            
            [randomMediaItems addObject:media];
        }
    }
    
    self.mediaItems = randomMediaItems;
}

- (User*) randomUser {
    User* user = [[User alloc] init];
    
    user.userName = [self randomStringOfLength:arc4random_uniform(10) + 2];
    
    NSString* firstName = [self randomStringOfLength:arc4random_uniform(7) + 2];
    NSString* lastName = [self randomStringOfLength:arc4random_uniform(12) + 2];
    user.fullName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
    
    return user;
}

- (Comment*) randomComment {
    Comment* comment = [[Comment alloc] init];
    
    comment.from = [self randomUser];
    comment.text = [self randomSentence];
    
    return comment;
}

- (NSString*) randomSentence {
    NSUInteger wordCount = arc4random_uniform(20) + 2;
    
    NSMutableString* randomSentence = [[NSMutableString alloc] init];
    for (int i = 0; i <= wordCount; i++) {
        NSString* randomWord = [self randomStringOfLength:arc4random_uniform(12) + 2];
        [randomSentence appendFormat:@"%@ ", randomWord];
    }
    
    return randomSentence;
}

- (NSString*) randomStringOfLength:(NSUInteger) len { // not (NSUInteger len)
    NSString* alphabet = @"qwertyuiopasdfghjklzxcvbnm";
    
    NSMutableString* s = [NSMutableString string];
    for (NSUInteger i = 0U; i < len; i++) { // 0U
        u_int32_t r = arc4random_uniform((u_int32_t)alphabet.length);
        unichar c = [alphabet characterAtIndex:r]; // alphabet[r] doesn't work
        [s appendFormat:@"%C", c]; // %C
    }
    
    return [NSString stringWithString:s];
}

@end
