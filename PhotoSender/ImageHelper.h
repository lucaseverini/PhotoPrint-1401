/*
 * The MIT License
 *
 * Copyright (c) 2011 Paul Solt, PaulSolt@gmail.com
 *
 * https://github.com/PaulSolt/UIImage-Conversion/blob/master/MITLicense.txt
 *
 */

@interface ImageHelper : NSObject
{
}

/** Converts a UIImage to RGBA8 bitmap.
 @param image - a UIImage to be converted
 @return a RGBA8 bitmap, or NULL if any memory allocation issues. Cleanup memory with free() when done.
 */
+ (unsigned char *) convertUIImageToBitmapGray:(UIImage *)image;

/** A helper routine used to convert a RGBA8 to UIImage
 @return a new context that is owned by the caller
 */
+ (CGContextRef) newBitmapGrayContextFromImage:(CGImageRef)image;

/** Converts a RGBA8 bitmap to a UIImage.
 @param buffer - the RGBA8 unsigned char * bitmap
 @param width - the number of pixels wide
 @param height - the number of pixels tall
 @return a UIImage that is autoreleased or nil if memory allocation issues
 */
+ (UIImage *) convertBitmapRGBA8ToUIImage:(unsigned char *)buffer
								withWidth:(int)width
							   withHeight:(int)height;

+ (UIImage*) imageWithView:(UIView *)view scale:(CGFloat)scale;

+ (UIImage*) clippedImageForRect:(CGRect)clipRect inView:(UIView*)view;

+ (UIImage*) scaleImage:(UIImage*)image horizScale:(CGFloat)hScale vertScale:(CGFloat)vScale;

+ (UIImage*) convertImageToGray:(UIImage*)originalImage;

@end