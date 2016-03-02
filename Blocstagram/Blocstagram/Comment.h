//
//  Comment.h
//  Blocstagram
//
//  Created by Jack Li on 2/28/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import <Foundation/Foundation.h>
// no need for UIKit

@class User;

@interface Comment : NSObject

@property (nonatomic) NSString* idNumber;

@property (nonatomic) User* from;
@property (nonatomic) NSString* text;


- (instancetype) initWithDictionary:(NSDictionary*)commentDictionary;

@end
