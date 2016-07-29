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

static NSString *const AZVideoPlayerItemStatusKeyPath = @"status";
static NSString *const AZVideoPlayerItemLoadedTimeRangesKeyPath = @"loadedTimeRanges";
static NSString *const AZVideoPlayerItemPlaybackBufferEmptyKeyPath = @"playbackBufferEmpty";
static NSString *const AZVideoPlayerItemPlaybackLikelyToKeepUpKeyPath = @"playbackLikelyToKeepUp";
static NSString *const AZVideoPlayerItemPresentationSizeKeyPath = @"presentationSize";

@interface AZPlayerView () <AZLoaderURLConnectionDelegate>
@property (nonatomic, strong) AVURLAsset          *videoURLAsset;
@property (nonatomic, strong) AVPlayerItem        *playerItem;
@property (nonatomic, strong) AVAssetImageGenerator *imageGenerator;
@property (nonatomic, strong) NSObject            *playbackTimeObserver;

@property (nonatomic, assign) AZPlayerState        state;
@property (nonatomic, assign) CGFloat              duration;
@property (nonatomic, assign) CGFloat              current;

//@property (nonatomic, assign) BOOL                 isPauseByUser;           //是否被用户暂停
@property (nonatomic, assign) BOOL                 isLocalVideo;            //是否播放本地文件

/**本地资源*/

/**网络资源*/
@property (nonatomic, strong) AZLoaderURLConnection *resouerLoader;          //远程资源加载的代理类
@property (nonatomic, assign) CGFloat               loadedProgress;          //远程资源的加载进度
@property (nonatomic, assign) BOOL                  isFinishLoad;            //是否下载完毕

@property (nonatomic, weak) id<AZPlayerViewDelegate> delegate;
@end

@implementation AZPlayerView

- (instancetype)initWithFrame:(CGRect)frame delegate:(id<AZPlayerViewDelegate>)delegate{
    if (self = [super initWithFrame:frame]) {
        _delegate = delegate;
        _loadedProgress = 0.0;
        _current = 0.0;
        _duration = 0.0;
        _rate = 1.0;
        _volume = 0.5;
        _isFinishLoad = NO;
        _stopInBackground = YES;
        _isLocalVideo = YES;
        _gravity = AZPlayerGravityResize;
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
    NSString *str = [url absoluteString];
    if ([str hasPrefix:@"https"] || [str hasPrefix:@"http"]) {//网络资源
        NSURLComponents *components = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
        components.scheme = kCustomVideoScheme;
        NSURL *playUrl = [components URL];
        NSString *md5File = [NSString stringWithFormat:@"%@.mp4", [[playUrl absoluteString] stringToMD5]];
        
        //判断本地有没有缓存文件，有的话直接读取缓存
        NSString *cachePath =  [[_cacheUrl absoluteString] stringByAppendingPathComponent:md5File];
        if ([[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
            NSURL *localURL = [NSURL fileURLWithPath:cachePath];
            [self loadLoacalResource:localURL];
        } else {
            [self loadRemoteResource:url];
        }
    } else {//本地资源
        [self loadLoacalResource:url];
    }
    
}

- (void)loadRemoteResource:(NSURL *)url {
    NSLog(@"load remote resource");
    self.isLocalVideo = NO;
    self.resouerLoader          = [[AZLoaderURLConnection alloc] initWithCacheUrl:_cacheUrl];
    self.resouerLoader.delegate = self;
    
    NSURL *playUrl              = [self.resouerLoader getSchemeVideoURL:url];
    self.videoURLAsset          = [AVURLAsset URLAssetWithURL:playUrl options:nil];
    [_videoURLAsset.resourceLoader setDelegate:self.resouerLoader queue:dispatch_get_main_queue()];
    
    self.playerItem      = [AVPlayerItem playerItemWithAsset:_videoURLAsset];
    self.imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:_videoURLAsset];
    
//    if (!self.player) {
        self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
//    } else {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
//        });
//    }

    [self.playerItem addObserver:self forKeyPath:AZVideoPlayerItemStatusKeyPath options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:AZVideoPlayerItemLoadedTimeRangesKeyPath options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:AZVideoPlayerItemPlaybackBufferEmptyKeyPath options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:AZVideoPlayerItemPlaybackLikelyToKeepUpKeyPath options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:AZVideoPlayerItemPresentationSizeKeyPath options:NSKeyValueObservingOptionNew context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemPlaybackStalled:) name:AVPlayerItemPlaybackStalledNotification object:self.playerItem];
}

- (void)loadLoacalResource:(NSURL *)url {
    NSLog(@"load local resource");
    self.videoURLAsset = [AVURLAsset URLAssetWithURL:url options:nil];
    self.imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:_videoURLAsset];
    NSString *tracksKey = @"tracks";
    WeakSelf
    [self.videoURLAsset loadValuesAsynchronouslyForKeys:@[tracksKey] completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error;
            AVKeyValueStatus status = [weakSelf.videoURLAsset statusOfValueForKey:tracksKey error:&error];
            
            if (status == AVKeyValueStatusLoaded) {
                self.isLocalVideo = YES;
                self.state = AZPlayerStateURLLoaded;
                weakSelf.playerItem = [AVPlayerItem playerItemWithURL:_url];
                if (!weakSelf.player) {
                    weakSelf.player = [AVPlayer playerWithPlayerItem:weakSelf.playerItem];
                } else {
                    [weakSelf.player replaceCurrentItemWithPlayerItem:weakSelf.playerItem];
                }
                
                [weakSelf.playerItem addObserver:weakSelf forKeyPath:AZVideoPlayerItemStatusKeyPath options:NSKeyValueObservingOptionNew context:nil];
                [weakSelf.playerItem addObserver:weakSelf forKeyPath:AZVideoPlayerItemLoadedTimeRangesKeyPath options:NSKeyValueObservingOptionNew context:nil];
                [weakSelf.playerItem addObserver:weakSelf forKeyPath:AZVideoPlayerItemPlaybackBufferEmptyKeyPath options:NSKeyValueObservingOptionNew context:nil];
                [weakSelf.playerItem addObserver:weakSelf forKeyPath:AZVideoPlayerItemPlaybackLikelyToKeepUpKeyPath options:NSKeyValueObservingOptionNew context:nil];
                [weakSelf.playerItem addObserver:weakSelf forKeyPath:AZVideoPlayerItemPresentationSizeKeyPath options:NSKeyValueObservingOptionNew context:nil];
                
                [[NSNotificationCenter defaultCenter] addObserver:weakSelf selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:weakSelf.playerItem];
                [[NSNotificationCenter defaultCenter] addObserver:weakSelf selector:@selector(playerItemPlaybackStalled:) name:AVPlayerItemPlaybackStalledNotification object:weakSelf.playerItem];

                
            } else {
                if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(playerView:didFailWithError:url:)]) {
                    [weakSelf.delegate playerView:weakSelf didFailWithError:error url:url];
                }
                NSLog(@"The asset's tracks were not loaded:\n%@", [error localizedDescription]);
            }
        });
    }];
}

- (void)dealloc {
    [self.resouerLoader.task clearData];
    [self removeObserver];
}

#pragma mark - Getter & Setter
- (void)setUrl:(NSURL *)url {
    _url = url;
    [self.resouerLoader.task clearData];
    [self removeObserver];
    [self initPlayerWithUrl:url];
}

- (void)setState:(AZPlayerState)state {
    _state = state;
    [self changeToNewState:state];
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

/**
 *  计算播放进度
 *
 *  @return 播放时间进度
 */
- (CGFloat)progress
{
    if (self.duration > 0) {
        return self.current / self.duration;
    }
    return 0;
}

#pragma mark - ACTION
- (void)play {
    self.state = AZPlayerStatePlaying;
    [self.player play];
}

- (void)seekToTime:(CGFloat)seconds {
    seconds = MAX(0, seconds);
    seconds = MIN(seconds, self.duration);
    
    [self.player pause];
    WeakSelf
    [self.player seekToTime:CMTimeMake(seconds, 1) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        [weakSelf.player play];
    }];
}

- (UIImage *)getThumbnailAt:(CGFloat)seconds {
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
}

- (void)pause {
    self.state = AZPlayerStatePause;
    [self.player pause];
}

- (void)stop {
    self.loadedProgress = 0;
    self.duration = 0;
    self.current = 0;
    self.state = AZPlayerStateStopped;
    [self seekToTime:0.0];
    [self.player pause];
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
    if ([keyPath isEqualToString:AZVideoPlayerItemStatusKeyPath]) {
        if ([playerItem status] == AVPlayerItemStatusReadyToPlay)
        {
            [self monitoringPlayback:playerItem];
            self.state = AZPlayerStateReady;
        }
        else if ([self.player.currentItem status] == AVPlayerItemStatusFailed || [self.player.currentItem status] == AVPlayerItemStatusUnknown)
        {
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

- (void)changeToNewState:(AZPlayerState)state {
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerView:didChangeToNewState:url:)]) {
        [self.delegate playerView:self didChangeToNewState:state url:_url];
    }
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    self.state = AZPlayerStateFinish;
}

- (void)playerItemPlaybackStalled:(NSNotification *)notification
{
    // 这里网络不好的时候，就会进入，不做处理，会在playbackBufferEmpty里面缓存之后重新播放
    self.state = AZPlayerStateBuffering;
}

- (void)removeObserver {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [self.playerItem removeObserver:self forKeyPath:AZVideoPlayerItemStatusKeyPath];
    [self.playerItem removeObserver:self forKeyPath:AZVideoPlayerItemLoadedTimeRangesKeyPath];
    [self.playerItem removeObserver:self forKeyPath:AZVideoPlayerItemPlaybackBufferEmptyKeyPath];
    [self.playerItem removeObserver:self forKeyPath:AZVideoPlayerItemPlaybackLikelyToKeepUpKeyPath];
    [self.playerItem removeObserver:self forKeyPath:AZVideoPlayerItemPresentationSizeKeyPath];
    [self.player removeTimeObserver:self.playbackTimeObserver];
}

#pragma mark - Private
- (void)monitoringPlayback:(AVPlayerItem *)playerItem {
    self.duration = CMTimeGetSeconds(self.player.currentItem.duration);
    self.player.rate = _rate;
    self.player.volume = _volume;
    WeakSelf
    self.playbackTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
        StrongSelf
        CGFloat current = playerItem.currentTime.value / playerItem.currentTime.timescale;
        if (strongSelf.current != current) {
            strongSelf.current = current;
            if (strongSelf.current > strongSelf.duration) {
                strongSelf.duration = strongSelf.current;
            }
            if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(playerView:playBackProgressChange::url:)]) {
                [strongSelf.delegate playerView:strongSelf playBackProgressChange:strongSelf.current :strongSelf.progress url:strongSelf.url];
            }
        }
    }];
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


#pragma mark - HCDLoaderURLConnectionDelegate

- (void)didFinishLoadingWithTask:(AZVideoRequestTask *)task
{
    _isFinishLoad = task.isFinishLoad;
}

- (void)didFailLoadingWithTask:(AZVideoRequestTask *)task withError:(NSError *)error
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerView:didFailWithError:url:)])
    {
        [self.delegate playerView:self didFailWithError:error url:_url];
    }
}

@end
