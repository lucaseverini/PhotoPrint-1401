//
//  TextImageView.m
//  GKImagePicker
//
//  Created by Luca Severini on 4/24/15.
//  Copyright (c) 2015 Luca Severini. All rights reserved.
//

#import "TextImageView.h"

@implementation TextImageView

- (instancetype) init
{
	self = [super init];
	if (self != nil)
	{
		self.frame = CGRectMake(0.0, 0.0, IMAGE_WIDTH, IMAGE_HEIGHT);
		self.backgroundColor = [UIColor whiteColor];
		
		self.xScale = X_SCALE;
		self.yScale = Y_SCALE;
		self.yCompensation = HEIGHT_COMPENSATION;
		
		// Find the .lst image file in NSCachesDirectory
		NSFileManager *fileManager = [[NSFileManager alloc] init];
		NSArray *urls = [fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
		NSArray *dirContents = [fileManager contentsOfDirectoryAtPath:(NSString*)[urls[0] path] error:nil];
		NSPredicate *filter = [NSPredicate predicateWithFormat:@"self ENDSWITH '.lst'"];
		NSArray *files = [dirContents filteredArrayUsingPredicate:filter];
		if(files.count > 0)
		{
			NSString *imageFilePath = [NSString stringWithFormat:@"%@/%@", [urls[0] path], files[0]];
			[self setImage:imageFilePath];
			
			NSLog(@"imageFilePath: %@", imageFilePath);
		}
	}
	
	return self;
}

- (instancetype) initWithImage:(NSString*)imagePath
{
	self = [super init];
	if (self != nil)
	{
		self.frame = CGRectMake(0.0, 0.0, IMAGE_WIDTH, IMAGE_HEIGHT);
		self.backgroundColor = [UIColor whiteColor];
		
		self.xScale = X_SCALE;
		self.yScale = Y_SCALE;
		self.yCompensation = HEIGHT_COMPENSATION;

		[self setImage:imagePath];
	}
	
	return self;
}

- (instancetype) initWithCoder:(NSCoder*)coder
{
	self = [super initWithCoder:coder];
	if (self != nil)
	{
		self.backgroundColor = [UIColor whiteColor];

		self.xScale = X_SCALE;
		self.yScale = Y_SCALE;
		self.yCompensation = HEIGHT_COMPENSATION;
	}
	
	return self;
}

- (instancetype) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
	{
		self.backgroundColor = [UIColor whiteColor];
	}
	
	return self;
}

- (void) setImage:(NSString*)imagePath
{
	self.backgroundColor = [UIColor whiteColor];

	content = [NSString stringWithContentsOfFile:imagePath encoding:NSASCIIStringEncoding error:nil];
	
	[self setNeedsDisplay];
}

- (void) drawRect:(CGRect)rect
{
	static UIFont *font = nil;
	static NSDictionary *fontAttribs = nil;
	static NSCharacterSet *whiteSet = nil;
	static unichar lineBuffer[512];
	
	if(content.length == 0)
	{
		return;
	}

	// NSDate *startTime = [NSDate date];

	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// -------------------------------------------------------------------
#pragma message "Perhaps this could be improved by avoiding the scaleY compensation"
	
	CGContextScaleCTM(context, self.xScale, self.yScale);
	
	CGFloat scaleX = self.frame.size.width / IMAGE_WIDTH;
	CGFloat scaleY = self.frame.size.height / IMAGE_HEIGHT;
	
	// scaleY compensation
	if(scaleX == scaleY)
	{
		scaleY = scaleX * self.yCompensation;
	}
	
	if(scaleX != 1.0 || scaleY != 1.0)
	{
		// CGFloat scale = MIN(scaleX, scaleY);
		// CGContextScaleCTM(context, scale, scale);
		
		CGContextScaleCTM(context, scaleX, scaleY);
	}

	// -------------------------------------------------------------------
	
	CGContextSetShouldSmoothFonts(context, NO);
	CGContextSetShouldAntialias(context, NO);
	CGContextSetAllowsAntialiasing(context, NO);

	if(font == nil)
	{
		font = [UIFont fontWithName:FONT_NAME size:FONT_SIZE];
		fontAttribs = @{NSFontAttributeName:font, NSKernAttributeName:@(FONT_KERN)};
	}
	
	CGPoint position = CGPointMake(2.0, 2.0);

	NSScanner *scanner = [NSScanner scannerWithString:content];
	if(scanner == nil)
	{
		return;
	}

	if(whiteSet == nil)
	{
		whiteSet = [NSCharacterSet whitespaceCharacterSet];
	}

	scanner.caseSensitive = YES;
	scanner.charactersToBeSkipped = [NSCharacterSet newlineCharacterSet];

	NSString *line;
	while([scanner scanUpToString:@"\r" intoString:&line])
	{
		char firstChar = [line characterAtIndex:0];
						  
		if(firstChar == ' ')
		{
			position.y += FONT_SIZE;
		}
		
		if(firstChar == ' ' || firstChar == 'S')
		{
			line = [line substringFromIndex:1];
		}
		
		if([line stringByTrimmingCharactersInSet:whiteSet].length > 0)
		{
			// Replace some characters with something closer to what is printed by 1401
			// '=' -> 'x'
			// ')' -> 'o'
			// '+' -> '€'

#if 1 // Faster
			NSUInteger length = line.length;
			[line getCharacters:lineBuffer range:(NSRange){0, length}];

			for(NSUInteger idx = 0; idx < length; idx++)
			{
				switch(lineBuffer[idx])
				{
					case (unichar)'=':
						lineBuffer[idx] = (unichar)'x';
						break;
						
					case (unichar)')':
						lineBuffer[idx] = (unichar)'o';
						break;

					case (unichar)'+':
						lineBuffer[idx] = (unichar)0x20AC; // € in UTF8
						break;
				}
			}
			
			line = [NSString stringWithCharacters:lineBuffer length:length];
#else
			line = [line stringByReplacingOccurrencesOfString:@"=" withString:@"x"];
			line = [line stringByReplacingOccurrencesOfString:@")" withString:@"o"];
			line = [line stringByReplacingOccurrencesOfString:@"+" withString:@"€"];
#endif
			[line drawAtPoint:position withAttributes:fontAttribs];
		}
	}
	
	// NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:startTime];
	// NSLog(@"drawRect executed in %g secs", time);
}

@end


