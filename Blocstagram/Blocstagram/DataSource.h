//
//  DataSource.h
//  Blocstagram
//
//  Created by Jack Li on 2/28/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Media; // for proper KVO deleting

// add completion handler definition (also, typedefs define types! (for reuse))
typedef void (^NewItemCompletionBlock)(NSError* error);

@interface DataSource : NSObject

+ (instancetype) sharedInstance;

+ (NSString*) instagramClientID; // client ID stored in DataSource

@property (nonatomic, readonly) NSMutableArray* mediaItems; // change to mutable for deletion (initial and/or KVO?)

@property (nonatomic, readonly) NSString* accessToken; // store once gotten

//+ (void) deleteItemAtIndex:(NSInteger)row; // initial deletion handling (not quite right)
- (void) deleteMediaItem:(Media*)item; // KVO deleting
//- (void) moveMediaItemToTop:(Media*)item; // KVO moving to top

// pull-to-refresh: 1. gets new data 2. create new Media objects 3. call handler when done
- (void) requestNewItemsWithCompletionHandler:(NewItemCompletionBlock)completionHandler;
// infinite scroll
- (void) requestOldItemsWithCompletionHandler:(NewItemCompletionBlock)completionHandler;

@end
