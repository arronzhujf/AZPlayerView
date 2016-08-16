//
//  NSString+MD5.h
//  AZPlayerViewDemo
//
//  Created by arronzhu on 16/8/16.
//  Copyright © 2016年 arronzhu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (AZVideo)

- (NSString *)stringToMD5;
+ (NSString *)calculateTimeWithTimeFormatter:(long long)timeSecond;

@end
