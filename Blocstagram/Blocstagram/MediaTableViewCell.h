//
//  MediaTableViewCell.h
//  Blocstagram
//
//  Created by Jack Li on 2/28/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Media;

@interface MediaTableViewCell : UITableViewCell

@property (nonatomic) Media* mediaItem; // every cell associated with single item

// like static variables declared earlier, but in .h so all classes may use
+ (CGFloat) heightForMediaItem:(Media*)mediaItem width:(CGFloat)width;

@end
