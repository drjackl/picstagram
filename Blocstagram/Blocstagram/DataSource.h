//
//  DataSource.h
//  Blocstagram
//
//  Created by Jack Li on 2/28/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataSource : NSObject

+ (instancetype) sharedInstance;

+ (void) deleteItemAtIndex:(NSInteger)row;

@property (nonatomic, readonly) NSMutableArray* mediaItems; // change to mutable for deletion

@end
