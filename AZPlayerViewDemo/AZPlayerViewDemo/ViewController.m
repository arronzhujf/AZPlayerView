//
//  ViewController.m
//  LiveViewDemo
//
//  Created by arronzhu on 16/7/18.
//  Copyright © 2016年 arronzhu. All rights reserved.
//

#import "ViewController.h"
#import "AZPlayerView.h"

#define WeakSelf   __typeof(&*self) __weak   weakSelf   = self;
#define StrongSelf __typeof(&*self) __strong strongSelf = weakSelf;
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

@interface ViewController () <AZPlayerViewDelegate, UIScrollViewDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIButton *playButton;
@property (nonatomic, strong) AZPlayerView *playerView;
@property (nonatomic, strong) NSString *resource;
@property (nonatomic, strong) NSString *type;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initUI];
}

- (void)initUI {
    self.playButton.enabled = NO;
    self.resource = @"IMG_2262";
    self.type = @"MOV";
    NSString *sourceMoviePath1 = [[NSBundle mainBundle] pathForResource:self.resource ofType:self.type];
    NSURL *originalMovieURL1 = [NSURL fileURLWithPath:sourceMoviePath1];
    self.playerView = [[AZPlayerView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT/3.0) delegate:self];
    self.playerView.url = originalMovieURL1;
    
//        NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
//        self.playerView.cacheUrl = [NSURL URLWithString:document];
//        self.playerView.url = [NSURL URLWithString:@"http://baobab.wdjcdn.com/14564977406580.mp4"];
    
    [self.view addSubview:self.playerView];
    
}

- (IBAction)play:sender {
    [self.playerView play];
}

- (IBAction)pause:(id)sender {
    [self.playerView pause];
}

- (IBAction)changeUrl:(id)sender {
    if ([self.resource isEqualToString:@"Video_AudioDemo"]) {
        self.resource = @"IMG_2262";
        self.type = @"MOV";
    } else {
        self.resource = @"Video_AudioDemo";
        self.type = @"mp4";
    }
    NSString *sourceMoviePath = [[NSBundle mainBundle] pathForResource:self.resource ofType:self.type];
    NSURL *originalMovieURL = [NSURL fileURLWithPath:sourceMoviePath];
    self.playerView.url = originalMovieURL;
    
//    NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
//    self.playerView.cacheUrl = [NSURL URLWithString:document];
//    self.playerView.url = [NSURL URLWithString:@"http://baobab.wdjcdn.com/1457521866561_5888_854x480.mp4"];
}

- (IBAction)changeRate:(id)sender {
    UISlider * slider=(UISlider*)sender;
    self.playerView.rate = slider.value;
}

- (IBAction)changeVolume:(id)sender {
    UISlider * slider=(UISlider*)sender;
    self.playerView.volume = slider.value;
}

#pragma mark - PlayerViewDelegate
- (void)playerView:(AZPlayerView *)playerView didChangeToNewState:(AZPlayerState)state url:(NSURL *)url{
    NSString *result;
    switch (state) {
        case AZPlayerStateURLLoaded:
            result = @"PlayerStateURLLoaded";
            break;
        case AZPlayerStateReady:
            result = @"PlayerStateReady";
            self.playButton.enabled = YES;
            [self.playerView play];
            break;
        case AZPlayerStateStopped:
            result = @"PlayerStateStopped";
            break;
        case AZPlayerStatePlaying:
            result = @"PlayerStatePlaying";
            break;
        case AZPlayerStatePause:
            result = @"PlayerStatePause";
            break;
        case AZPlayerStateFinish:
            [playerView seekToTime:0];
            [playerView play];
            result = @"PlayerStateFinish";
            break;
        default:
            result = @"PlayerStateUnkonwn";
            break;
    }
    NSLog(@"changeToNewState --> %@", result);
}

- (void)playerView:(AZPlayerView *)playerView playBackProgressChange:(CGFloat)currentTime :(CGFloat)currentProgress url:(NSURL *)url{
    NSLog(@"currenttime %2f  progress %2f",currentTime,currentProgress);
}

- (void)playerView:(AZPlayerView *)playerView didFailWithError:(NSError *)error url:(NSURL *)url{
    NSLog(@"player did failed with error %@", [error description]);
}

@end
