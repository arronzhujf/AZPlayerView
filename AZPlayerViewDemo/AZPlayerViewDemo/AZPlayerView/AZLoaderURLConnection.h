//  PlayerView.h
//  LiveViewDemo
//
//  Created by arronzhu on 16/7/18.
//  Copyright © 2016年 arronzhu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "AZVideoRequestTask.h"

@protocol AZLoaderURLConnectionDelegate <NSObject>

- (void)didFinishLoadingWithTask:(AZVideoRequestTask *)task;
- (void)didFailLoadingWithTask:(AZVideoRequestTask *)task withError:(NSError *)error;

@end

static NSString *const kCustomVideoScheme = @"streaming";
@interface AZLoaderURLConnection : NSURLConnection <AVAssetResourceLoaderDelegate>

@property (nonatomic, strong) AZVideoRequestTask *task;
@property (nonatomic, weak  ) id<AZLoaderURLConnectionDelegate> delegate;

- (instancetype)initWithCacheUrl:(NSURL *)url;

- (NSURL *)getSchemeVideoURL:(NSURL *)url;

@end
