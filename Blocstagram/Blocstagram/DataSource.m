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

@property (nonatomic) BOOL thereAreNoMoreOlderMessages; // infinite scroll, for real data

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
        
        // got token, populate initial data (first pass, just a printout)
        //[self populateDataWithParameters:nil]; // has handler in parsing JSON now
        [self populateDataWithParameters:nil completionHandler:nil];
    }];
    
    // normally would unregister removeObserver: in dealloc
}

// create pics/media request and turn IG API respons to a dictionary
// update to use completion handler for pulling real pics/media
//- (void) populateDataWithParameters:(NSDictionary*)parameters {
- (void) populateDataWithParameters:(NSDictionary*)parameters completionHandler:(NewItemCompletionBlock)completionHandler {
    
    // only try get data if there's access token
    if (self.accessToken) {
        
        // do network request in background so UI doesn't lockup
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSMutableString* urlString = [NSMutableString stringWithFormat:@"https://api.instagram.com/v1/users/self/media/recent/?access_token=%@", self.accessToken];
            
            // eg, if dictionary has count: 50, append &count=50 to URL
            for (NSString* parameterName in parameters) {
                [urlString appendFormat:@"&%@=%@", parameterName, parameters[parameterName]];
            }
            
            NSURL* url = [NSURL URLWithString:urlString];
            if (url) {
                // request normally given to a UIWebView to load and display
                NSURLRequest* request = [NSURLRequest requestWithURL:url];
                
                NSURLResponse* response;
                NSError* webError;
                
                // if not displaying, use connection to handle connect and download
                // NSData represents any type of data; can be convered to UIImage or NSString
                NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&webError]; // seems to be deprecated
                
                if (responseData) {
                    NSError* jsonError;
                    NSDictionary* feedDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonError];
                    
                    if (feedDictionary) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            // done networking, go back on the main thread
                            [self parseDataFromFeedDictionary:feedDictionary fromRequestWithParameters:parameters];
                            
                            if (completionHandler) { // if request successful, no error
                                completionHandler(nil);
                            }
                        });
                    } else if (completionHandler) { // if json error pass to handler
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completionHandler(jsonError);
                        });
                    }
                } else if (completionHandler) { // if weberror, pass that to handler
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionHandler(webError);
                    });
                }
            }
        });
    }
}

- (void) parseDataFromFeedDictionary:(NSDictionary*)feedDictionary fromRequestWithParameters:(NSDictionary*)parameters {
    NSLog(@"%@", feedDictionary); // first time login and getting data
    
    // now actually parse the IG feed
    NSArray* mediaArray = feedDictionary[@"data"];
    
    NSMutableArray* tmpMediaItems = [NSMutableArray array];
    for (NSDictionary* mediaDictionary in mediaArray) {
        Media* mediaItem = [[Media alloc] initWithDictionary:mediaDictionary];
        
        if (mediaItem) { // always need to check if parsed successfully
            [tmpMediaItems addObject:mediaItem];
            
            [self downloadImageForMediaItem:mediaItem]; // download image, though this is inefficient as it downloads 100 images simultaneously; better to start downloading as user scrolls through feed
        }
    }
    
//    // this code doesn't use parameters dictionary, so need to update
//    [self willChangeValueForKey:@"mediaItems"]; // inform KVO about to be replaced
//    self.mediaItems = tmpMediaItems;
//    [self didChangeValueForKey:@"mediaItems"]; // inform KVO has been replaced, triggers reload of all data
    
    NSMutableArray* mutableArrayWithKVO = [self mutableArrayValueForKey:@"mediaItems"];
    
    if (parameters[@"min_id"]) { // this was a pull-to-refresh request
        NSRange rangeOfIndex = NSMakeRange(0, tmpMediaItems.count);
        NSIndexSet* indexSetOfNewObjects = [NSIndexSet indexSetWithIndexesInRange:rangeOfIndex];
        
        [mutableArrayWithKVO insertObjects:tmpMediaItems atIndexes:indexSetOfNewObjects];
    } else if (parameters[@"max_id"]) { // this was an infinite scroll request
        if (tmpMediaItems.count == 0) { // disable scroll since no more older posts
            self.thereAreNoMoreOlderMessages = YES;
        } else {
            [mutableArrayWithKVO addObjectsFromArray:tmpMediaItems];
        }
    } else {
        [self willChangeValueForKey:@"mediaItems"]; // inform KVO about to be replaced
        self.mediaItems = tmpMediaItems;
        [self didChangeValueForKey:@"mediaItems"]; // inform KVO has been replaced, triggers reload of all data
    }
}

- (void) downloadImageForMediaItem:(Media*)mediaItem {
    if (mediaItem.mediaURL && !mediaItem.image) { // if there's a URL, but no image
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSURLRequest* request = [NSURLRequest requestWithURL:mediaItem.mediaURL];
            
            NSURLResponse* response;
            NSError* error;
            NSData* imageData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            
            if (imageData) {
                UIImage* image = [UIImage imageWithData:imageData];
                
                if (image) {
                    mediaItem.image = image;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSMutableArray* mutableArrayWithKVO = [self mutableArrayValueForKey:@"mediaItems"];
                        NSUInteger index = [mutableArrayWithKVO indexOfObject:mediaItem];
                        [mutableArrayWithKVO replaceObjectAtIndex:index withObject:mediaItem]; // triggers KVO notification to reload row
                    });
                }
            } else { // no imageData
                NSLog(@"Error downloading image: %@", error);
            }
        });
    }
}

// pull-to-refresh
- (void) requestNewItemsWithCompletionHandler:(NewItemCompletionBlock)completionHandler {
    self.thereAreNoMoreOlderMessages = NO; // reset
    
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

        // past todo: Add images
        NSString* minID = [[self.mediaItems firstObject] idNumber];
        NSDictionary* parameters;
        if (minID) {
            parameters = @{@"min_id": minID};
        }
        [self populateDataWithParameters:parameters completionHandler:^(NSError *error) {
            self.isRefreshing = NO;
            
            if (completionHandler) {
                completionHandler(error);
            }
        }];
        
//        // when images were created, could simply just set isRefreshing to NO
//        self.isRefreshing = NO;
//        
//        if (completionHandler) {
//            completionHandler(nil); // error not used now for fake local data
//        }
    }
}

// infinite scroll
- (void) requestOldItemsWithCompletionHandler:(NewItemCompletionBlock)completionHandler {
    //if (self.isLoadingOlderItems == NO) { // before, didn't care about pointless requests
    if (self.isLoadingOlderItems && self.thereAreNoMoreOlderMessages) {
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
        NSString* maxID = [[self.mediaItems lastObject] idNumber];
        NSDictionary* parameters;
        if (maxID) {
            parameters = @{@"max_id": maxID};
        }
        [self populateDataWithParameters:parameters completionHandler:^(NSError*error) {
            self.isLoadingOlderItems = NO;
            
            if (completionHandler) {
                completionHandler(nil);
            }
        }];
        
//        // before, just stopped once created placeholder data
//        self.isLoadingOlderItems = NO;
//        
//        if (completionHandler) {
//            completionHandler(nil);
//        }
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
