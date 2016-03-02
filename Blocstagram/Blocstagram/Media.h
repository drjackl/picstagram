//
//  Media.h
//  Blocstagram
//
//  Created by Jack Li on 2/28/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

//#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h> // includes all Foundation objects NSObject, NSString, NSURL

@class User; // forward declare as generally bad to #import custom classes in .h

@interface Media : NSObject <NSCoding> // 1/2 of archiving (also NSKeyedArchiver)

@property (nonatomic) NSString* idNumber;
@property (nonatomic) User* user;
@property (nonatomic) NSURL* mediaURL;
@property (nonatomic) UIImage* image; // needs UIKit
@property (nonatomic) NSString* caption;
@property (nonatomic) NSArray* comments;

- (instancetype) initWithDictionary:(NSDictionary*)mediaDictionary;

@end
