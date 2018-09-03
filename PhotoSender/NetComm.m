//
//  NetComm.m
//  PhotoSender
//
//  Created by Luca Severini on 5/27/15.
//  Copyright (c) 2015 Luca Severini. All rights reserved.
//

#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>

#import "GCDAsyncUdpSocket.h"
#import "GCDAsyncSocket.h"

#import "NetComm.h"

@implementation NetComm

static GCDAsyncUdpSocket *udpSocket;
static GCDAsyncSocket *tcpSocket;
static dispatch_semaphore_t semaphore;
static dispatch_queue_t socketQueue;
static NSString *udpHost = @"255.255.255.255";
static NSInteger port = 25000;
static NSString *tcpHost;

+ (BOOL) sendTo1401:(NSString*)filePath eofString:(NSString*)eofStr
{
	NSString *fileName = [filePath lastPathComponent];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	udpHost = [defaults stringForKey:@"AddressPreference"];
	port = [[defaults stringForKey:@"PortPreference"] integerValue];
	
	NSLog(@"Sending file %@...", fileName);

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken,
	^{
		semaphore = dispatch_semaphore_create(1);
	});
	
	[self setupSockets];

	if(udpSocket == nil || tcpSocket == nil)
	{
		return NO;
	}
	
	// Acquire semaphore
	dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
	
	tcpHost = nil;

	NSData *data = [@"IBM1401-Photoserver" dataUsingEncoding:NSUTF8StringEncoding];
	[udpSocket sendData:data toHost:udpHost port:port withTimeout:10 tag:0];
	
	// Wait until semaphore is released for max 10 seconds
	dispatch_time_t waitTime = dispatch_time(DISPATCH_TIME_NOW, (uint64_t)(5.0 * NSEC_PER_SEC));
	
	long result = dispatch_semaphore_wait(semaphore, waitTime);
	
	// Release the semaphore in any case
	dispatch_semaphore_signal(semaphore);
	
	if(result != 0)
	{
		NSLog(@"Timeout waiting for server reply");
		return NO;
	}
	
	if (![self isValidIPAddress:tcpHost])
	{
		NSLog(@"Invalid host address");
		return NO;
	}

	NSLog(@"Host: %@", tcpHost);
	
	NSString *dataStr = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
	if (dataStr.length == 0)
	{
		NSLog(@"Invalid image data");
		return NO;
	}
	
	if(eofStr != nil && eofStr.length != 0)
	{
		dataStr = [dataStr stringByAppendingFormat:@"%@\n", eofStr];
	}
	
	NSError *error;
	if([tcpSocket connectToHost:tcpHost onPort:port withTimeout:10 error:&error])
	{
		NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
		[dateFormat setDateFormat:@"MM-dd_hh.mm.ssa"];
		NSString *date = [dateFormat stringFromDate:[NSDate date]];
		NSString *fileName = [NSString stringWithFormat:@"Image_%@", date];
		
		NSData *data = [[NSString stringWithFormat:@"@@@@BEGIN:%@\n", fileName] dataUsingEncoding:NSUTF8StringEncoding];
		[tcpSocket writeData:data withTimeout:10 tag:0];
		
		NSScanner *scanner = [NSScanner scannerWithString:dataStr];
		NSCharacterSet *set = [NSCharacterSet newlineCharacterSet];
		scanner.charactersToBeSkipped = set;
		
		NSString *rowStr;
		while ([scanner scanUpToCharactersFromSet:set intoString:&rowStr])
		{
			data = [[NSString stringWithFormat:@"@@@@DATA:%@\n@@@@", rowStr] dataUsingEncoding:NSUTF8StringEncoding];
			[tcpSocket writeData:data withTimeout:10 tag:0];
		}
		
		data = [@"@@@@END" dataUsingEncoding:NSUTF8StringEncoding];
		[tcpSocket writeData:data withTimeout:10 tag:0];
		
		[tcpSocket disconnectAfterWriting];
	}
	else
	{
		NSLog(@"Error %@ connecting to host %@", error.description, tcpHost);
	}

	return YES;
}

+ (void) setupSockets
{
	NSError *error = nil;
	
	if(socketQueue == nil)
	{
		socketQueue = dispatch_queue_create("com.1401-photosender.socketQueue", DISPATCH_QUEUE_CONCURRENT);
		if(socketQueue == nil)
		{
			NSLog(@"Error creating socket queue");
			return;
		}
	}
	
	if(udpSocket != nil)
	{
		[udpSocket close];
		udpSocket = nil;
	}
	
	udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:socketQueue];
	if(udpSocket == nil)
	{
		NSLog(@"Error initializing udp socket");
		return;
	}
	
	if (![udpSocket enableBroadcast:YES error:&error])
	{
		NSLog(@"Error setting broadcast: %@", error);
		return;
	}
	
	if (![udpSocket bindToPort:0 error:&error])
	{
		NSLog(@"Error binding: %@", error);
		return;
	}
	
	if (![udpSocket beginReceiving:&error])
	{
		NSLog(@"Error receiving: %@", error);
		return;
	}
	
	NSLog(@"UDP socket ready");
	
	if(tcpSocket != nil)
	{
		[tcpSocket disconnect];
		tcpSocket = nil;
	}

	tcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:socketQueue];
	if(tcpSocket == nil)
	{
		NSLog(@"Error initializing tcp socket");
		return;
	}
	
	NSLog(@"TCP socket ready");
}

#pragma mark UDP socket delegate methods

+ (void) udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
	// NSLog(@"UDP data sent");
}

+ (void) udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
	NSLog(@"UDP data not sent. Error %@", error.description);
}

+ (void) udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
	NSString *host = nil;
	uint16_t port = 0;
	[GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
	
	NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if (msg)
	{
		NSLog(@"UDP RECV from %@:%hu : %@", host, port, msg);
		
		NSArray *parts = [msg componentsSeparatedByString:@":"];
		if([[parts firstObject] isEqualToString:@"IBM1401-Photoserver"])
		{
			tcpHost = [parts lastObject];
		}
	}
	else
	{
		NSLog(@"UDP RECV from %@:%hu : Unknown message", host, port);
	}
	
	dispatch_semaphore_signal(semaphore);			// Release semaphore
}

#pragma mark TCP socket delegate methods

+ (void) socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
	NSLog(@"TCP socket connected to %@:%hu", host, port);
}

+ (void) socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	// NSLog(@"TCP data written");
}

+ (void) socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	NSString *host = nil;
	uint16_t port = 0;
	
	NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if (msg)
	{
		NSLog(@"TCP RECV from %@:%hu : %@", host, port, msg);
	}
	else
	{
		NSLog(@"TCP RECV from %@:%hu : Unknown message", host, port);
	}
}

+ (BOOL) isValidIPAddress:(NSString*)string
{
	const char *utf8 = [string UTF8String];
	struct in_addr dst;
	int success = inet_pton(AF_INET, utf8, &dst);
	if (success != 1)
	{
		struct in6_addr dst6;
		success = inet_pton(AF_INET6, utf8, &dst6);
	}
	
	return success == 1;
}

@end
