//
//  AZPlayerCache.m
//  AZPlayerViewDemo
//
//  Created by arronzhu on 16/8/16.
//  Copyright © 2016年 arronzhu. All rights reserved.
//

#import "AZPlayerCache.h"

@interface AZPlayerCache() <AZPlayerWrapperDelegate>
/**
 *  url --> array weak observer<PLPlayerCacheDelegate>
 */
@property (nonatomic, strong) NSMutableDictionary *observerDic;
/**
 *  url --> PLPlayerWrapper
 */
@property (nonatomic, strong) NSMutableDictionary *playerWrapperDic;
@end

@implementation AZPlayerCache

+ (instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        _observerDic = [NSMutableDictionary new];
        _playerWrapperDic = [NSMutableDictionary new];
    }
    return self;
}

- (AZPlayerWrapper *)playerForURL:(NSURL *)url {
    if ([_playerWrapperDic objectForKey:url.absoluteString]) {
        AZPlayerWrapper *wrapper = [_playerWrapperDic objectForKey:url.absoluteString];
        [wrapper.player play];
        [wrapper.player setMuted:NO];
        return wrapper;
    }
    AZPlayerWrapper *wrapper = [[AZPlayerWrapper alloc] initWithURL:url delegate:self];
    [_playerWrapperDic setObject:wrapper forKey:url.absoluteString];
    return wrapper;
}

- (void)addObserver:(id<AZPlayerCacheDelegate>) obs forURL:(NSURL *)url {
    if ([_observerDic objectForKey:url.absoluteString]) {
        NSHashTable *table = [_observerDic objectForKey:url.absoluteString];
        [table addObject:obs];
    } else {
        NSHashTable *table = [NSHashTable weakObjectsHashTable];
        [table addObject:obs];
        [_observerDic setObject:table forKey:url.absoluteString];
    }
}

- (void)removeObserver:(id<AZPlayerCacheDelegate>) obs forURL:(NSURL *)url {
    if ([_observerDic objectForKey:url.absoluteString]) {
        NSHashTable *table = (NSHashTable *)[_observerDic objectForKey:url.absoluteString];
        if ([table containsObject:obs]) {
            [table removeObject:obs];
        }
        if ([table count] == 0) {
            [_observerDic removeObjectForKey:url.absoluteString];
        }
    }
}

- (void)clearCache {
    [_observerDic removeAllObjects];
    [_playerWrapperDic removeAllObjects];
}

#pragma mark - AZPlayerWrapperDelegate
- (void)player:(AZPlayerWrapper *)playerWrapper didChangeToNewState:(AZPlayerState)state url:(NSURL *)url {
    if ([_observerDic objectForKey:url.absoluteString]) {
        NSHashTable *table = [_observerDic objectForKey:url.absoluteString];
        for (id<AZPlayerCacheDelegate> obs in table) {
            [obs player:playerWrapper didChangeToNewState:state url:url];
        }
    }
}

- (void)player:(AZPlayerWrapper *)playerWrapper playBackProgressChange:(CGFloat)currentTime :(CGFloat)currentProgress url:(NSURL *)url {
    if ([_observerDic objectForKey:url.absoluteString]) {
        NSHashTable *table = [_observerDic objectForKey:url.absoluteString];
        for (id<AZPlayerCacheDelegate> obs in table) {
            [obs player:playerWrapper playBackProgressChange:currentTime :currentProgress url:url];
        }
    }
}

- (void)player:(AZPlayerWrapper *)playerWrapper didFailWithError:(NSError *)error url:(NSURL *)url {
    if ([_observerDic objectForKey:url.absoluteString]) {
        NSHashTable *table = [_observerDic objectForKey:url.absoluteString];
        for (id<AZPlayerCacheDelegate> obs in table) {
            [obs player:playerWrapper didFailWithError:error url:url];
        }
    }
}
@end
