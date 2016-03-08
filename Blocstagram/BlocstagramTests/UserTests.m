//
//  UserTests.m
//  Blocstagram
//
//  Created by Jack Li on 3/7/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "User.h"
#import "Media.h"
#import "ComposeCommentView.h"
#import "MediaTableViewCell.h"

@interface UserTests : XCTestCase

@end

@implementation UserTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


- (void) testThatInitializationWorks {
    NSDictionary* sourceDictionary = @{@"id": @"98374598",
                                       @"username": @"d'oh",
                                       @"full_name": @"Homer Simpson",
                                       @"profile_picture": @"http://www.example.com/example.jpg"};
    User* testUser = [[User alloc] initWithDictionary:sourceDictionary];
    
    XCTAssertEqualObjects(testUser.idNumber, sourceDictionary[@"id"], @"The ID number should be equal");
    XCTAssertEqualObjects(testUser.userName, sourceDictionary[@"username"], @"The username should be equal");
    XCTAssertEqualObjects(testUser.fullName, sourceDictionary[@"full_name"], @"The full name should be equal");
    XCTAssertEqualObjects(testUser.profilePictureURL, [NSURL URLWithString:sourceDictionary[@"profile_picture"]], @"The profile picture should be equal");
}

- (void) testMediaInitialzer {
    NSDictionary* userDictionary = @{@"id": @"908asd9023kjasdf",
                                     @"username": @"ps145",
                                     @"full_name": @"Fake Johnson",
                                     @"profile_picture": @"http://www.example.com/example.jpg"};
    NSDictionary* mediaDictionary = @{@"id": @"872349khj09890",
                                      @"user": userDictionary,
                                      @"images": @{@"standard_resolution": @{@"url": @"https://d262ilb51hltx0.cloudfront.net/max/800/1*b3CaM-K2RNlcbfAl-L-uXA.png"}},
                                      @"user_has_liked": @1,
                                      @"likes": @{@"count": @55}};
    Media* testMedia = [[Media alloc] initWithDictionary:mediaDictionary];
    XCTAssertEqualObjects(testMedia.idNumber, mediaDictionary[@"id"], @"The ID number should be equal");
    //NSLog(@"testMedia url: %@", testMedia.mediaURL);
    //NSLog(@"mediaDictionary url: %@", mediaDictionary[@"images"][@"standard_resolution"][@"url"]);
    XCTAssertEqualObjects(testMedia.mediaURL, [NSURL URLWithString:mediaDictionary[@"images"][@"standard_resolution"][@"url"]], @"The media URL should be equal");
    XCTAssertEqual(testMedia.likeCount, [mediaDictionary[@"likes"][@"count"] intValue], @"The like count should be equal");
    XCTAssertEqual(testMedia.likeState, [mediaDictionary[@"user_has_liked"] boolValue] ? LikeStateLiked : LikeStateNotLiked, @"The like state should be equal");
    XCTAssertEqual(testMedia.likeState, LikeStateLiked, @"The like state should be Liked");
    
    XCTAssertEqualObjects(testMedia.user.idNumber, mediaDictionary[@"user"][@"id"], @"The User ID number should be equal");
    XCTAssertEqualObjects(testMedia.user.userName, mediaDictionary[@"user"][@"username"], @"The User username should be equal");
    XCTAssertEqualObjects(testMedia.user.fullName, mediaDictionary[@"user"][@"full_name"], @"The User's full name should be equal");
    XCTAssertEqualObjects(testMedia.user.profilePictureURL, [NSURL URLWithString:mediaDictionary[@"user"][@"profile_picture"]], @"The User's profile pic should be equal");
    
}

- (void) testComposeCommentSetsIsWritingComment {
    ComposeCommentView* composeCommentView = [[ComposeCommentView alloc] init];
    [composeCommentView setText:@"some comment text"];
    XCTAssertTrue(composeCommentView.isWritingComment);
    [composeCommentView setText:@""];
    XCTAssertFalse(composeCommentView.isWritingComment);
}

- (void) testMediaTableViewCellsHeightForMediaMethod {
    NSDictionary* userDictionary = @{//@"id": @"908asd9023kjasdf",
                                     @"username": @"ps145"//,
                                     //@"full_name": @"Fake Johnson",
                                     //@"profile_picture": @"http://www.example.com/example.jpg"
                                     };
    NSDictionary* mediaDictionary = @{//@"id": @"872349khj09890",
                                      @"user": userDictionary,
                                      //@"images": @{@"standard_resolution": @{@"url": @"http://www.example.com/example.jpg"}},
                                      //@"user_has_liked": @1,
                                      @"likes": @{@"count": @55}
                                      };
    Media* testMedia = [[Media alloc] initWithDictionary:mediaDictionary];
    //NSLog(@"%f", [MediaTableViewCell heightForMediaItem:testMedia width:3 traitCollection:nil]);
    //XCTAssertEqual([MediaTableViewCell heightForMediaItem:testMedia width:3 traitCollection:nil], 4);
    testMedia.image = [UIImage imageNamed:@"7.jpg"];
    
    // need to pass in traitcollection otherwise imageHeighConstraint doesn't get set
    
    // to test heightForMediaItem, need Media, set an image, set traitCollection, understand how height of cell is calculated from all subviews with auto-layout
    
    // constraint to test: V:|[_mediaImageView][_usernameAndCaptionLabel][_commentLabel][_commentView(==100)

    // 1200x1600 item has height 4 for width 3 (so cell height == 4 + 109.667 + 0 + 100)
    XCTAssertEqualWithAccuracy([MediaTableViewCell heightForMediaItem:testMedia width:3 traitCollection:[UITraitCollection traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassCompact]], 213, 2);
    
    // 1200x1600 item has height 1600 for height 1200 (so cell height == 1600 + 38 + 0 + 100)
    XCTAssertEqualWithAccuracy([MediaTableViewCell heightForMediaItem:testMedia width:1200 traitCollection:[UITraitCollection traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassCompact]], 1738, 2);
    
    // 3200 + 38 + 0 + 100
    XCTAssertEqualWithAccuracy([MediaTableViewCell heightForMediaItem:testMedia width:2400 traitCollection:[UITraitCollection traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassCompact]], 3338, 2);
    
    
}


- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
