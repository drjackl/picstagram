//
//  UIImage+ImageUtilities.m
//  Blocstagram
//
//  Created by Jack Li on 3/5/16.
//  Copyright © 2016 Jack Li. All rights reserved.
//

#import "UIImage+ImageUtilities.h"

@implementation UIImage (ImageUtilities)

// inspects image's orientation and flips or rotates as necessary
- (UIImage*) imageWithFixedOrientation {
    // do nothing if orientation already correct (yikes, was infinitely calling method in this line)
    if (self.imageOrientation == UIImageOrientationUp) return [self copy];
    
    // calculate transformation to make image upright
    // 2 steps: rotate if left/right/down, flip if mirrored
    
    // transform holds an affine transformation matrix that we update
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    // 1. rotate
    switch (self.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, self.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored: // translate? (width, 0)
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored: // translate? (0, height)
            transform = CGAffineTransformTranslate(transform, 0, self.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
            
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    // 2. flip
    switch (self.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored: // translate? (width, 0)
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored: // translate? (height, 0)
            transform = CGAffineTransformTranslate(transform, self.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    
    // now draw underlying CGImage into new context, apply calculated transforms
    CGFloat scaleFactor = self.scale;
    
    // so once transform is set, 1) we create bitmap graphics context (blank sheet)
    CGContextRef ctx = CGBitmapContextCreate(NULL,
                                             self.size.width*scaleFactor,
                                             self.size.height*scaleFactor,
                                             CGImageGetBitsPerComponent(self.CGImage),
                                             0, // bytes per row
                                             CGImageGetColorSpace(self.CGImage),
                                             CGImageGetBitmapInfo(self.CGImage));
    
    // 2) scale image (for retina displays)
    CGContextScaleCTM(ctx, scaleFactor, scaleFactor);
    
    // 3) apply transform
    CGContextConcatCTM(ctx, transform);
    switch (self.imageOrientation) {
        case UIImageOrientationLeft: // interesting height and width switched
        case UIImageOrientationLeftMirrored: // oh, it's on its side
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextDrawImage(ctx,
                               CGRectMake(0, 0, self.size.height, self.size.width),
                               self.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx,
                               CGRectMake(0, 0, self.size.width, self.size.height),
                               self.CGImage);
            break;
    }
    
    // 4) create new UIImage from drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage* img = [UIImage imageWithCGImage:cgimg scale:scaleFactor orientation:UIImageOrientationUp];
    
    // since ARC doesn't support C, these methods release objects
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    
    return img;
}

// aspect ratio of iOS device screen not same as iOS device camera; resize to screen so cropping rectangle accurate
- (UIImage*) imageResizedToMatchAspectRationOfSize:(CGSize)size {
    CGFloat horizontalRatio = size.width / self.size.width;
    CGFloat verticalRatio = size.height / self.size.height;
    CGFloat ratio = MAX(horizontalRatio, verticalRatio);
    CGSize newSize = CGSizeMake(self.size.width * ratio * self.scale,
                                self.size.height * ratio * self.scale);
    
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGImageRef imageRef = self.CGImage;
    
    CGContextRef ctx = CGBitmapContextCreate(NULL,
                                             newRect.size.width,
                                             newRect.size.height,
                                             CGImageGetBitsPerComponent(self.CGImage),
                                             0, // bytes per row
                                             CGImageGetColorSpace(self.CGImage),
                                             CGImageGetBitmapInfo(self.CGImage));
    
    // draw into context (scales the image)
    CGContextDrawImage(ctx, newRect, imageRef);
    
    // get resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(ctx);
    UIImage* newImage = [UIImage imageWithCGImage:newImageRef scale:self.scale orientation:UIImageOrientationUp];
    
    // clean up
    CGContextRelease(ctx);
    CGImageRelease(newImageRef);
    
    return newImage;
}

// crop image to rect (simple cuz CGImageCreateWithImageInRect does the work)
- (UIImage*) imageCroppedToRect:(CGRect)cropRect {
    cropRect.size.width *= self.scale;
    cropRect.size.height *= self.scale;
    cropRect.origin.x *= self.scale;
    cropRect.origin.y *= self.scale;
    
    CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, cropRect);
    UIImage* image = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
    
    CGImageRelease(imageRef);
    
    return image;
}

// convenience method
- (UIImage*) imageByScalingToSize:(CGSize)size andCroppingWithRect:(CGRect)rect {
    UIImage* image = [self imageWithFixedOrientation];
    image = [self imageResizedToMatchAspectRationOfSize:size];
    image = [self imageCroppedToRect:rect];
    return image;
}


@end
