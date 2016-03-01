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
#import "LoginViewController.h" // for IG login

@interface DataSource () { // extension for ensuring mediaItems readonly to others
    NSMutableArray* _mediaItems; // first step for KVC (could've also done method -mediaItems)
}

@property (nonatomic) NSMutableArray* mediaItems; // redefined without readonly, mutable for delete (mutable/readwrite must've been an assignment/branch not a checkpt/master)
@property (nonatomic) NSString* accessToken; // also redefined without readonly

// to ensure we don't fetch multiple times
@property (nonatomic) BOOL isRefreshing; // defaults to assign, I assume

@property (nonatomic) BOOL isLoadingOlderItems;

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

+ (NSString*) instagramClientID {
    return @"2d659bcd5033498e9b557d7d16242dca"; // from creating IG Client
}

//// initial deletion handling (no KVO)
//+ (void) deleteItemAtIndex:(NSInteger)row {
//    [[DataSource sharedInstance].mediaItems removeObjectAtIndex:row];
//}

// deleting item with KVO (else no objects like ImagesTableVC will get notification)
- (void) deleteMediaItem:(Media*)item {
    NSMutableArray* mutableArrayWithKVO = [self mutableArrayValueForKey:@"mediaItems"];
    [mutableArrayWithKVO removeObject:item];
}

//// moves media item to top with KVO (similar to delete with KVO)
//- (void) moveMediaItemToTop:(Media*)item {
//    NSMutableArray* mutableArrayWithKVO = [self mutableArrayValueForKey:@"mediaItems"];
//    [mutableArrayWithKVO removeObject:item];
//    [mutableArrayWithKVO insertObject:item atIndex:0];
//}

- (instancetype) init {
    self = [super init];
    if (self) {
        //[self addRandomData]; // adds placeholder data
        [self registerForAccessTokenNotification]; // register and respond to notification
    }
    return self;
}

- (void) registerForAccessTokenNotification {
    // block runs after login VC posts *long name* notification
    [[NSNotificationCenter defaultCenter] addObserverForName:LoginViewControllerDidGetAccessTokenNotification object:nil queue:nil usingBlock:^(NSNotification* _Nonnull note) {
        self.accessToken = note.object;
    }];
    
    // normally would unregister removeObserver: in dealloc
}

// pull-to-refresh
- (void) requestNewItemsWithCompletionHandler:(NewItemCompletionBlock)completionHandler {
    if (self.isRefreshing == NO) { // if request in progress, return immediately
        self.isRefreshing = YES; // else lock and continue
        
//        // placeholder data
//        Media* media = [[Media alloc] init]; // create random media
//        media.user = [self randomUser];
//        media.image = [UIImage imageNamed:@"10.jpg"];
//        media.caption = [self randomSentence];
//        
//        NSMutableArray* mutableArrayWithKVO = [self mutableArrayValueForKey:@"mediaItems"]; // append to top-most cell
//        [mutableArrayWithKVO insertObject:media atIndex:0];

        // TODO: Add images
        
        self.isRefreshing = NO;
        
        if (completionHandler) {
            completionHandler(nil); // error not used now for fake local data
        }
    }
}

// infinite scroll
- (void) requestOldItemsWithCompletionHandler:(NewItemCompletionBlock)completionHandler {
    if (self.isLoadingOlderItems == NO) {
        self.isLoadingOlderItems = YES;
        
//        // placeholder data
//        Media* media = [[Media alloc] init];
//        media.user = [self randomUser];
//        media.image = [UIImage imageNamed:@"1.jpg"];
//        media.caption = [self randomSentence];
//        
//        NSMutableArray* mutableArrayWithKVO = [self mutableArrayValueForKey:@"mediaItems"];
//        [mutableArrayWithKVO addObject:media];

        // TODO: Add images
        
        self.isLoadingOlderItems = NO;
        
        if (completionHandler) {
            completionHandler(nil);
        }
    }
}


#pragma mark - Key/Value Observing

// KVC: Accessor methods to allow observers to be notified when array changes

- (NSUInteger) countOfMediaItems {
    return self.mediaItems.count;
}

- (instancetype) objectInMediaItemsAtIndex:(NSUInteger)index {
    return self.mediaItems[index];
}

- (NSArray*) mediaItemsAtIndexes:(NSIndexSet *)indexes {
    return [self.mediaItems objectsAtIndexes:indexes];
    
}

// KVC: Mutable accessor methods (note using _mediaItems cuz readonly?)

- (void) insertObject:(Media*)object inMediaItemsAtIndex:(NSUInteger)index {
    [_mediaItems insertObject:object atIndex:index];
}

- (void) removeObjectFromMediaItemsAtIndex:(NSUInteger)index {
    [_mediaItems removeObjectAtIndex:index];
}

- (void) replaceObjectInMediaItemsAtIndex:(NSUInteger)index withObject:(id)object {
    [_mediaItems replaceObjectAtIndex:index withObject:object];
}


#pragma mark - Placeholder Data

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
