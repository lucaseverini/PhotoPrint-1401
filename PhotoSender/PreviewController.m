//
//  PreviewController.m
//  PhotoSender
//
//  Created by Luca Severini on 4/24/15.
//  Copyright (c) 2015 Luca Severini. All rights reserved.
//

#import "PreviewController.h"
#import "PreviewView.h"
#import "TextImageView.h"

@implementation PreviewController

- (void) viewDidLoad
{
    [super viewDidLoad];

	UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
	tapGesture.numberOfTapsRequired = 2;
	[self.preview addGestureRecognizer:tapGesture];
}

- (void) viewDidUnload
{
    [super viewDidUnload];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	self.preview.maximumZoomScale = 4.0;
	self.preview.minimumZoomScale = 0.25;

	NSLog(@"scrollFrame: %@", NSStringFromCGRect(self.preview.frame));
	NSLog(@"imageFrame: %@", NSStringFromCGRect(((PreviewView*)self.preview).imageView.frame));
	NSLog(@"contentSize: %@", NSStringFromCGSize(self.preview.contentSize));
	NSLog(@"contentOffset: %@", NSStringFromCGPoint(self.preview.contentOffset));
	NSLog(@"contentScaleFactor: %@", @(self.preview.contentScaleFactor));
	
	CGSize frameSize = self.preview.frame.size;
	CGSize imgSize = ((PreviewView*)self.preview).imageView.frame.size;
	
	CGFloat prop = (frameSize.width / imgSize.width);
	CGFloat screenScale = [[UIScreen mainScreen] scale];
	self.preview.zoomScale = prop * screenScale;

	CGSize contentSize = CGSizeMake(self.preview.contentSize.width * prop * screenScale, self.preview.contentSize.height * prop * screenScale);
	self.preview.contentSize = contentSize;
	
	startContentSize = self.preview.contentSize;
	startZoomScale = self.preview.zoomScale;
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - User interaction methods

- (IBAction) handleBackButton:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void) handleTapGesture:(UITapGestureRecognizer *)sender
{
	if (sender.state == UIGestureRecognizerStateRecognized)
	{
		self.preview.zoomScale = startZoomScale;
		self.preview.contentSize = startContentSize;
		self.preview.contentOffset = CGPointMake(0.0, 0.0);
	}
}

#pragma mark - UIScrollViewDelegate methods

- (void) scrollViewDidScroll:(UIScrollView*)scrollView
{
	[scrollView setNeedsDisplay];
}

- (UIView*) viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	return ((PreviewView*)scrollView).imageView;
}

- (void) scrollViewDidEndZooming:(UIScrollView*)scrollView withView:(UIView*)view atScale:(CGFloat)scale
{
	CGFloat screenScale =  [[UIScreen mainScreen] scale];
	CGFloat width = self.preview.contentSize.width / screenScale;
	CGFloat height = self.preview.contentSize.height / screenScale;
	CGSize contentSize = CGSizeMake(width, height * ((PreviewView*)self.preview).imageView.yCompensation);
	self.preview.contentSize = contentSize;
}

@end





