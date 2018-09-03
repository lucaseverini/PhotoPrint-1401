//
//  AppDelegate.h
//  PhotoSender
//
//  Created by Luca Severini on 4/24/15.
//  Copyright (c) 2015 Luca Severini. All rights reserved.
//

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) ViewController *viewController;

@property (assign, nonatomic) BOOL antidebugTamperFlag;
@property (assign, nonatomic) BOOL debuggerDetectedFlag;
@property (assign, nonatomic) BOOL integrityBrokenFlag;
@property (assign, nonatomic) BOOL swizzlingDetectedFlag;
@property (assign, nonatomic) BOOL jailbreakDetectedFlag;

@end
