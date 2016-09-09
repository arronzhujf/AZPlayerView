//
//  PlayerView.m
//  LiveViewDemo
//
//  Created by arronzhu on 16/7/18.
//  Copyright © 2016年 arronzhu. All rights reserved.
//

#import "AZPlayerView.h"
#import "AZLoaderURLConnection.h"
#import "AZVideoRequestTask.h"
#import "NSString+AZVideo.h"

#define WeakSelf   __typeof(&*self) __weak   weakSelf   = self;
#define StrongSelf __typeof(&*self) __strong strongSelf = weakSelf;

@interface AZPlayerView () <AZLoaderURLConnectionDelegate, AZPlayerCacheDelegate>
@property (nonatomic, strong) AZPlayerWrapper        *playerWrapper;
@property (nonatomic, strong) AVURLAsset             *videoURLAsset;
@property (nonatomic, strong) AVPlayerItem           *playerItem;
@property (nonatomic, strong) AVAssetImageGenerator  *imageGenerator;

@property (nonatomic, assign) AZPlayerState          state;
@property (nonatomic, assign) CGFloat                duration;
@property (nonatomic, assign) CGFloat                current;
@property (nonatomic, assign) CGSize                 videoSize;

//@property (nonatomic, assign) BOOL                 isPauseByUser;           //是否被用户暂停
@property (nonatomic, assign) BOOL                   isLocalVideo;            //是否播放本地文件

/**网络资源*/
@property (nonatomic, strong) AZLoaderURLConnection  *resouerLoader;          //远程资源加载的代理类
@property (nonatomic, assign) CGFloat                loadedProgress;          //远程资源的加载进度
@property (nonatomic, assign) BOOL                   isFinishLoad;            //是否下载完毕
@property (nonatomic, assign, getter=isObserve) BOOL observe;                 //标记是否注册了通知
@property (nonatomic, weak) id<AZPlayerViewDelegate> delegate;
@end

@implementation AZPlayerView

- (instancetype)initWithFrame:(CGRect)frame delegate:(id<AZPlayerViewDelegate>)delegate{
    if (self = [super initWithFrame:frame]) {
        _delegate = delegate;
        _isFinishLoad = NO;
        _stopInBackground = YES;
        _autoPlayAfterReady = YES;
        _muted = NO;
        _startTime = 0;
        _rate = 1.0;
        _volume = 0.5;
        _autoRepeat = NO;
        _state = AZPlayerStateUnready;
        _gravity = AZPlayerGravityResize;
        _observe = NO;
        _maskImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _maskImageView.contentMode = UIViewContentModeScaleToFill;
        [self addSubview:_maskImageView];
    }
    return self;
}

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayer*)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    AVPlayerLayer *layer = (AVPlayerLayer *)[self layer];
    layer.frame = self.frame;
    switch (_gravity) {
        case AZPlayerGravityResizeAspect:
            layer.videoGravity = AVLayerVideoGravityResizeAspect;
            break;
        case AZPlayerGravityResizeAspectFill:
            layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            break;
        case AZPlayerGravityResize:
            layer.videoGravity = AVLayerVideoGravityResize;
            break;
        default:
            break;
    }
}

- (void)initPlayerWithUrl:(NSURL *)url {
    [self initUrlResetData];
    NSString *str = [url absoluteString];
    if ([str hasSuffix:@".m3u8"]) {//HLS直播
        self.isLocalVideo = NO;
        self.playerItem = [AVPlayerItem playerItemWithURL:url];
        self.player = [AVPlayer playerWithPlayerItem:_playerItem];
        self.player.muted = _muted;
        
        //add new observer
        [self addObserverForPlayback:_playerItem];
    } else if ([str hasPrefix:@"https"] || [str hasPrefix:@"http"]) {//网络资源
        NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
        components.scheme = kCustomVideoScheme;
        NSURL *playUrl = [components URL];
        NSString *md5File = [NSString stringWithFormat:@"%@.mp4", [[playUrl absoluteString] stringToMD5]];
        
        //判断本地有没有缓存文件，有的话直接读取缓存
        NSString *cachePath =  [[_cacheUrl absoluteString] stringByAppendingPathComponent:md5File];
        if ([[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
            NSURL *localURL = [NSURL fileURLWithPath:cachePath];
            _url = localURL;
            [self loadLoacalResource:localURL];
        } else {
            [self loadRemoteResource:url];
        }
    } else {//本地资源
        [self loadLoacalResource:url];
    }
}

/**替换URL时需要重新初始化的数据*/
- (void)initUrlResetData {
    _loadedProgress = 0.0;
    _current = 0.0;
    _duration = 0.0;
    _videoSize = CGSizeZero;
    _maskImageView.hidden = YES;
}

- (void)dealloc {
    [self.resouerLoader.task clearData];
    [[AZPlayerCache sharedInstance] removeObserver:self forURL:_url];
    if (!_isLocalVideo) {
        [_playerItem removeObserver:self forKeyPath:AZVideoPlayerItemStatusKeyPath];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

#pragma mark - Private
- (void)loadLoacalResource:(NSURL *)url {
    NSLog(@"load local resource");
    self.isLocalVideo = YES;
    [[AZPlayerCache sharedInstance] addObserver:self forURL:url];
    self.playerWrapper = [[AZPlayerCache sharedInstance] playerForURL:url];
    self.imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:_playerWrapper.videoURLAsset];
    self.player = _playerWrapper.player;
    self.playerItem = _playerWrapper.playerItem;
    self.player.muted = _muted;
}

- (void)loadRemoteResource:(NSURL *)url {
    NSLog(@"load remote resource");
    self.isLocalVideo = NO;
    self.resouerLoader          = [[AZLoaderURLConnection alloc] initWithCacheUrl:_cacheUrl];
    self.resouerLoader.delegate = self;
    
    NSURL *playUrl              = [_resouerLoader getSchemeVideoURL:url];
    self.videoURLAsset          = [AVURLAsset URLAssetWithURL:playUrl options:nil];
    [_videoURLAsset.resourceLoader setDelegate:_resouerLoader queue:dispatch_get_main_queue()];
    self.imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:_videoURLAsset];
    
    self.playerItem      = [AVPlayerItem playerItemWithAsset:_videoURLAsset];
    self.player = [AVPlayer playerWithPlayerItem:_playerItem];
    self.player.muted = _muted;
    
    //add new observer
    [self addObserverForPlayback:_playerItem];
}

- (void)addObserverForPlayback:(AVPlayerItem *)playerItem {
    [playerItem addObserver:self forKeyPath:AZVideoPlayerItemStatusKeyPath options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemPlaybackStalled:) name:AVPlayerItemPlaybackStalledNotification object:_playerItem];
}

- (void)calculateDownloadProgress:(AVPlayerItem *)playerItem
{
    NSArray *loadedTimeRanges = [playerItem loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval timeInterval = startSeconds + durationSeconds;// 计算缓冲总进度
    CMTime duration = playerItem.duration;
    CGFloat totalDuration = CMTimeGetSeconds(duration);
    self.loadedProgress = timeInterval / totalDuration;
}

- (void)bufferingSomeSecond
{
    // playbackBufferEmpty会反复进入，因此在bufferingOneSecond延时播放执行完之前再调用bufferingSomeSecond都忽略
    static BOOL isBuffering = NO;
    if (isBuffering) {
        return;
    }
    isBuffering = YES;
    
    // 需要先暂停一小会之后再播放，否则网络状况不好的时候时间在走，声音播放不出来
    [self.player pause];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        //        // 如果此时用户已经暂停了，则不再需要开启播放了
        //        if (self.isPauseByUser) {
        //            isBuffering = NO;
        //            return;
        //        }
        
        [self.player play];
        // 如果执行了play还是没有播放则说明还没有缓存好，则再次缓存一段时间
        isBuffering = NO;
        if (!self.playerItem.isPlaybackLikelyToKeepUp) {
            [self bufferingSomeSecond];
        }
    });
}

- (BOOL)isCurrentItem:(AVPlayerItem *)playerItem {
    if (![playerItem.asset isKindOfClass:[AVURLAsset class]]) {
        return NO;
    }
    AVURLAsset *urlAsset = (AVURLAsset *)playerItem.asset;
    NSURL *url = [urlAsset URL];
    if ([url.absoluteString hasPrefix:kCustomVideoScheme]) {
        NSURLComponents *components = [[NSURLComponents alloc] initWithURL:_url resolvingAgainstBaseURL:NO];
        components.scheme = kCustomVideoScheme;
        return [url isEqual:[components URL]];
    }
    return [url isEqual:_url];
}

#pragma mark - Getter & Setter
- (void)setUrl:(NSURL *)url {
    if (url == nil) {
        return;
    }
    if (url == _url) {
        [self stop];
        return;
    }
    //
    self.player.muted = YES;
    if (self.player && _isLocalVideo) {
        [[AZPlayerCache sharedInstance] removeObserver:self forURL:_url];
    } else if(self.player && !_isLocalVideo){
        [_playerItem removeObserver:self forKeyPath:AZVideoPlayerItemStatusKeyPath];
        [_playerItem removeObserver:self forKeyPath:AZVideoPlayerItemPlaybackLikelyToKeepUpKeyPath];
        [_playerItem removeObserver:self forKeyPath:AZVideoPlayerItemPresentationSizeKeyPath];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    _url = url;
    [self.resouerLoader.task clearData];
    [self initPlayerWithUrl:url];
}

- (void)setMuted:(BOOL)muted {
    _muted = muted;
    if (self.player) {
        self.player.muted = muted;
    }
}

- (void)setState:(AZPlayerState)state {
    _state = state;
    [self player:self.playerWrapper didChangeToNewState:state url:_url];
}

- (void)setLoadedProgress:(CGFloat)loadedProgress {
    if (_loadedProgress == loadedProgress) {
        return;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerView:loadedProgressChange:)])
    {
        [self.delegate playerView:self loadedProgressChange:loadedProgress];
    }
    _loadedProgress = loadedProgress;
}

- (void)setRate:(CGFloat)rate {
    rate = MAX(0.0, rate);
    _rate = rate;
    self.player.rate = rate;
}

- (void)setVolume:(CGFloat)volume {
    volume = MAX(0.0, volume);
    volume = MIN(volume, 1.0);
    _volume = volume;
    self.player.volume = volume;
}

- (CGSize)videoSize {
    NSArray *array = self.videoURLAsset.tracks;
    for (AVAssetTrack *track in array) {
        if ([track.mediaType isEqualToString:AVMediaTypeVideo]) {
            _videoSize = track.naturalSize;
        }
    }
    return _videoSize;
}

- (CGFloat)progress
{
    if (self.duration > 0) {
        return self.current / self.duration;
    }
    return 0;
}

#pragma mark - ACTION
- (void)play {
    if (self.state == AZPlayerStatePlaying) {
        return;
    }
    if (self.state != AZPlayerStateUnready && self.state != AZPlayerStateURLLoaded) {
        [self.player play];
        self.state = AZPlayerStatePlaying;
    } else {
        NSLog(@"PLPlayerView the url resource is not ready, video will play after ready, please wait.");
        _autoPlayAfterReady = YES;
    }
}

- (void)seekToTime:(CGFloat)seconds Pause:(BOOL)pause {
    if (self.state != AZPlayerStateUnready && self.state != AZPlayerStateURLLoaded) {
        seconds = MAX(0, seconds);
        seconds = MIN(seconds, self.duration);
        [self.player pause];
        [self.player seekToTime:CMTimeMake(seconds, 1)];
        if (!pause) {
            [self.player play];
        }
    } else {
        _autoPlayAfterReady = YES;
        _startTime = seconds;
        NSLog(@"PLPlayerView the url resource is not ready, PLPlayerView will seekToTime after ready,please wait.");
    }
}

- (UIImage *)getThumbnailAt:(CGFloat)seconds {
    if (self.state != AZPlayerStateUnready && self.state != AZPlayerStateURLLoaded) {
        seconds = MAX(0, seconds);
        seconds = MIN(seconds, self.duration);
        
        CMTime time = CMTimeMake(seconds, 1);
        NSError *error;
        CMTime actualTime;
        CGImageRef imageRef = [_imageGenerator copyCGImageAtTime:time actualTime:&actualTime error:&error];
        
        if (!error) {
            NSString *actualTimeString = (__bridge_transfer NSString *)CMTimeCopyDescription(NULL, actualTime);
            NSString *requestedTimeString = (__bridge_transfer NSString *)CMTimeCopyDescription(NULL, time);
            NSLog(@"Got thumbnail: Asked for %@, got %@", requestedTimeString,
                  actualTimeString);
        } else {
            if (self.delegate && [self.delegate respondsToSelector:@selector(playerView:didFailWithError:url:)]) {
                [self.delegate playerView:self didFailWithError:error url:_url];
            }
        }
        UIImage *thumbnail = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
        return thumbnail;
    } else {
        NSLog(@"PLPlayerView get thumbnail failed, the url resource is not ready!");
        return nil;
    }
}

- (void)pause {
    if (self.state == AZPlayerStatePause) {
        return;
    }
    if (self.state == AZPlayerStateStopped) {
        self.state = AZPlayerStatePause;
    }
    if (self.state != AZPlayerStateUnready && self.state != AZPlayerStateURLLoaded) {
        [self.player pause];
        self.state = AZPlayerStatePause;
    } else {
        _autoPlayAfterReady = NO;
        NSLog(@"PLPlayerView the url resource is not ready, video will pause when it is ready");
    }
}

- (void)stop {
    if (self.state == AZPlayerStateStopped) {
        return;
    }
    if (self.state != AZPlayerStateUnready && self.state != AZPlayerStateURLLoaded) {
        [self.player pause];
        [self.player seekToTime:kCMTimeZero];
        self.state = AZPlayerStateStopped;
    } else {
        _autoPlayAfterReady = NO;
    }
    
}

#pragma mark - Observer
- (void)appDidEnterBackground {
    if (self.stopInBackground) {
        [self pause];
    }
}
- (void)appDidEnterPlayGround {
    [self play];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if (![self isCurrentItem:playerItem]) {
        return;
    }
    if ([keyPath isEqualToString:AZVideoPlayerItemStatusKeyPath]) {
        if ([playerItem status] == AVPlayerItemStatusReadyToPlay) {
            self.duration = CMTimeGetSeconds(self.player.currentItem.duration);
            self.player.rate = _rate;
            self.player.volume = _volume;
            self.state = AZPlayerStateReady;
            if (_autoPlayAfterReady) {
                CGFloat seconds = MAX(0, _startTime);
                seconds = MIN(seconds, self.duration);
                [self.player seekToTime:CMTimeMake(seconds, 1)];
                [self.player play];
            } else {
                [self stop];
            }
        }
        else if ([playerItem status] == AVPlayerItemStatusFailed || [playerItem status] == AVPlayerItemStatusUnknown)
        {
            _maskImageView.hidden = NO;
            [self stop];
            if (self.delegate && [self.delegate respondsToSelector:@selector(playerView:didFailWithError:url:)])
            {
                [self.delegate playerView:self didFailWithError:playerItem.error url:_url];
            }
        }
        
    } else if ([keyPath isEqualToString:AZVideoPlayerItemLoadedTimeRangesKeyPath]) { //监听播放器的下载进度
        [self calculateDownloadProgress:playerItem];
    } else if ([keyPath isEqualToString:AZVideoPlayerItemPlaybackBufferEmptyKeyPath]) { //监听播放器在缓冲数据的状态
        if (playerItem.isPlaybackBufferEmpty) {
            self.state = AZPlayerStateBuffering;
        }
    } else if ([keyPath isEqualToString:AZVideoPlayerItemPlaybackLikelyToKeepUpKeyPath]) {
        
    } else if ([keyPath isEqualToString:AZVideoPlayerItemPresentationSizeKeyPath]) { //监测屏幕旋转
        
    }
    return;
}

- (void)playerItemDidReachEnd:(AVPlayerItem *)item {
    self.state = AZPlayerStateFinish;
}

- (void)playerItemPlaybackStalled:(AVPlayerItem *)item {
    [self bufferingSomeSecond];
    self.state = AZPlayerStateBuffering;
}

#pragma mark - AZPlayerCacheDelegate
- (void)player:(AZPlayerWrapper *)playerWrapper didChangeToNewState:(AZPlayerState)state url:(NSURL *)url {
    _state = state;
    if (state == AZPlayerStateURLLoaded) {
        self.playerWrapper = playerWrapper;
        self.player = playerWrapper.player;
        self.playerItem = playerWrapper.playerItem;
        self.player.muted = _muted;
    }
    if (state == AZPlayerStateReady && _autoPlayAfterReady == YES) {
        [self play];
    }
    if (state == AZPlayerStateFinish && _autoRepeat == YES) {
        [self seekToTime:0 Pause:NO];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerView:didChangeToNewState:url:)]) {
        [self.delegate playerView:self didChangeToNewState:state url:url];
    }
}

- (void)player:(AZPlayerWrapper *)playerWrapper playBackProgressChange:(CGFloat)currentTime :(CGFloat)currentProgress url:(NSURL *)url {
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerView:playBackProgressChange::url:)]) {
        [self.delegate playerView:self playBackProgressChange:currentTime :currentProgress url:url];
    }
}

- (void)player:(AZPlayerWrapper *)playerWrapper didFailWithError:(NSError *)error url:(NSURL *)url {
    _maskImageView.hidden = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerView:didFailWithError:url:)]) {
        [self.delegate playerView:self didFailWithError:error url:url];
    }
}
#pragma mark - AZLoaderURLConnectionDelegate

- (void)didFinishLoadingWithTask:(AZVideoRequestTask *)task
{
    _isFinishLoad = task.isFinishLoad;
}

- (void)didFailLoadingWithTask:(AZVideoRequestTask *)task withError:(NSError *)error
{
    _maskImageView.hidden = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerView:didFailWithError:url:)])
    {
        [self.delegate playerView:self didFailWithError:error url:_url];
    }
}

@end
