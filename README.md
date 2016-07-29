# AZPlayerView
一款iOS视频播放组件(UIView中嵌入AVPlayer),支持本地url和网络url,网络资源目前只支持mp4。

Usage:
就像使用UIView一样使用AZPlayerView!
初始化方法：- (instancetype)initWithFrame:(CGRect)frame delegate:(id<AZPlayerViewDelegate>) delegate；
本地资源在初始化后直接设置URL;
网络资源需要先设置cacheUrl再设置url(顺序不能乱)。

AZPlayerView接口提供了各种操作：
播放，暂停，任意指定时间点播放，获取任意时间点的缩略图

提供了获取视频各种属性的接口：
current, duration,progress,rate,volume,gravity等

同时AZPlayerView的delegate十分简洁：
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

开始使用吧！
