//  PlayerView.h
//  AZPlayerViewDemo
//
//  Created by arronzhu on 16/8/16.
//  Copyright © 2016年 arronzhu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class AZVideoRequestTask;

@protocol AZVideoRequestTaskDelegate <NSObject>

- (void)task:(AZVideoRequestTask *)task didReciveVideoLength:(NSUInteger)videoLength mimeType:(NSString *)mimeType;
- (void)didReciveVideoDataWithTask:(AZVideoRequestTask *)task;
- (void)didFinishLoadingWithTask:(AZVideoRequestTask *)task;
- (void)didFailLoadingWithTask:(AZVideoRequestTask *)task withError:(NSError *)error;

@end

@interface AZVideoRequestTask : NSObject

@property (nonatomic, strong, readonly) NSURL         *url;
@property (nonatomic, readonly)         NSUInteger    offset;

@property (nonatomic, readonly)         NSUInteger    videoLength;
@property (nonatomic, readonly)         NSUInteger    downLoadingOffset;
@property (nonatomic, readonly)         NSString      *mimeType;
@property (nonatomic, assign)           BOOL          isFinishLoad;

@property (nonatomic, weak)             id<AZVideoRequestTaskDelegate> delegate;

- (instancetype)initWithCachePath:(NSString *)cachePath;

- (void)setUrl:(NSURL *)url offset:(NSUInteger)offset;

- (void)cancel;

- (void)continueLoading;

- (void)clearData;

@end
