//
//  UIImage+GRKImageCrop.h
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

#import <UIKit/UIKit.h>

@interface UIImage (GRKImageCrop)

/**
 * Asynchronously provides a rectangularly cropped version of the receiver where pixels below the given alpha threshold are used to determine the edge insets of the cropping rectangle.
 *
 * @param alphaThreshold The threshold of the alpha pixel component to use when determining the cropping rectangle. This should be a value from 0.0 to 1.0. If a pixel's alpha component is below this threshold it will be considered cropable.
 * @param completion     A block to receive the cropped image, or error, should one occur. This will be called from the main queue.
 */
- (void)cropImageBelowAlphaThreshold:(CGFloat)alphaThreshold completion:(void(^)(UIImage *croppedImage, NSError *error))completion;

/**
 * Crops the receiver to the given rectangle.
 *
 * @param rect The rectangle to crop to.
 *
 * @return A new UIImage insatnce containign the cropped version of the receiver.
 */
- (UIImage *)croppedImageInRect:(CGRect)rect;

/**
 * Calculates edge insets, in points, of a given image based on the alpha threshold specified for bordering pixels.
 *
 * @param alphaThreshold The threshold of the alpha pixel component to use when determining the edge insets. This should be a value from 0.0 to 1.0. If a pixel's alpha component is below this threshold it will be considered transparent and therefore ignored as a "non-visible" pixel.
 * @param image          The image whose edge insets to calculate.
 * @param error          Should any error occur, this pointer will be populated with a new NSError object containing the error information.
 *
 * @return A UIEdgeInsets containing the calculated point insets, or UIEdgeInsetsZero if they could not be calculated.
 */
+ (UIEdgeInsets)edgeInsetsBelowAlphaThreshold:(CGFloat)alphaThreshold forImage:(UIImage *)image error:(NSError **)error;

@end
