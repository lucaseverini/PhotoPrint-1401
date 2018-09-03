//
//  AppDelegate.m
//  PhotoSender
//
//  Created by Luca Severini on 4/24/15.
//  Copyright (c) 2015 Luca Severini. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"

@implementation AppDelegate

static AppDelegate *delegate;

+ (instancetype) shared
{
	return delegate;
}

- (void) dealloc
{
	delegate = nil;
}

- (instancetype) init
{
	self = [super init];
	
	delegate = self;
	
	return self;
}

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if TARGET_IPHONE_SIMULATOR
	NSLog(@"App folder: %@", NSHomeDirectory());
#endif // TARGET_IPHONE_SIMULATOR
	
	[Fabric with:@[CrashlyticsKit]];
	[Crashlytics startWithAPIKey:@"88c9c4ad4fc9cf683851e90309df86b88651c49c"];
	
	NSURL *defaultPrefsFile = [[NSBundle mainBundle] URLForResource:@"DefaultSettings" withExtension:@"plist"];
	NSDictionary *defaultPrefs = [NSDictionary dictionaryWithContentsOfURL:defaultPrefsFile];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultPrefs];
	
	// Set the default values in iOS Settings Panel
	if(![[defaultPrefs objectForKey:@"DefaultSettingsSet"] boolValue])
	{
		for(NSString *key in [defaultPrefs allKeys])
		{
#ifdef DEBUG
			if([key isEqualToString:@"FromEmailPreference"] || [key isEqualToString:@"LoginPreference"] || [key isEqualToString:@"PasswordPreference"])
			{
				continue;
			}
#endif
			id value = [defaultPrefs objectForKey:key];
			[[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
		}
		
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		NSMutableDictionary *mutDict = [defaultPrefs mutableCopy];
		[mutDict setObject:@(YES) forKey:@"DefaultSettingsSet"];
		[mutDict writeToURL:defaultPrefsFile atomically:NO];
	}

	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.viewController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];

	return YES;
}

- (void) applicationWillResignActive:(UIApplication *)application
{
}

- (void) applicationDidEnterBackground:(UIApplication *)application
{
}

- (void) applicationWillEnterForeground:(UIApplication *)application
{
}

- (void) applicationDidBecomeActive:(UIApplication *)application
{
}

- (void) applicationWillTerminate:(UIApplication *)application
{
}

void debuggerDetectedCallback()
{
	NSLog(@"debuggerDetectedCallback called!!");
	
	if(![AppDelegate shared].debuggerDetectedFlag)
	{
		[AppDelegate shared].debuggerDetectedFlag = YES;
	}
}

void integrityBrokenCallback()
{
	NSLog(@"integrityBrokenCallback called!!");
	
	if(![AppDelegate shared].integrityBrokenFlag)
	{
		[AppDelegate shared].integrityBrokenFlag = YES;
	}
}

void antidebugTamperCallback()
{
	NSLog(@"antidebugTamperCallback called!!");
	
	if(![AppDelegate shared].antidebugTamperFlag)
	{
		[AppDelegate shared].antidebugTamperFlag = YES;
	}
}

void swizzlingDetectedCallback()
{
	NSLog(@"swizzlingDetectedCallback called!!");
	
	if(![AppDelegate shared].swizzlingDetectedFlag)
	{
		[AppDelegate shared].swizzlingDetectedFlag = YES;
	}
}

void jailbreakDetectedCallback()
{
	NSLog(@"jailbreakDetectedCallback called!!");
	
	if(![AppDelegate shared].jailbreakDetectedFlag)
	{
		[AppDelegate shared].jailbreakDetectedFlag = YES;
	}
}

@end
