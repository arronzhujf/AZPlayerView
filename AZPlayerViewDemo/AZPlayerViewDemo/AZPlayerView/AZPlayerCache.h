//
//  AZPlayerCache.h
//  AZPlayerViewDemo
//
//  Created by arronzhu on 16/8/16.
//  Copyright © 2016年 arronzhu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AZPlayerWrapper.h"

@protocol AZPlayerCacheDelegate <NSObject>
@optional

- (void)player:(AZPlayerWrapper *)playerWrapper didChangeToNewState:(AZPlayerState)state url:(NSURL *)url;

- (void)player:(AZPlayerWrapper *)playerWrapper playBackProgressChange:(CGFloat)currentTime :(CGFloat)currentProgress url:(NSURL *)url;

- (void)player:(AZPlayerWrapper *)playerWrapper didFailWithError:(NSError *)error url:(NSURL *)url;
@end

@interface AZPlayerCache : NSObject
+ (instancetype)sharedInstance;

- (AZPlayerWrapper *)playerForURL:(NSURL *)url;

- (void)addObserver:(id<AZPlayerCacheDelegate>) obs forURL:(NSURL *)url;

- (void)removeObserver:(id<AZPlayerCacheDelegate>) obs forURL:(NSURL *)url;

/**清楚所有缓存和通知*/
- (void)clearCache;
@end
