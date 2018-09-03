//
//  NetComm.h
//  PhotoSender
//
//  Created by Luca Severini on 5/27/15.
//  Copyright (c) 2015 Luca Severini. All rights reserved.
//

@interface NetComm : NSObject

+ (BOOL) sendTo1401:(NSString*)filePath eofString:(NSString*)eofStr;

@end
