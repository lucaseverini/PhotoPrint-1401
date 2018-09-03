//
//  GKImagePicker.m
//  GKImagePicker
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

#import "GKImagePicker.h"


@implementation UIImage (private)

- (UIImage*) normalizedImage
{
	if (self.imageOrientation == UIImageOrientationUp)
	{
		return self;
	}
	
	UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
	
	[self drawInRect:(CGRect){0, 0, self.size}];
	UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
	return normalizedImage;
}

@end

@interface GKImagePicker () <GKImageCropperDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

- (void) presentImageCropperWithImage:(UIImage *)image;

@end


@implementation GKImagePicker 

@synthesize delegate = _delegate;
@synthesize cropper = _cropper;

#pragma mark - View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
	{
        self.cropper = [[GKImageCropper alloc] init];
        self.cropper.delegate = self;
    }
	
    return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - View control

- (void) presentPicker
{
    // **********************************************
    // * Show action sheet that will allow image selection from camera or gallery
    // **********************************************
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:(id)self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Image from Camera", @"Image from Gallery", nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    actionSheet.alpha=0.90;
    actionSheet.tag = 1;
    [actionSheet showInView:[UIApplication sharedApplication].keyWindow];
}

- (void) presentImageCropperWithImage:(UIImage *)image {
    // **********************************************
    // * Show GKImageCropper
    // **********************************************
    self.cropper.image = image;
    [(UIViewController *)self.delegate presentViewController:[[UINavigationController alloc] initWithRootViewController:self.cropper] animated:YES completion:nil];
}

#pragma mark - Image picker methods

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (actionSheet.tag)
	{
        case 1:
            switch (buttonIndex)
		{
                case 0:
                    [self showCameraImagePicker];
                    break;
				
                case 1:
                    [self showGalleryImagePicker];
                    break;
            }
            break;
			
        default:
            break;
    }
}

- (void) showCameraImagePicker
{
#if TARGET_IPHONE_SIMULATOR
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Simulator" message:@"Camera not available." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
#elif TARGET_OS_IPHONE
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.delegate = self;
    picker.allowsEditing = NO;
    [(UIViewController*)self.delegate presentViewController:picker animated:YES completion:nil];
#endif
}

- (void) showGalleryImagePicker
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    picker.allowsEditing = NO;
    [(UIViewController*)self.delegate presentViewController:picker animated:YES completion:nil];
}

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
    [picker dismissModalViewControllerAnimated:NO];
    [self presentImageCropperWithImage:image];
}

- (void) imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info
{
    // Extract image from the picker
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:@"public.image"])
	{
		[SVProgressHUD showWithStatus:@"Importing image…" maskType:SVProgressHUDMaskTypeClear];
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
		^{
			UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];		
			UIImage *normImage = [image normalizedImage];

			NSFileManager *fileManager = [[NSFileManager alloc] init];
			NSArray *urls = [fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
			NSString *filePath = [NSString stringWithFormat:@"%@/PickedImage.png", [urls[0] path]];
			[UIImagePNGRepresentation(normImage) writeToFile:filePath atomically:YES];

			NSData *data = [[NSData alloc] initWithContentsOfFile:filePath];
			image = [UIImage imageWithData:data];

			dispatch_main_async_safe(
			^{
				[SVProgressHUD dismiss];
				
				[picker dismissViewControllerAnimated:YES completion:
				^{
					[self presentImageCropperWithImage:image];
				}];
			});
		});
    }
}

#pragma mark - GKImageCropper delegate methods

- (void) imageCropperDidFinish:(GKImageCropper *)imageCropper withImage:(UIImage *)image
{
    [self.delegate imagePickerDidFinish:self withImage:image];
}

@end
