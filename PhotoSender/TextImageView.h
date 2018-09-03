//
//  TextImageView.h
//  GKImagePicker
//
//  Created by Luca Severini on 4/24/15.
//  Copyright (c) 2015 Luca Severini. All rights reserved.
//

#define X_SCALE				1.2
#define Y_SCALE				1.0
#define IMAGE_WIDTH			1266	// Was 1284
#define IMAGE_HEIGHT		886
#define RATIO				1.4492	// Image width/height ratio
#define HEIGHT_COMPENSATION	1.24	// Height is 1.24 times the width
#define FONT_NAME			@"Menlo"
#define FONT_SIZE			10.0
#define FONT_KERN			2.2

@interface TextImageView : UIView
{
	NSString *content;
	
}

@property (nonatomic, assign) CGFloat xScale;
@property (nonatomic, assign) CGFloat yScale;
@property (nonatomic, assign) CGFloat yCompensation;

- (instancetype) initWithImage:(NSString*)imagePath;

- (void) setImage:(NSString*)imagePath;

@end
