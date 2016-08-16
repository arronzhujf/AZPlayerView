//
//  AZPlayerWrapper.h
//  AZPlayerViewDemo
//
//  Created by arronzhu on 16/8/16.
//  Copyright © 2016年 arronzhu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, AZPlayerState) {
    AZPlayerStateUnready = 1,      //未加载
    AZPlayerStateURLLoaded,        //本地资源加载成功
    AZPlayerStateBuffering,        //网络资源网络阻塞，缓冲后会继续播放
    AZPlayerStateReady,            //准备播放
    AZPlayerStatePlaying,          //正在播放
    AZPlayerStateStopped,          //播放结束
    AZPlayerStatePause,            //暂停播放
    AZPlayerStateFinish,           //播放完成
};

typedef NS_ENUM(NSInteger, AZPlayerGravity) {
    AZPlayerGravityResizeAspect = 1,
    AZPlayerGravityResizeAspectFill,
    AZPlayerGravityResize,
};

static NSString *const AZVideoPlayerItemStatusKeyPath = @"status";
static NSString *const AZVideoPlayerItemLoadedTimeRangesKeyPath = @"loadedTimeRanges";
static NSString *const AZVideoPlayerItemPlaybackBufferEmptyKeyPath = @"playbackBufferEmpty";
static NSString *const AZVideoPlayerItemPlaybackLikelyToKeepUpKeyPath = @"playbackLikelyToKeepUp";
static NSString *const AZVideoPlayerItemPresentationSizeKeyPath = @"presentationSize";

@class AZPlayerWrapper;
@protocol AZPlayerWrapperDelegate <NSObject>
@optional
/**视频资源的状态转变，各个状态的操作逻辑应在在这个函数中处理*/
- (void)player:(AZPlayerWrapper *)playerWrapper didChangeToNewState:(AZPlayerState)state url:(NSURL *)url;

/**每隔一秒抛出视频的播放时间和播放时间百分比*/
- (void)player:(AZPlayerWrapper *)playerWrapper playBackProgressChange:(CGFloat)currentTime :(CGFloat)currentProgress url:(NSURL *)url;

/**抛出错误*/
- (void)player:(AZPlayerWrapper *)playerWrapper didFailWithError:(NSError *)error url:(NSURL *)url;
@end

@interface AZPlayerWrapper : NSObject
@property (nonatomic, strong) AVPlayer               *player;
@property (nonatomic, strong) AVPlayerItem           *playerItem;
@property (nonatomic, strong) AVURLAsset             *videoURLAsset;
@property (nonatomic, readonly) CGSize               videoSize;
@property (nonatomic, readonly) CGFloat              progress;

- (instancetype)initWithURL:(NSURL *)url delegate:(id<AZPlayerWrapperDelegate>) delegate;
@end
