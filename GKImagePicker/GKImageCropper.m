//
//  GKImageCropper.m
//  GKImageEditor
//
//  Created by Genki Kondo on 9/18/12.
//  Copyright (c) 2012 Genki Kondo. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "GKImageCropper.h"
#import "UIImage+Resize.h"
#import "UIImage+Rotate.h"
#import "UIImage+FixOrientation.h"
#import "ImageHelper.h"

@interface GKImageCropper () <UIScrollViewDelegate>
{
    UIScrollView *scrollView;
    UIImageView *imageView;
}
@end

@implementation GKImageCropper

@synthesize delegate = _delegate;
@synthesize image = _image;
@synthesize cropSize = _cropSize;
@synthesize rescaleImage = _rescaleImage;
@synthesize rescaleFactor = _rescaleFactor;
@synthesize dismissAnimated = _dismissAnimated;
@synthesize overlayColor = _overlayColor;
@synthesize innerBorderColor = _innerBorderColor;

-(id) initWithImage:(UIImage*)theImage withCropSize:(CGSize)theSize willRescaleImage:(BOOL)willRescaleImage withRescaleFactor:(double)theFactor willDismissAnimated:(BOOL)willDismissAnimated
{
    self = [super init];
    if(self != nil)
	{
        self.image = theImage;

		// Rotate image to proper orientation
        if (self.image.imageOrientation == UIImageOrientationRight)
		{
            self.image = [UIImage imageWithCGImage:[self.image CGImage] scale:1.0 orientation: UIImageOrientationUp];
            self.image = [self.image imageRotatedByDegrees:90.0];
        }
		else if (self.image.imageOrientation == UIImageOrientationLeft)
		{
            self.image = [UIImage imageWithCGImage:[self.image CGImage] scale:1.0 orientation: UIImageOrientationUp];
            self.image = [self.image imageRotatedByDegrees:-90.0];
        }
		else if (self.image.imageOrientation == UIImageOrientationDown)
		{
            self.image = [UIImage imageWithCGImage:[self.image CGImage] scale:1.0 orientation: UIImageOrientationUp];
            self.image = [self.image imageRotatedByDegrees:180.0];
        }
		
        self.cropSize = theSize;
        self.rescaleImage = willRescaleImage;
        self.rescaleFactor = theFactor;
        self.dismissAnimated = willDismissAnimated;
    }
	
    return self;
}

#pragma mark - View lifecycle

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self != nil)
	{
        self.image = [[UIImage alloc] init];
        self.cropSize = CGSizeMake(320.0, 320.0);
        self.rescaleImage = YES;
        self.rescaleFactor = 1.0;
        self.dismissAnimated = YES;
        self.overlayColor = [UIColor colorWithRed:0/255. green:0/255. blue:0/255. alpha:0.7];
        self.innerBorderColor = [UIColor colorWithRed:255./255. green:255./255. blue:255./255. alpha:0.7];
    }
	
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
	
	self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.title = @"Crop Image";
	
    UIBarButtonItem *importButton = [[UIBarButtonItem alloc] initWithTitle:@"Crop" style:UIBarButtonItemStyleBordered target:self action:@selector(handleCropButton)];
    [self.navigationItem setLeftBarButtonItem:importButton animated:NO];

	UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(handleCancelButton)];
	[self.navigationItem setRightBarButtonItem:cancelButton animated:NO];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self setupScrollView];
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Helper methods

- (void) setupScrollView
{
	CGFloat vertAdjustment = 0.0;
	CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
	CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
	
	if(scrollView != nil)
	{
		[scrollView removeFromSuperview];
		scrollView = nil;
		
		vertAdjustment = -(statusBarHeight + navBarHeight);
	}
	
	// Determine scroll zoom level
	CGFloat frameWidth = self.view.frame.size.width;
	CGFloat frameHeight = self.view.frame.size.height - navBarHeight;
	CGFloat imageWidth = CGImageGetWidth(self.image.CGImage);
	CGFloat imageHeight = CGImageGetHeight(self.image.CGImage);
	CGFloat scaleX = self.cropSize.width / imageWidth;
	CGFloat scaleY = self.cropSize.height / imageHeight;
	CGFloat scaleScroll = MAX(scaleX, scaleY);
	
	// Create scroll view
	scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
	scrollView.delegate = self;
	scrollView.scrollEnabled = YES;
	scrollView.contentSize = self.image.size;
	scrollView.pagingEnabled = NO;
	scrollView.directionalLockEnabled = NO;
	scrollView.showsHorizontalScrollIndicator = NO;
	scrollView.showsVerticalScrollIndicator = NO;
	
	// Limit zoom
	scrollView.maximumZoomScale = scaleScroll * 8.0;
	scrollView.minimumZoomScale = scaleScroll / 2.0;
	
	[self.view addSubview:scrollView];
	
	// Create top shaded overlay
	CGRect overlayTopRect = CGRectMake(0.0, navBarHeight, frameWidth, (frameHeight - self.cropSize.height) / 2.0);
	UIImageView *overlayTop = [[UIImageView alloc] initWithFrame:overlayTopRect];
	overlayTop.backgroundColor = self.overlayColor;
	[self.view addSubview:overlayTop];
	
	// Create bottom shaded overlay
	CGRect overlayBottomRect = CGRectMake(0.0, (navBarHeight + frameHeight) - overlayTopRect.size.height, frameWidth, overlayTopRect.size.height);
	UIImageView *overlayBottom = [[UIImageView alloc] initWithFrame:overlayBottomRect];
	overlayBottom.backgroundColor = self.overlayColor;
	[self.view addSubview:overlayBottom];
	
	// Create left shaded overlay
	CGRect overlayLeftRect = CGRectMake(0.0, navBarHeight + overlayTopRect.size.height, (frameWidth - self.cropSize.width) / 2.0, self.cropSize.height);
	UIImageView *overlayLeft = [[UIImageView alloc] initWithFrame:overlayLeftRect];
	overlayLeft.backgroundColor = self.overlayColor;
	[self.view addSubview:overlayLeft];
	
	// Create right shaded overlay
	CGRect overlayRightRect = CGRectMake(frameWidth - overlayLeftRect.size.width, overlayLeftRect.origin.y, overlayLeftRect.size.width, self.cropSize.height);
	UIImageView *overlayRight = [[UIImageView alloc] initWithFrame:overlayRightRect];
	overlayRight.backgroundColor = self.overlayColor;
	[self.view addSubview:overlayRight];
	
	// Create inner border overlay
	CGRect overlayInnerBorderRect = CGRectMake(overlayLeftRect.size.width, overlayLeftRect.origin.y, self.cropSize.width, self.cropSize.height);
	overlayInnerBorderRect = CGRectInset(overlayInnerBorderRect, -1.0, -1.0);
	UIImageView *overlayInnerBorder = [[UIImageView alloc] initWithFrame:overlayInnerBorderRect];
	overlayInnerBorder.backgroundColor = [UIColor clearColor];
	overlayInnerBorder.layer.masksToBounds = YES;
	overlayInnerBorder.layer.borderColor = self.innerBorderColor.CGColor;
	overlayInnerBorder.layer.borderWidth = 1.0;
	[self.view addSubview:overlayInnerBorder];
	
	// Add image view
	imageView = [[UIImageView alloc] initWithImage:self.image];
	[scrollView insertSubview:imageView atIndex:0];
	
	// Set initial zoom of scroll view
	[scrollView setZoomScale:scaleScroll animated:NO];
	
	CGPoint offset;
	UIEdgeInsets inset;
	
	if(scaleScroll == scaleX) // Portrait
	{
		offset = CGPointMake(-overlayLeft.frame.size.width,
										 (((imageHeight * scaleScroll) - frameHeight) / 2.0) + statusBarHeight + vertAdjustment);
		
		inset = UIEdgeInsetsMake(overlayTop.frame.size.height + self.cropSize.height - statusBarHeight,
											 overlayLeft.frame.size.width + (imageWidth * scaleScroll),
											 overlayBottom.frame.size.height + self.cropSize.height,
											 overlayRight.frame.size.width + (imageWidth * scaleScroll));
	}
	else // Landscape
	{
		offset = CGPointMake((((imageWidth * scaleScroll) - frameWidth) / 2.0),
										 -(overlayTop.frame.size.height - statusBarHeight - vertAdjustment));
		
		inset = UIEdgeInsetsMake(overlayTop.frame.size.height + self.cropSize.height - statusBarHeight,
											 overlayLeft.frame.size.width + self.cropSize.width,
											 overlayBottom.frame.size.height + self.cropSize.height,
											 overlayRight.frame.size.width + self.cropSize.width);
	}
	
	scrollView.contentOffset = offset;
	scrollView.contentInset = inset;
	
	// NSLog(@"ImageSize: %@", NSStringFromCGSize(self.image.size));
	// NSLog(@"contentSize: %@", NSStringFromCGSize(scrollView.contentSize));
	// NSLog(@"contentInset: %@", NSStringFromUIEdgeInsets(scrollView.contentInset));
	// NSLog(@"contentOffset: %@", NSStringFromCGPoint(scrollView.contentOffset));
	
	// Add gesture recognizer for double tap to reset image position
	UITapGestureRecognizer *doubletap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
	doubletap.numberOfTapsRequired = 2;
	[scrollView addGestureRecognizer:doubletap];
	
	// Add gesture recognizer for single tap to display image rotation menu
	UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
	[singleTap requireGestureRecognizerToFail:doubletap];
	singleTap.numberOfTapsRequired = 1;
	[scrollView addGestureRecognizer:singleTap];
}

UIImage* imageFromView (UIImage* srcImage, CGRect* rect)
{
    UIImage *fixOrientation = [srcImage fixOrientation];
    CGImageRef cr = CGImageCreateWithImageInRect(fixOrientation.CGImage, *rect);
    UIImage* cropped = [UIImage imageWithCGImage:cr];
    CGImageRelease(cr);
    return cropped;
}

#pragma mark - User interaction handle methods

- (void) handleCancelButton
{
	[self dismissViewControllerAnimated:self.dismissAnimated completion:nil];
}

- (void) handleCropButton
{
    // Define CGRect to crop
	double navBarHeight = self.navigationController.navigationBar.frame.size.height;
    double cropAreaHorizontalOffset = self.view.frame.size.width / 2.0 - self.cropSize.width / 2.0;
	double cropAreaVerticalOffset = navBarHeight + (self.view.frame.size.height - navBarHeight - self.cropSize.height) / 2.0;
    CGRect cropRect = CGRectMake(cropAreaHorizontalOffset, cropAreaVerticalOffset, self.cropSize.width, self.cropSize.height);

	// Get the image
	self.image = [ImageHelper clippedImageForRect:cropRect inView:self.view];
    
    [self dismissViewControllerAnimated:self.dismissAnimated completion:nil];
	
    [self.delegate imageCropperDidFinish:self withImage:self.image];
}

- (void) handleDoubleTap:(UIGestureRecognizer *)gestureRecognizer
{
	[self setupScrollView];
}

- (void) handleSingleTap:(UIGestureRecognizer *)gestureRecognizer
{
    // Single tap shows rotation menu
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:(id)self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Rotate Clockwise", @"Rotate Counterclockwise", nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    actionSheet.alpha = 0.9;
    actionSheet.tag = 1;
    [actionSheet showInView:self.view];
}

#pragma mark - Action sheet methods

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == 1)
	{
        if (buttonIndex == 0)
		{
            // Rotate clockwise
            [self rotateImageByDegrees:90.0];
        }
		else if (buttonIndex == 1)
		{
            // Rotate counterclockwise
            [self rotateImageByDegrees:-90.0];
        }
    }
}

#pragma mark - UIScrollView delegate methods

- (UIView *) viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return imageView;
}

#pragma mark - Image rotation

- (void) rotateImageByDegrees:(CGFloat)degrees
{
	self.image = [self.image imageRotatedByDegrees:degrees];
	
	[self setupScrollView];
}

@end
