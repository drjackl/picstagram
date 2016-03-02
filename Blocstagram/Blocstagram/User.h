//
//  User.h
//  Blocstagram
//
//  Created by Jack Li on 2/28/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

//#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h> // apparently includes NSObject or all of Foundation?

@interface User : NSObject <NSCoding> // 1/2 of archiving (also NSKeyedArchiver)

@property (nonatomic) NSString* idNumber;
@property (nonatomic) NSString* userName;
@property (nonatomic) NSString* fullName;
@property (nonatomic) NSURL* profilePictureURL;
@property (nonatomic) UIImage* profilePicture; // requires UIKit

// for JSON parsing
- (instancetype) initWithDictionary:(NSDictionary*)userDictionary;

@end
