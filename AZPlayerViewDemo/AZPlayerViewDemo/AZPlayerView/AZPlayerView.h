//
//  PlayerView.h
//  LiveViewDemo
//
//  Created by arronzhu on 16/7/18.
//  Copyright © 2016年 arronzhu. All rights reserved.
//

#import <UIKit/UIKit.h>
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

@class AZPlayerView;
@protocol AZPlayerViewDelegate <NSObject>
@optional
/**
 *  视频资源的状态转变，各个状态的操作逻辑应在在这个函数中处理
 */
- (void)playerView:(AZPlayerView *)playerView didChangeToNewState:(AZPlayerState)state url:(NSURL *)url;
/**
 *  每隔一秒抛出视频的播放时间和播放时间百分比
 *
 *  @param playerView      playerView
 *  @param currentTime     当前播放时间
 *  @param currentProgress 当前播放时间占比
 */
- (void)playerView:(AZPlayerView *)playerView playBackProgressChange:(CGFloat)currentTime :(CGFloat)currentProgress url:(NSURL *)url;
/**
 *  网络资源加载的进度
 */
- (void)playerView:(AZPlayerView *)playerView loadedProgressChange:(CGFloat)loadedProgress;

/**
 *  抛出错误
 *
 *  @param playerView playerView
 *  @param error      分为本地资源加载错误和网络资源加载错误两种,网络资源的错误码如下：
 *                    网络中断：-1005
 *                    无网络连接：-1009
 *                    请求超时：-1001
 *                    服务器内部错误：-1004
 *                    找不到服务器：-1003
 *  @param url        url
 */
- (void)playerView:(AZPlayerView *)playerView didFailWithError:(NSError *)error url:(NSURL *)url;
@end

@interface AZPlayerView : UIView
@property (nonatomic, readonly) AZPlayerState  state;                   //player的状态
@property (nonatomic, readonly) CGFloat        duration;                //视频总时间
@property (nonatomic, readonly) CGFloat        current;                 //当前播放时间
@property (nonatomic, readonly) CGFloat        progress;                //播放进度0~1之间
@property (nonatomic, readonly) CGSize         videoSize;               //视频尺寸

@property (nonatomic, assign  ) BOOL           stopInBackground;        //是否在后台播放，默认YES
@property (nonatomic, assign) CGFloat          rate;                    //播放速率 0.0相当于暂停, 1.0为原始速率
@property (nonatomic, assign) CGFloat          volume;                  //播放音量 0.0最小 1.0最大

/**每次在设置视频的其他属性后再设置url，确保属性生效*/
@property (nonatomic, strong) NSURL            *url;                    //资源URL
@property (nonatomic, assign) AZPlayerGravity  gravity;                 //默认AZPlayerGravityResize
@property (nonatomic, getter=isMuted) BOOL     muted;                   //默认NO 加载音频，设置YES以提升性能
@property (nonatomic, assign) BOOL             autoPlayAfterReady;      //加载完成后是否自动播放，默认YES
@property (nonatomic, assign) CGFloat          startTime;               //自动播放的开始时间，默认0，从头开始播放

@property (nonatomic, assign) BOOL             autoRepeat;              //循环播放，默认NO
/**网络资源*/
@property (nonatomic, strong) NSURL            *cacheUrl;               //若是获取网络资源，则必须在设置url之前设置缓存url
@property (nonatomic, readonly) CGFloat        loadedProgress;          //缓冲的进度
@property (nonatomic, readonly) BOOL           isFinishLoad;            //是否下载完毕

/**初始化方法*/
- (instancetype)initWithFrame:(CGRect)frame delegate:(id<AZPlayerViewDelegate>) delegate;

/**播放*/
- (void)play;

/**以下操作应在确保资源Ready后操作,若不在ready状态后操作请看log日志提示*/
/**
 *  暂停播放
 */
- (void)pause;

/**
 *  停止播放,等于seek到0秒然后暂停
 */
- (void)stop;

/**
 *  指定到某一事件点开始播放
 *
 *  @param seconds 时间点
 */
- (void)seekToTime:(CGFloat)seconds Pause:(BOOL) pause;

/**
 *  获取指定时间的缩略图
 */
- (UIImage *)getThumbnailAt:(CGFloat)seconds;

@end
