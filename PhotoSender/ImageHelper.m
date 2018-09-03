/*
 * The MIT License
 *
 * Copyright (c) 2011 Paul Solt, PaulSolt@gmail.com
 *
 * https://github.com/PaulSolt/UIImage-Conversion/blob/master/MITLicense.txt
 *
 */

#import "ImageHelper.h"

@implementation ImageHelper

+ (unsigned char *) convertUIImageToBitmapGray:(UIImage *) image
{
	CGImageRef imageRef = image.CGImage;
	
	// Create a bitmap context to draw the uiimage into
	CGContextRef context = [self newBitmapGrayContextFromImage:imageRef];
	if(!context)
	{
		return NULL;
	}
	
	size_t width = CGImageGetWidth(imageRef);
	size_t height = CGImageGetHeight(imageRef);
	
	CGRect rect = CGRectMake(0, 0, width, height);
	
	// Draw image into the context to get the raw image data
	CGContextDrawImage(context, rect, imageRef);
	
	// Get a pointer to the data
	unsigned char *bitmapData = (unsigned char *)CGBitmapContextGetData(context);
	
	// Copy the data and release the memory (return memory allocated with new)
	size_t bytesPerRow = CGBitmapContextGetBytesPerRow(context);
	size_t bufferLength = bytesPerRow * height;
	
	unsigned char *newBitmap = NULL;
	
	if(bitmapData)
	{
		int count = (int)(sizeof(unsigned char) * bytesPerRow * height);
		newBitmap = (unsigned char *)malloc(count);
		if(newBitmap != NULL)
		{
			for(int i = 0; i < bufferLength; ++i)
			{
				newBitmap[i] = bitmapData[i];
			}
		}
		
		free(bitmapData);
	}
	else
	{
		NSLog(@"Error getting bitmap pixel data\n");
	}
	
	CGContextRelease(context);
	
	return newBitmap;
}

+ (CGContextRef) newBitmapGrayContextFromImage:(CGImageRef) image
{
	CGContextRef context = NULL;
	CGColorSpaceRef colorSpace;
	uint32_t *bitmapData;
	
	size_t bitsPerPixel = 8;
	size_t bitsPerComponent = 8;
	size_t bytesPerPixel = bitsPerPixel / bitsPerComponent;
	
	size_t width = CGImageGetWidth(image);
	size_t height = CGImageGetHeight(image);
	
	size_t bytesPerRow = width * bytesPerPixel;
	size_t bufferLength = bytesPerRow * height;
	
	colorSpace = CGColorSpaceCreateDeviceGray();
	if(!colorSpace)
	{
		NSLog(@"Error allocating color space Gray\n");
		return NULL;
	}
	
	// Allocate memory for image data
	bitmapData = (uint32_t *)malloc(bufferLength);
	if(!bitmapData)
	{
		NSLog(@"Error allocating memory for bitmap\n");
		CGColorSpaceRelease(colorSpace);
		return NULL;
	}
	
	//Create bitmap context
	
	context = CGBitmapContextCreate(bitmapData,
									width,
									height,
									bitsPerComponent,
									bytesPerRow,
									colorSpace,
									kCGImageAlphaNone);
	if(!context)
	{
		free(bitmapData);
		NSLog(@"Bitmap context not created");
	}
	
	CGColorSpaceRelease(colorSpace);
	
	return context;
}

+ (UIImage *) convertBitmapRGBA8ToUIImage:(unsigned char *) buffer
								withWidth:(int) width
							   withHeight:(int) height
{
	size_t bufferLength = width * height * 4;
	CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, bufferLength, NULL);
	size_t bitsPerComponent = 8;
	size_t bitsPerPixel = 32;
	size_t bytesPerRow = 4 * width;
	
	CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
	if(colorSpaceRef == NULL)
	{
		NSLog(@"Error allocating color space");
		CGDataProviderRelease(provider);
		return nil;
	}
	
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
	CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
	
	CGImageRef iref = CGImageCreate(width,
									height,
									bitsPerComponent,
									bitsPerPixel,
									bytesPerRow,
									colorSpaceRef,
									bitmapInfo,
									provider,	// data provider
									NULL,		// decode
									YES,			// should interpolate
									renderingIntent);
	
	uint32_t* pixels = (uint32_t*)malloc(bufferLength);
	
	if(pixels == NULL)
	{
		NSLog(@"Error: Memory not allocated for bitmap");
		CGDataProviderRelease(provider);
		CGColorSpaceRelease(colorSpaceRef);
		CGImageRelease(iref);
		return nil;
	}
	
	CGContextRef context = CGBitmapContextCreate(pixels,
												 width,
												 height,
												 bitsPerComponent,
												 bytesPerRow,
												 colorSpaceRef,
												 bitmapInfo);
	
	if(context == NULL)
	{
		NSLog(@"Error context not created");
		free(pixels);
		pixels = nil;
	}
	
	UIImage *image = nil;
	if(context)
	{
		CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), iref);
		
		CGImageRef imageRef = CGBitmapContextCreateImage(context);
		
		// Support both iPad 3.2 and iPhone 4 Retina displays with the correct scale
		if([UIImage respondsToSelector:@selector(imageWithCGImage:scale:orientation:)])
		{
			float scale = [[UIScreen mainScreen] scale];
			image = [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
		}
		else
		{
			image = [UIImage imageWithCGImage:imageRef];
		}
		
		CGImageRelease(imageRef);
		CGContextRelease(context);
	}
	
	CGColorSpaceRelease(colorSpaceRef);
	CGImageRelease(iref);
	CGDataProviderRelease(provider);
	
	if(pixels)
	{
		free(pixels);
	}
	
	return image;
}

+ (UIImage*) clippedImageForRect:(CGRect)clipRect inView:(UIView*)view
{
	UIGraphicsBeginImageContextWithOptions(clipRect.size, view.opaque, 1.0);
	
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(ctx, -clipRect.origin.x, -clipRect.origin.y);
	[view.layer renderInContext:ctx];
	
	UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
	return img;
}

+ (UIImage*) imageWithView:(UIView *)view scale:(CGFloat)scale
{
	UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 1.0);
	
	// [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
	[view.layer renderInContext:UIGraphicsGetCurrentContext()];
	
	UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
	return snapshotImage;
}

+ (UIImage*) convertImageToGray:(UIImage*)originalImage
{
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
	CGContextRef context = CGBitmapContextCreate(nil, originalImage.size.width * originalImage.scale, originalImage.size.height * originalImage.scale, 8,
												 originalImage.size.width * originalImage.scale, colorSpace, kCGImageAlphaNone);
	CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
	CGContextSetShouldAntialias(context, NO);
	CGContextDrawImage(context, CGRectMake(0, 0, originalImage.size.width, originalImage.size.height), [originalImage CGImage]);
	
	CGImageRef bwImage = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	CGColorSpaceRelease(colorSpace);
	
	UIImage *resultImage = [UIImage imageWithCGImage:bwImage];
	CGImageRelease(bwImage);
	
	UIGraphicsBeginImageContextWithOptions(originalImage.size, NO, originalImage.scale);
	[resultImage drawInRect:CGRectMake(0.0, 0.0, originalImage.size.width, originalImage.size.height)];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return newImage;
}

+ (UIImage*) scaleImage:(UIImage*)image horizScale:(CGFloat)hScale vertScale:(CGFloat)vScale
{
	CGSize newSize = CGSizeMake(image.size.width * hScale, image.size.height * vScale);
	UIGraphicsBeginImageContext(newSize);
	
	[image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
	return newImage;
}

@end


