# AZPlayerView

一款iOS视频播放组件(UIView中嵌入AVPlayer),支持本地url和网络url,网络资源目前只支持mp4。支持网络MP4资源缓存本地。

AZPlayer专为小视频定制，为内嵌入tableview的性能优化实现了AVPlayer的缓存机制，支持动态设置url，更方便嵌入UITableViewCell。

##Usage:

就像初始化UIView一样初始化AZPlayerView。

本地资源在初始化后直接设置URL;

网络资源需要先设置cacheUrl再设置url(顺序不能乱)。

```
- (instancetype)initWithFrame:(CGRect)frame delegate:(id<AZPlayerViewDelegate>) delegate;
- 设置各种需要的属性
- 设置url
- 然后add进你的superView吧！
```



你不必去了解底层缓存机制，组件帮你做好了一切通知的remove和add,你只需要在小视频销毁之后调用一次:
```
[[PLPlayerCache sharedInstance] clearCache];
```



##接口介绍:
AZPlayerView提供了获取视频各种属性的接口：
current, duration,progress,rate,volume,gravity等。


```
@property (nonatomic, readonly) AZPlayerState  state;                   //player的状态
@property (nonatomic, readonly) CGFloat        duration;                //视频总时间
@property (nonatomic, readonly) CGFloat        current;                 //当前播放时间
@property (nonatomic, readonly) CGFloat        progress;                //播放进度0~1之间
@property (nonatomic, readonly) CGSize         videoSize;               //视频尺寸

@property (nonatomic, assign  ) BOOL           stopInBackground;        //是否在后台播放，默认YES
@property (nonatomic, assign) CGFloat          rate;                    //播放速率 0.0相当于暂停, 1.0为原始速率
@property (nonatomic, assign) CGFloat          volume;                  //播放音量 0.0最小 1.0最大
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
```

AZPlayerView接口提供了各种操作：
播放，暂停，任意指定时间点播放，获取任意时间点的缩略图
```
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
```


同时AZPlayerView的delegate也十分简洁：
```
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
```
```
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
- (void)playerView:(PLPlayerView *)playerView didFailWithError:(NSError *)error url:(NSURL *)url;
```


开始使用吧！
