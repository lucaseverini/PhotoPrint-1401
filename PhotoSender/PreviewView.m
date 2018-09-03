//
//  PreviewView.m
//  PhotoSender
//
//  Created by Luca Severini on 4/24/15.
//  Copyright (c) 2015 Luca Severini. All rights reserved.
//

#import "PreviewView.h"
#import "TextImageView.h"

@implementation PreviewView

- (id) initWithCoder:(NSCoder*)coder
{
	self = [super initWithCoder:coder];
	if (self != nil)
	{
		self.imageView = [[TextImageView alloc] init];
		[self addSubview:self.imageView];
		
		self.contentSize = self.imageView.frame.size;
	}
	
	return self;
}

- (void) drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextScaleCTM(context, self.zoomScale, self.zoomScale);
}

@end


