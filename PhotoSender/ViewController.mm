//
//  ViewController.m
//  PhotoSender
//
//  Created by Luca Severini on 4/24/15.
//  Copyright (c) 2015 Luca Severini. All rights reserved.
//

#import "ViewController.h"
#import "ImageHelper.h"
#import "PreviewController.h"
#import "PicToPrint.h"
#import "TextImageView.h"
#import "GKImagePicker.h"
#import "GKImageCropper.h"
#import "SKPSMTPMessage.h"
#import "ImageHelper.h"
#import "NetComm.h"

@implementation UIButton (Private)

- (void) enable
{
	self.enabled = YES;
	self.alpha = 1,0;
}

- (void) disable
{
	self.enabled = NO;
	self.alpha = 0.5;
}

@end

@implementation UISwitch (Private)

- (void) enable
{
	self.enabled = YES;
	self.alpha = 1.0;
}

- (void) disable
{
	self.on = NO;
	self.enabled = NO;
	self.alpha = 0.5;
}

@end

@implementation UILabel (Private)

- (void) enable
{
	self.alpha = 1.0;
}

- (void) disable
{
	self.alpha = 0.5;
}

@end

@implementation ViewController

- (void) viewDidLoad
{
    [super viewDidLoad];

	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(recropPhotoAction)];
	[self.imageView addGestureRecognizer:tap];

	UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showLargePreviewAction)];
	[self.previewView addGestureRecognizer:tap2];
	
	[self.sendBtn disable];
	[self.printBtn disable];
	[self.clearBtn disable];
	[self.saveBtn disable];
	[self.enhance disable];
	[self.enhanceTxt disable];

	[self clearImageAction:nil];
	[self removeAllImageFiles];

	CGFloat screenWidth = self.view.frame.size.width;
	CGFloat screenHeight = self.view.frame.size.height;
	
	if(screenHeight == 480.0)
	{
		CGFloat x;
		CGSize size;
		
		size = CGSizeMake(219.0, 184.0);
		x = (screenWidth - size.width) / 2.0;
		
		CGRect frame = self.imageView.frame;
		frame.size = size;
		frame.origin.x = x;
		self.imageView.frame = frame;
		
		frame = self.previewView.frame;
		frame.size = size;
		frame.origin.x = x;
		self.previewView.frame = frame;
	}
	else if(screenHeight == 568.0)
	{
		CGFloat x;
		CGSize size;
		
		size = CGSizeMake(260.0, 218.0);
		x = (screenWidth - size.width) / 2.0;
		
		CGRect frame = self.imageView.frame;
		frame.size = size;
		frame.origin.x = x;
		self.imageView.frame = frame;
		
		frame = self.previewView.frame;
		frame.size = size;
		frame.origin.x = x;
		frame.origin.y += 10.0;
		self.previewView.frame = frame;
	}
}

- (void) viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
	
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard:)];
	tap.delegate = self;
	tap.cancelsTouchesInView = NO;
	[self.view addGestureRecognizer:tap];
}

- (void) viewWillDisappear:(BOOL)animated
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
	
	[super viewWillDisappear:animated];
}

#pragma mark - IBAction methods

- (IBAction) enhanceImageAction:(id)sender
{
	NSDate *startTime = [NSDate date];

	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSArray *urls = [fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
	NSString *filePath = [NSString stringWithFormat:@"%@/LastCroppedImage.png", [urls[0] path]];
/*
	if(self.enhance.on)
	{
		[SVProgressHUD showWithStatus:@"Enhancing image" maskType:SVProgressHUDMaskTypeBlack];
	}

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
	^{
*/
		NSData *data = [[NSData alloc] initWithContentsOfFile:filePath];
		UIImage *image = [UIImage imageWithData:data];
		if(image != nil)
		{
			[self removeAllImageFiles];
			
			self.imageFileName = [self convertImage:image];
/*
			dispatch_main_async_safe(
			^{
				if(self.imageFileName != nil)
				{
					[self.sendBtn enable];
					[self.printBtn enable];
					[self.clearBtn enable];
					[self.saveBtn enable];
					[self.enhance enable];
					[self.enhanceTxt enable];
				}
				else
				{
					[self.sendBtn disable];
					[self.printBtn disable];
					[self.clearBtn disable];
					[self.saveBtn disable];
					[self.enhance disable];
					[self.enhanceTxt disable];
				}
			});
*/
		}
/*
		dispatch_main_async_safe(
		^{
			[SVProgressHUD dismiss];
		});
	});
*/
	NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:startTime];
	NSLog(@"Executed %g secs", time);
}

- (IBAction) recropPhotoAction
{
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSArray *urls = [fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
	NSString *filePath = [NSString stringWithFormat:@"%@/PickedImage.png", [urls[0] path]];

	NSData *data = [[NSData alloc] initWithContentsOfFile:filePath];
	UIImage *lastImage = [UIImage imageWithData:data];	
	if(lastImage != nil)
	{
		self.cropper = [[GKImageCropper alloc] init];
		self.cropper.delegate = self;
		self.cropper.image = lastImage;
		self.cropper.cropSize = CGSizeMake(262.0, 208.0);	// (131, 110) * 2
		self.cropper.rescaleImage = YES;
		self.cropper.rescaleFactor = 1.0;
		self.cropper.dismissAnimated = YES;
		self.cropper.overlayColor = [[UIColor whiteColor] colorWithAlphaComponent:0.8];
		self.cropper.innerBorderColor = [UIColor blackColor];
		[self presentViewController:[[UINavigationController alloc] initWithRootViewController:self.cropper] animated:YES completion:nil];
	}
}

- (IBAction) clearImageAction:(id)sender
{
	self.imageView.image = nil;
	[self.imageView setNeedsDisplay];
	
	self.previewView.image = nil;
	[self.previewView setNeedsDisplay];
	
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSArray *urls = [fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
	NSString *filePath = [NSString stringWithFormat:@"%@/PickedImage.png", [urls[0] path]];
	[fileManager removeItemAtPath:filePath error:nil];
	
	urls = [fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
	filePath = [NSString stringWithFormat:@"%@/%@", [urls[0] path], self.imageFileName];
	[fileManager removeItemAtPath:filePath error:nil];

	self.imageFileName = nil;

	[self.sendBtn disable];
	[self.printBtn disable];
	[self.clearBtn disable];
	[self.saveBtn disable];
	[self.enhance disable];
	[self.enhanceTxt disable];
}

- (IBAction) takeImageAction:(id)sender
{
    self.picker = [[GKImagePicker alloc] init];
    self.picker.delegate = self;
    self.picker.cropper.cropSize = CGSizeMake(262.0, 208.0);	// (131, 110) * 2
    self.picker.cropper.rescaleImage = YES;
	self.picker.cropper.rescaleFactor = 1.0;
    self.picker.cropper.dismissAnimated = YES;
    self.picker.cropper.overlayColor = [[UIColor whiteColor] colorWithAlphaComponent:0.8];
	self.picker.cropper.innerBorderColor = [UIColor blackColor];
	[self.picker presentPicker];
}

- (IBAction) showLargePreviewAction
{
	if(self.imageView.image != nil)
	{
		PreviewController *previewController = [[PreviewController alloc] init];
		[self presentViewController:previewController animated:YES completion:nil];
	}
}

- (IBAction) printAction:(id)sender
{
	if(self.imageFileName == nil)
	{
		NSString *msg = @"Please take a photo, crop and then send it.";
		[[[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
		return;
	}
	
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSArray *urls = [fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
	NSString *filePath = [NSString stringWithFormat:@"%@/%@", [urls[0] path], self.imageFileName];
	
	[SVProgressHUD showWithStatus:@"Printing" maskType:SVProgressHUDMaskTypeBlack];

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
	^{
		BOOL sendResult = [NetComm sendTo1401:filePath eofString:nil]; // @"$EOF "
		
		dispatch_main_async_safe(
		^{
			[SVProgressHUD dismiss];
			
			if(sendResult)
			{
				NSString *msg = @"Image successfully sent to the IBM 1401.";
				[[[UIAlertView alloc] initWithTitle:nil message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
			}
			else
			{
				NSString *msg = @"Error sending the image to the IBM 1401.";
				[[[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
			}
		});
	});
}

- (IBAction) sendAction:(id)sender
{
	if(self.imageFileName == nil)
	{
		NSString *msg = @"Please take a photo, crop and then send it.";
		[[[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
		return;
	}
	
	NSString *title = @"Send by email";
	NSString *msg = @"Type a valid email address";
	UIAlertView *popup = [[UIAlertView alloc] initWithTitle:title message:msg delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Send", nil];
	popup.alertViewStyle = UIAlertViewStylePlainTextInput;
	[popup textFieldAtIndex:0].keyboardType = UIKeyboardTypeEmailAddress;
	[popup show];
}

- (void) alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if(buttonIndex == 1)
	{
		NSFileManager *fileManager = [[NSFileManager alloc] init];
		NSArray *urls = [fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
		NSString *filePath = [NSString stringWithFormat:@"%@/%@", [urls[0] path], self.imageFileName];
		
		NSString *imagePath = [NSString stringWithFormat:@"%@.png", filePath];
		[fileManager removeItemAtPath:imagePath error:nil];
		
		// Generate PNG image of ascii representation
		TextImageView *asciiView = [[TextImageView alloc] initWithImage:filePath];
		asciiView.xScale = 1.0;
		UIImage *asciiImage = [ImageHelper imageWithView:asciiView scale:10.0];
		[UIImagePNGRepresentation(asciiImage) writeToFile:imagePath atomically:NO];
		
		[self sendEmailTo:[alertView textFieldAtIndex:0].text withAttachments:@[imagePath, filePath]];
	}
}

- (IBAction) saveAction:(id)sender
{
	if(self.imageFileName == nil)
	{
		NSString *msg = @"Please take a photo, crop and then send it.";
		[[[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
		return;
	}

	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSArray *urls = [fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
	NSString *filePath = [NSString stringWithFormat:@"%@/%@", [urls[0] path], self.imageFileName];
	
	// Generate PNG image of ascii representation
	TextImageView *asciiView = [[TextImageView alloc] initWithImage:filePath];
	asciiView.xScale = 1.0;
	UIImage *asciiImage = [ImageHelper imageWithView:asciiView scale:10.0];

	UIImageWriteToSavedPhotosAlbum(asciiImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (void) image:(UIImage *)image didFinishSavingWithError: (NSError *) error contextInfo: (void *) contextInfo
{
	if(error != nil)
	{
		NSString *msg = [NSString stringWithFormat:@"Error %@ saving the Photo in the Camera Roll", error.description];
		[[[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
	}
	else
	{
		NSString *msg = @"Photo saved in Camera Roll";
		[[[UIAlertView alloc] initWithTitle:nil message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
	}
}

#pragma mark - GKImagePicker delegate methods

- (void) imagePickerDidFinish:(GKImagePicker *)imagePicker withImage:(UIImage *)image
{
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSArray *urls = [fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
	NSString *filePath = [NSString stringWithFormat:@"%@/LastCroppedImage.png", [urls[0] path]];
	[UIImagePNGRepresentation(image) writeToFile:filePath atomically:YES];

	[self removeAllImageFiles];

	self.imageFileName = [self convertImage:image];
	if(self.imageFileName != nil)
	{
		[self.sendBtn enable];
		[self.printBtn enable];
		[self.clearBtn enable];
		[self.saveBtn enable];
		[self.enhance enable];
		[self.enhanceTxt enable];
	}
	else
	{
		[self.sendBtn disable];
		[self.printBtn disable];
		[self.clearBtn disable];
		[self.saveBtn disable];
		[self.enhance disable];
		[self.enhanceTxt disable];
	}
}

#pragma mark - SKPSMTPMessageDelegate delegate methods

- (void) messageSent:(SKPSMTPMessage*)message
{
	[SVProgressHUD dismiss];
}

- (void) messageFailed:(SKPSMTPMessage*)message error:(NSError*)error
{
	[SVProgressHUD dismiss];

	NSString *msg = [NSString stringWithFormat:@"Image not sent.\rError %d", (int)[error code]];
	[[[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

#pragma mark - GKImageCropper delegate methods

- (void) imageCropperDidFinish:(GKImageCropper *)imageCropper withImage:(UIImage *)image
{
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSArray *urls = [fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
	NSString *filePath = [NSString stringWithFormat:@"%@/LastCroppedImage.png", [urls[0] path]];
	[UIImagePNGRepresentation(image) writeToFile:filePath atomically:YES];

	[self removeAllImageFiles];

	self.imageFileName = [self convertImage:image];
	if(self.imageFileName != nil)
	{
		[self.sendBtn enable];
		[self.printBtn enable];
		[self.clearBtn enable];
		[self.saveBtn enable];
		[self.enhance enable];
		[self.enhanceTxt enable];
	}
	else
	{
		[self.sendBtn disable];
		[self.printBtn disable];
		[self.clearBtn disable];
		[self.saveBtn disable];
		[self.enhance disable];
		[self.enhanceTxt disable];
	}
}

#pragma mark - UITextFieldDelegate methods

- (BOOL) textFieldShouldReturn:(UITextField*)textField;
{
	[textField resignFirstResponder];
	return NO;
}

- (BOOL) textFieldShouldClear:(UITextField*)textField
{
	textField.text = @"";
	return NO;
}

#pragma mark - Private methods

void printData (int width, int height, unsigned char *data)
{
	int dataIdx = 0;
	for(int y = 0; y < height; y++)
	{
		for(int x = 0; x < width; x++)
		{
			printf("%02X ", data[dataIdx++]);
		}
		
		printf("\n");
	}
}

- (NSString*) convertImage:(UIImage*)image
{
	NSString *imageFileName = nil;
	
	UIImage *tmpImage = [ImageHelper convertImageToGray:image];
	self.imageView.image = [tmpImage copy];
	tmpImage = [ImageHelper scaleImage:tmpImage horizScale:1.0 vertScale:0.8];
	tmpImage = [ImageHelper scaleImage:tmpImage horizScale:0.5 vertScale:0.5];
	
	Byte *data = [ImageHelper convertUIImageToBitmapGray:tmpImage];
	
	// Normalization
	// 1. Find the lowest pixel value in the picture
	// 2. If the lowest value is more than zero, subtract that value from all pixels
	// 3. Find the highest pixel value in the picture
	// 4. If the highest value is less than 255 multiply each pixel value by 255/highest value
	Byte lowest = 255;
	Byte highest = 0;
	int count = tmpImage.size.width * tmpImage.size.height;
	for(int idx = 0; idx < count; idx++)
	{
		if(data[idx] < lowest)
		{
			lowest = data[idx];
		}
		
		if(data[idx] > highest)
		{
			highest = data[idx];
		}
	}
	
	if(lowest > 0)
	{
		for(int idx = 0; idx < count; idx++)
		{
			data[idx] -= lowest;
		}
	}
	
	if(highest < 255)
	{
		float val = 255.0 / highest;
		for(int idx = 0; idx < count; idx++)
		{
			data[idx] = (Byte)round(val * data[idx]);
		}
	}
	
	if([self.enhance isOn])
	{
		printf("Enhanced image\n");
		
		Byte *sortedData = (Byte*)malloc(count);
		memcpy(sortedData, data, count);
		
		for(int idx = 0; idx < count - 1; idx++)
		{
			for(int idx2 = idx + 1; idx2 < count; idx2++)
			{
				if(sortedData[idx] > sortedData[idx2])
				{
					Byte tmp = sortedData[idx];
					sortedData[idx] = sortedData[idx2];
					sortedData[idx2] = tmp;
				}
			}
		}
		
		Byte lowThreshold = sortedData[(int)(count * 0.1)];
		Byte highThreshold = sortedData[(int)(count * 0.9)];
		
		free(sortedData);
		
		for(int idx = 0; idx < count; idx++)
		{
			if(data[idx] < lowThreshold)
			{
				data[idx] = lowThreshold;
			}
			else if(data[idx] > highThreshold)
			{
				data[idx] = highThreshold;
			}
		}

		lowest = 255;
		highest = 0;
		for(int idx = 0; idx < count; idx++)
		{
			if(data[idx] < lowest)
			{
				lowest = data[idx];
			}
			
			if(data[idx] > highest)
			{
				highest = data[idx];
			}
		}
		
		if(lowest > 0)
		{
			for(int idx = 0; idx < count; idx++)
			{
				data[idx] -= lowest;
			}
		}
		
		if(highest < 255)
		{
			float val = 255.0 / highest;
			for(int idx = 0; idx < count; idx++)
			{
				data[idx] = (Byte)round(val * data[idx]);
			}
		}
	}
	
	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateFormat:@"MM-dd_hh:mm:ssa"];
	NSString *date = [dateFormat stringFromDate:[NSDate date]];
	
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSArray *urls = [fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
	NSString *path = [NSString stringWithFormat:@"%@/Image_%@.lst", [urls[0] path], date];
	[fileManager removeItemAtPath:path error:nil];
	
	int result = picToPrint([path UTF8String], data);
	if(result != 0)
	{
		dispatch_main_async_safe((
		^{
			NSString *msg = [NSString stringWithFormat:@"Can't generate the print file for the 1401.\rError %d", result];
			[[[UIAlertView alloc] initWithTitle:@"Sign Up Error" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
		}));
	}
	else
	{
		dispatch_main_async_safe(
		^{
			[self.previewView setImage:path];
		});
								 
		imageFileName = [path lastPathComponent];
	}
	
	free(data);
	
	return imageFileName;
}

- (void) sendEmailTo:(NSString*)recipient withAttachments:(NSArray*)files
{
	if(recipient.length == 0)
	{
		NSString *msg = [NSString stringWithFormat:@"Invalid email address"];
		[[[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
		return;
	}

	NSString *data1 = [[NSData dataWithContentsOfFile:[files objectAtIndex:0]] encodeBase64ForData];
	NSString *data2 = [[NSData dataWithContentsOfFile:[files objectAtIndex:1]] encodeBase64ForData];
	if(data1 == nil || data2 == nil)
	{
		NSString *msg = [NSString stringWithFormat:@"Photo delivery to %@ failed.", recipient];
		[[[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
		return;
	}

	SKPSMTPMessage *mailMsg = [[SKPSMTPMessage alloc] init];
	mailMsg.delegate = self;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	mailMsg.fromEmail = [defaults stringForKey:@"FromEmailPreference"];
	mailMsg.toEmail = recipient; // [defaults stringForKey:@"ToEmailPreference"];
	mailMsg.relayHost = [defaults stringForKey:@"RelayHostPreference"];
	mailMsg.requiresAuth = [defaults boolForKey:@"RequiresAuthPreference"];
	mailMsg.wantsSecure = [defaults boolForKey:@"WantsSecurePreference"];
	mailMsg.subject = @"IBM 1401 Photo";
	
	if(mailMsg.fromEmail.length == 0 || mailMsg.toEmail.length == 0 || mailMsg.relayHost.length == 0)
	{
		NSString *msg = @"Please check all email delivery preferences in Settings Panel.";
		[[[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
		return;
	}
	
	if (mailMsg.requiresAuth)
	{
		mailMsg.login = [defaults stringForKey:@"LoginPreference"];
		mailMsg.pass = [defaults stringForKey:@"PasswordPreference"];
		
		if(mailMsg.login.length == 0 || mailMsg.pass.length == 0)
		{
			NSString *msg = @"Please check all email delivery preferences in Settings Panel.";
			[[[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
			return;
		}
	}
	
	[SVProgressHUD showWithStatus:@"Emailing" maskType:SVProgressHUDMaskTypeBlack];
	
	// Only do this for self-signed certificates
	// mailMsg.validateSSLChain = NO;
	
	NSString *message = @"Greetings from IBM 1401 at Computer History Museum!\r\n";
	NSDictionary *plainPart = @{ kSKPSMTPPartContentTypeKey:@"text/plain; charset=UTF-8",
								 kSKPSMTPPartMessageKey:message,
								 kSKPSMTPPartContentTransferEncodingKey:@"8bit" };
	
	NSString *fileName = [[files objectAtIndex:0] lastPathComponent];
	NSString *contentType = [NSString stringWithFormat:@"image/png;\r\n\tx-unix-mode=0644;\r\n\tname=\"%@\"", fileName];
	NSString *contentDisposition = [NSString stringWithFormat:@"attachment;\r\n\tfilename=\"%@\"", fileName];
	NSDictionary *multiPart1 = @{ kSKPSMTPPartContentTypeKey:contentType,
								 kSKPSMTPPartContentDispositionKey:contentDisposition,
								 kSKPSMTPPartMessageKey:data1,
								 kSKPSMTPPartContentTransferEncodingKey:@"base64" };

	fileName = [[files objectAtIndex:1] lastPathComponent];
	contentType = [NSString stringWithFormat:@"text/plain;\r\n\tx-unix-mode=0644;\r\n\tname=\"%@\"", fileName];
	contentDisposition = [NSString stringWithFormat:@"attachment;\r\n\tfilename=\"%@\"", fileName];
	NSDictionary *multiPart2 = @{ kSKPSMTPPartContentTypeKey:contentType,
								  kSKPSMTPPartContentDispositionKey:contentDisposition,
								  kSKPSMTPPartMessageKey:data2,
								  kSKPSMTPPartContentTransferEncodingKey:@"base64" };

	mailMsg.parts = @[plainPart, multiPart1, multiPart2];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
	^{
		[mailMsg send];
	});
}

- (void) removeAllImageFiles
{
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSArray *urls = [fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
	NSArray *dirContents = [fileManager contentsOfDirectoryAtPath:(NSString*)[urls[0] path] error:nil];
	NSPredicate *filter = [NSPredicate predicateWithFormat:@"self ENDSWITH '.lst'"];
	NSArray *files = [dirContents filteredArrayUsingPredicate:filter];
	for(NSString *file in files)
	{
		NSString *filePath = [NSString stringWithFormat:@"%@/%@", [urls[0] path], file];
		[fileManager removeItemAtPath:filePath error:nil];
	}
}

- (void) keyboardWillShowNotification:(NSNotification*)notification
{
	// Animate the current view out of the way if is not already...
	if (self.view.frame.origin.y >= 0)
	{
		CGFloat keybHeight = [[notification.userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.height;
		scrollOffset = keybHeight;
			
		[self setViewMovedUp:YES];
	}
}

- (void) keyboardWillHideNotification:(NSNotification*)notification
{
	if (self.view.frame.origin.y < 0)
	{
		[self setViewMovedUp:NO];
	}
}

- (void) setViewMovedUp:(BOOL)movedUp
{
	if(scrollOffset == 0)
	{
		return;
	}
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3];
	
	CGRect rect = self.view.frame;
	
	if (movedUp)
	{
		// Move the view's origin up
		rect.origin.y -= scrollOffset;
	}
	else
	{
		// Move the view's origin down
		rect.origin.y += scrollOffset;
	}
	
	self.view.frame = rect;
	
	[UIView commitAnimations];
}

- (void) hideKeyboard:(UITapGestureRecognizer*)sender
{
	[self.userText resignFirstResponder];
}

@end




