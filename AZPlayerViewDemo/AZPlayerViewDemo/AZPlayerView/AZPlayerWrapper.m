//
//  AZPlayerWrapper.m
//  AZPlayerViewDemo
//
//  Created by arronzhu on 16/8/16.
//  Copyright © 2016年 arronzhu. All rights reserved.
//

#import "AZPlayerWrapper.h"

#define WeakSelf   __typeof(&*self) __weak   weakSelf   = self;
#define StrongSelf __typeof(&*self) __strong strongSelf = weakSelf;

@interface AZPlayerWrapper()
@property (nonatomic, weak) id<AZPlayerWrapperDelegate> delegate;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, assign) AZPlayerState          state;
@property (nonatomic, strong) NSObject               *playbackTimeObserver;

@property (nonatomic, assign) CGFloat                duration;
@property (nonatomic, assign) CGFloat                current;
@property (nonatomic, assign) CGSize                 videoSize;
@end
@implementation AZPlayerWrapper

- (instancetype)initWithURL:(NSURL *)url delegate:(id<AZPlayerWrapperDelegate>) delegate{
    if (self = [super init]) {
        _url = url;
        _delegate  = delegate;
        [self initPlayer];
    }
    return self;
}

- (void)initPlayer {
    self.videoURLAsset = [AVURLAsset URLAssetWithURL:_url options:nil];
    NSString *tracksKey = @"tracks";
    [self.videoURLAsset loadValuesAsynchronouslyForKeys:@[tracksKey] completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error;
            AVKeyValueStatus status = [self.videoURLAsset statusOfValueForKey:tracksKey error:&error];
            if (status == AVKeyValueStatusLoaded) {
                [self loadedLocalAssetForPlay];
            } else {
                if (self.delegate && [self.delegate respondsToSelector:@selector(player:didFailWithError:url:)]) {
                    [self.delegate player:self didFailWithError:error url:_url];
                }
                NSLog(@"The asset's tracks were not loaded:\n%@", [error localizedDescription]);
            }
        });
    }];
    
}

- (void)loadedLocalAssetForPlay {
    self.playerItem = [AVPlayerItem playerItemWithAsset:_videoURLAsset];
    self.player = [AVPlayer playerWithPlayerItem:_playerItem];
    
    [self addObserverForPlayback:_playerItem];
    self.state = AZPlayerStateURLLoaded;
}

- (void)addObserverForPlayback:(AVPlayerItem *)playerItem {
    WeakSelf
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemPlaybackStalled:) name:AVPlayerItemPlaybackStalledNotification object:_playerItem];
    self.playbackTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
        StrongSelf
        CGFloat current = playerItem.currentTime.value / playerItem.currentTime.timescale;
        if (strongSelf.current != current) {
            strongSelf.current = current;
            if (strongSelf.current > strongSelf.duration) {
                strongSelf.duration = strongSelf.current;
            }
            if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(player:playBackProgressChange::url:)]) {
                [strongSelf.delegate player:strongSelf playBackProgressChange:strongSelf.current :strongSelf.progress url:strongSelf.url];
            }
        }
    }];
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

- (void)setState:(AZPlayerState)state {
    _state = state;
    [self changeToNewState:state];
}

- (void)setPlayerItem:(AVPlayerItem *)playerItem {
    [_playerItem removeObserver:self forKeyPath:AZVideoPlayerItemStatusKeyPath];
    [_playerItem removeObserver:self forKeyPath:AZVideoPlayerItemPlaybackLikelyToKeepUpKeyPath];
    [_playerItem removeObserver:self forKeyPath:AZVideoPlayerItemPresentationSizeKeyPath];
    
    _playerItem = playerItem;
    
    [playerItem addObserver:self forKeyPath:AZVideoPlayerItemStatusKeyPath options:NSKeyValueObservingOptionNew context:nil];
    [playerItem addObserver:self forKeyPath:AZVideoPlayerItemPlaybackLikelyToKeepUpKeyPath options:NSKeyValueObservingOptionNew context:nil];
    [playerItem addObserver:self forKeyPath:AZVideoPlayerItemPresentationSizeKeyPath options:NSKeyValueObservingOptionNew context:nil];
}

- (void)dealloc {
    [_playerItem removeObserver:self forKeyPath:AZVideoPlayerItemStatusKeyPath];
    [_playerItem removeObserver:self forKeyPath:AZVideoPlayerItemPlaybackLikelyToKeepUpKeyPath];
    [_playerItem removeObserver:self forKeyPath:AZVideoPlayerItemPresentationSizeKeyPath];
    [self.player removeTimeObserver:_playbackTimeObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - observer
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:AZVideoPlayerItemStatusKeyPath]) {
        if ([playerItem status] == AVPlayerItemStatusReadyToPlay) {
            self.duration = CMTimeGetSeconds(self.player.currentItem.duration);
            self.state = AZPlayerStateReady;
        }
        else if ([playerItem status] == AVPlayerItemStatusFailed || [playerItem status] == AVPlayerItemStatusUnknown)
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(player:didFailWithError:url:)])
            {
                [self.delegate player:self didFailWithError:playerItem.error url:_url];
            }
        }
        
    } else if ([keyPath isEqualToString:AZVideoPlayerItemPlaybackLikelyToKeepUpKeyPath]) {
        
    } else if ([keyPath isEqualToString:AZVideoPlayerItemPresentationSizeKeyPath]) { //监测屏幕旋转
        
    }
    return;
}

- (void)changeToNewState:(AZPlayerState)state {
    if (self.delegate && [self.delegate respondsToSelector:@selector(player:didChangeToNewState:url:)]) {
        [self.delegate player:self didChangeToNewState:state url:_url];
    }
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    self.state = AZPlayerStateFinish;
}

- (void)playerItemPlaybackStalled:(NSNotification *)notification
{
    self.state = AZPlayerStateBuffering;
}
@end