//
//  ViewController.h
//  PhotoSender
//
//  Created by Luca Severini on 4/24/15.
//  Copyright (c) 2015 Luca Severini. All rights reserved.
//

#import "TextImageView.h"
#import "GKImagePicker.h"
#import "GKImageCropper.h"
#import "SKPSMTPMessage.h"

@interface ViewController : UIViewController <GKImagePickerDelegate, GKImageCropperDelegate, SKPSMTPMessageDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate, UIAlertViewDelegate>
{
	CGFloat scrollOffset;
}

@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) IBOutlet TextImageView *previewView;
@property (nonatomic, retain) IBOutlet UIButton *photoBtn;
@property (nonatomic, retain) IBOutlet UIButton *printBtn;
@property (nonatomic, retain) IBOutlet UIButton *sendBtn;
@property (nonatomic, retain) IBOutlet UIButton *clearBtn;
@property (nonatomic, retain) IBOutlet UIButton *saveBtn;
@property (nonatomic, retain) IBOutlet UITextField *userText;
@property (nonatomic, retain) IBOutlet UISwitch *enhance;
@property (nonatomic, retain) IBOutlet UILabel *enhanceTxt;

@property (nonatomic, retain) GKImagePicker *picker;
@property (nonatomic, retain) GKImageCropper *cropper;
@property (nonatomic, retain) NSString *imageFileName;

- (IBAction) takeImageAction:(id)sender;
- (IBAction) sendAction:(id)sender;
- (IBAction) clearImageAction:(id)sender;
- (IBAction) showLargePreviewAction;
- (IBAction) enhanceImageAction:(id)sender;
- (IBAction) printAction:(id)sender;
- (IBAction) saveAction:(id)sender;

@end
