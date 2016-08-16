//
//  PlayerView.h
//  AZPlayerViewDemo
//
//  Created by arronzhu on 16/8/16.
//  Copyright © 2016年 arronzhu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "AZPlayerCache.h"

@class AZPlayerView;
@protocol AZPlayerViewDelegate <NSObject>
@optional
/**
 *  视频资源的状态转变，各个状态的操作逻辑应在在这个函数中处理
 */
- (void)playerView:(AZPlayerView *)playerView didChangeToNewState:(AZPlayerState)state url:(NSURL *)url;
/**
 *  每隔一秒抛出视频的播放时间和播放时间百分比 TODO:网络资源暂未实现
 */
- (void)playerView:(AZPlayerView *)playerView playBackProgressChange:(CGFloat)currentTime :(CGFloat)currentProgress url:(NSURL *)url;
/**
 *  网络资源加载的进度
 */
- (void)playerView:(AZPlayerView *)playerView loadedProgressChange:(CGFloat)loadedProgress;

/**
 *  抛出错误
 */
- (void)playerView:(AZPlayerView *)playerView didFailWithError:(NSError *)error url:(NSURL *)url;
@end

@interface AZPlayerView : UIView
@property (nonatomic, readonly) AZPlayerState  state;                   //player的状态
@property (nonatomic, readonly) CGFloat        duration;                //视频总时间
@property (nonatomic, readonly) CGFloat        current;                 //当前播放时间
@property (nonatomic, readonly) CGFloat        progress;                //播放进度0~1之间
@property (nonatomic, readonly) CGSize         videoSize;               //视频尺寸

@property (nonatomic, assign) BOOL             stopInBackground;        //是否在后台播放，默认YES
@property (nonatomic, assign) CGFloat          rate;                    //播放速率 0.0相当于暂停, 1.0为原始速率
@property (nonatomic, assign) CGFloat          volume;                  //播放音量 0.0最小 1.0最大
@property (nonatomic, strong) UIImageView      *maskImageView;          //发生错误时候的遮罩层 使用:self.maskImageView.image = XXX
/**每次在设置视频的其他属性后再设置url，确保属性生效*/
@property (nonatomic, strong) NSURL            *url;                    //资源URL
@property (nonatomic, assign) AZPlayerGravity  gravity;                 //默认PLPlayerGravityResize
@property (nonatomic, getter=isMuted) BOOL     muted;                   //默认NO 加载音频，设置YES以提升性能
@property (nonatomic, assign) BOOL             autoPlayAfterReady;      //加载完成后是否自动播放，默认YES
@property (nonatomic, assign) CGFloat          startTime;               //自动播放的开始时间，默认0，从头开始播放
@property (nonatomic, assign) BOOL             autoRepeat;              //循环播放，默认NO
@property (nonatomic, assign) BOOL             cache;                   //是否使用缓存
/**网络资源*/
@property (nonatomic, strong) NSURL            *cacheUrl;               //若是获取网络资源，则必须在设置url之前设置缓存url
@property (nonatomic, readonly) CGFloat        loadedProgress;          //缓冲的进度
@property (nonatomic, readonly) BOOL           isFinishLoad;            //是否下载完毕

/**初始化方法*/
- (instancetype)initWithFrame:(CGRect)frame delegate:(id<AZPlayerViewDelegate>) delegate;

/**播放*/
- (void)play;

/**以下操作应在确保资源Ready后操作*/
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
