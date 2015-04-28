//
//  UIImage+GRKImageCrop.m
//
//  Created by Levi Brown on April 24, 2015.
//  Copyright (c) 2015 Levi Brown <mailto:levigroker@gmail.com>
//  This work is licensed under the Creative Commons Attribution 3.0
//  Unported License. To view a copy of this license, visit
//  http://creativecommons.org/licenses/by/3.0/ or send a letter to Creative
//  Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041,
//  USA.
//
//  The above attribution and the included license must accompany any version
//  of the source code. Visible attribution in any binary distributable
//  including this work (or derivatives) is not required, but would be
//  appreciated.
//

#import "UIImage+GRKImageCrop.h"

NSString * const kGRKImageCropErrorDomain = @"GRKImageCropErrorDomain";

@implementation UIImage (GRKImageCrop)

- (void)cropImageBelowAlphaThreshold:(CGFloat)alphaThreshold completion:(void(^)(UIImage *croppedImage, NSError *error))completion
{
    if (completion)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *error = nil;
            UIImage *image = nil;
            UIEdgeInsets insets = [UIImage edgeInsetsBelowAlphaThreshold:alphaThreshold forImage:self error:&error];
            if (!error)
            {
                CGRect rect = CGRectMake(insets.left, insets.top, self.size.width - (insets.left + insets.right), self.size.height - (insets.top + insets.bottom));
                image = [self croppedImageInRect:rect];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(image, error);
            });
        });
    }
}

+ (UIEdgeInsets)edgeInsetsBelowAlphaThreshold:(CGFloat)alphaThreshold forImage:(UIImage *)image error:(NSError **)error
{
    UIEdgeInsets retVal = UIEdgeInsetsZero;
    
    UInt8 alphaThresholdValue = 255.0f * alphaThreshold;
    CGImageRef imageRef = image.CGImage;
    CGFloat scale = image.scale;
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    
    UInt8 *pixelBuffer = (UInt8 *)calloc(height * width * bytesPerPixel, sizeof(UInt8));
    if (pixelBuffer == NULL)
    {
        if (error)
        {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : NSLocalizedString(@"Unable to allocate memory for the pixel buffer.", nil) };
            *error = [[NSError alloc] initWithDomain:NSPOSIXErrorDomain code:ENOMEM userInfo:userInfo];
        }
    }
    else
    {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        if (colorSpace == NULL)
        {
            if (error)
            {
                NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : NSLocalizedString(@"Unable to create color space.", nil) };
                *error = [[NSError alloc] initWithDomain:NSPOSIXErrorDomain code:ENOMEM userInfo:userInfo];
            }
        }
        else
        {
            CGContextRef context = CGBitmapContextCreate(pixelBuffer, width, height,
                                                         bitsPerComponent, bytesPerRow, colorSpace,
                                                         kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
            //Release the color space memory
            CGColorSpaceRelease(colorSpace);
            
            if (context == NULL)
            {
                if (error)
                {
                    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : NSLocalizedString(@"Unable to create bitmap context.", nil) };
                    *error = [[NSError alloc] initWithDomain:NSPOSIXErrorDomain code:ENOMEM userInfo:userInfo];
                }
            }
            else
            {
                CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
                //Release the context memory
                CGContextRelease(context);
                
                //Now the pixelBuffer is populated with RGBA8888 pixel data
                
                //Discover the top, bottom, left and right insets as concurrent operations
                __block CGFloat topInset;
                __block CGFloat bottomInset;
                __block CGFloat leftInset;
                __block CGFloat rightInset;
                
                //Create a dispatch group so we can wait for all our concurrent operations to finish
                dispatch_group_t group = dispatch_group_create();
                
                //Fire the top inset operation
                dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    topInset = [UIImage topPixelInsetForAlphaThreshold:alphaThresholdValue width:width height:height pixelBuffer:pixelBuffer];
                    topInset /= scale;
                });

                //Fire the bottom inset operation
                dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    bottomInset = [UIImage bottomPixelInsetForAlphaThreshold:alphaThresholdValue width:width height:height pixelBuffer:pixelBuffer];
                    bottomInset /= scale;
                });

                //Fire the left inset operation
                dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    leftInset = [UIImage leftPixelInsetForAlphaThreshold:alphaThresholdValue width:width height:height pixelBuffer:pixelBuffer];
                    leftInset /= scale;
                });

                //Fire the right inset operation
                dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    rightInset = [UIImage rightPixelInsetForAlphaThreshold:alphaThresholdValue width:width height:height pixelBuffer:pixelBuffer];
                    rightInset /= scale;
                });

                //Wait for all our concurrent operations to complete
                dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
                
                retVal = UIEdgeInsetsMake(topInset, leftInset, bottomInset, rightInset);
            }
        }

        //Free the pixelBuffer memory
        free(pixelBuffer);
    }

    return retVal;
}

+ (CGFloat)topPixelInsetForAlphaThreshold:(UInt8)alphaThresholdValue width:(size_t)width height:(size_t)height pixelBuffer:(UInt8 *)pixelBuffer
{
    // For the top, we start at the top and scan horizontally line by line until we find a pixel whose alpha is less than (or equal to) the threshold
    // *---------------*
    // |...............|
    // |...../\_/\     |
    // |   =( O.O )=   |
    // |   --O---O--   |
    // |               |
    // *---------------*
    for (size_t y = 0; y < height; ++y)
    {
        for (size_t x = 0; x < width; ++x)
        {
            size_t loc = x + (y * width); //Linear pixel offset
            loc *= 4; //4 bytes per pixel
            loc += 3; //Alpha byte
            if (pixelBuffer[loc] > alphaThresholdValue)
            {
                return y;
            }
        }
    }
    
    return height - 1;
}

+ (CGFloat)bottomPixelInsetForAlphaThreshold:(UInt8)alphaThresholdValue width:(size_t)width height:(size_t)height pixelBuffer:(UInt8 *)pixelBuffer
{
    // For the bottom, we start at the bottom and scan horizontally line by line until we find a pixel whose alpha is less than (or equal to) the threshold
    // *---------------*
    // |               |
    // |     /\_/\     |
    // |   =( O.O )=   |
    // |...--O---O--   |
    // |...............|
    // *---------------*
    for (long y = height - 1; y >= 0; --y)
    {
        for (size_t x = 0; x < width; ++x)
        {
            size_t loc = x + (y * width); //Linear pixel offset
            loc *= 4; //4 bytes per pixel
            loc += 3; //Alpha byte
            if (pixelBuffer[loc] > alphaThresholdValue)
            {
                return height - (y + 1);
            }
        }
    }
    
    return 0;
}

+ (CGFloat)leftPixelInsetForAlphaThreshold:(UInt8)alphaThresholdValue width:(size_t)width height:(size_t)height pixelBuffer:(UInt8 *)pixelBuffer
{
    // For the left, we start at the left and scan vertically column by column until we find a pixel whose alpha is less than (or equal to) the threshold
    // *---------------*
    // |....           |
    // |.... /\_/\     |
    // |...=( O.O )=   |
    // |...--O---O--   |
    // |...            |
    // *---------------*
    for (size_t x = 0; x < width; ++x)
    {
        for (size_t y = 0; y < height; ++y)
        {
            size_t loc = x + (y * width); //Linear pixel offset
            loc *= 4; //4 bytes per pixel
            loc += 3; //Alpha byte
            if (pixelBuffer[loc] > alphaThresholdValue)
            {
                return x;
            }
        }
    }
    
    return width - 1;
}


+ (CGFloat)rightPixelInsetForAlphaThreshold:(UInt8)alphaThresholdValue width:(size_t)width height:(size_t)height pixelBuffer:(UInt8 *)pixelBuffer
{
    // For the right, we start at the right and scan vertically column by column until we find a pixel whose alpha is less than (or equal to) the threshold
    // *---------------*
    // |           ....|
    // |     /\_/\ ....|
    // |   =( O.O )=...|
    // |   --O---O--...|
    // |            ...|
    // *---------------*
    for (long x = width - 1; x >= 0; --x)
    {
        for (size_t y = 0; y < height; ++y)
        {
            size_t loc = x + (y * width); //Linear pixel offset
            loc *= 4; //4 bytes per pixel
            loc += 3; //Alpha byte
            if (pixelBuffer[loc] > alphaThresholdValue)
            {
                return width - (x + 1);
            }
        }
    }
    
    return 0;
}

//From http://stackoverflow.com/a/25293588/397210
- (UIImage *)croppedImageInRect:(CGRect)rect
{
    double (^rad)(double) = ^(double deg)
    {
        return deg / 180.0 * M_PI;
    };
    
    CGAffineTransform rectTransform;
    switch (self.imageOrientation)
    {
        case UIImageOrientationLeft:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(90)), 0, -self.size.height);
            break;
        case UIImageOrientationRight:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(-90)), -self.size.width, 0);
            break;
        case UIImageOrientationDown:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(-180)), -self.size.width, -self.size.height);
            break;
        default:
            rectTransform = CGAffineTransformIdentity;
    };
    rectTransform = CGAffineTransformScale(rectTransform, self.scale, self.scale);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, CGRectApplyAffineTransform(rect, rectTransform));
    UIImage *result = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(imageRef);
    
    return result;
}

@end
