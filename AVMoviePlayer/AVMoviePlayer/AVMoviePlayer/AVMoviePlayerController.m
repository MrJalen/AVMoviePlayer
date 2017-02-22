//
//  AVMoviePlayerController.m
//  AVMoviePlayerDemo
//
//  Created by HuaTiKeJi on 2017/2/17.
//  Copyright © 2017年 HuaTiKeJi. All rights reserved.
//

#import "AVMoviePlayerController.h"

static const CGFloat kVideoPlayerControllerAnimationTimeinterval = 0.3f;

@interface AVMoviePlayerController () {
    
}

@property (nonatomic, strong) AVMoviePlayerView *videoControl;
@property (nonatomic, strong) UIView *movieBackgroundView;
@property (nonatomic, assign) BOOL isFullscreenMode;
@property (nonatomic, assign) CGRect originFrame;
@property (nonatomic, strong) NSTimer *durationTimer;
@property (nonatomic, copy) NSString *timeElapsedString;//当前时间
@property (nonatomic, copy) NSString *timeRmainingString;//视频总时长

@end

@implementation AVMoviePlayerController

- (void)dealloc {
    [self cancelObserver];
}

- (instancetype)initWithFrame:(CGRect)frame movieTitle:(NSString *)movieTitle {
    self = [super init];
    if (self) {
        self.view.frame = frame;
        self.view.backgroundColor = [UIColor blackColor];
        self.controlStyle = MPMovieControlStyleNone;
        [self.view addSubview:self.videoControl];
        self.videoControl.frame = self.view.bounds;
        self.videoControl.titleLabel.text = movieTitle;
        [self.videoControl.indicatorView startAnimating];
        
        [self configObserver];
        [self configControlAction];
        [self ListeningRotating];
        
        
        // 创建轻拍手势
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(singleTap:)];
        [singleTap setNumberOfTapsRequired:1];
        [self.videoControl.addGestureView addGestureRecognizer:singleTap];
        
        // 滑动手势
        [self.videoControl.addGestureView addGestureRecognizer:[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePan:)]];
    }
    return self;
}

- (void)singleTap:(UITapGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        if (self.videoControl.isBarShowing) {
            [self.videoControl animateHide];
        } else {
            [self.videoControl animateShow];
        }
    }
}

#pragma mark - Override Method
- (void)setContentURL:(NSURL *)contentURL {
    [self stop];
    [super setContentURL:contentURL];
    [self play];
}

#pragma mark - Publick Method
- (void)showInWindow {
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    if (!keyWindow) {
        keyWindow = [[[UIApplication sharedApplication] windows] firstObject];
    }
    [keyWindow addSubview:self.view];
    self.view.alpha = 0.0;
    [UIView animateWithDuration:kVideoPlayerControllerAnimationTimeinterval animations:^{
        self.view.alpha = 1.0;
    } completion:^(BOOL finished) {
        
    }];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}

- (void)dismiss {
    [self stopDurationTimer];
    [self stop];
    [UIView animateWithDuration:kVideoPlayerControllerAnimationTimeinterval animations:^{
        self.view.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
        if (self.dimissCompleteBlock) {
            self.dimissCompleteBlock();
        }
    }];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

#pragma mark - 注册通知：
- (void)configObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMPMoviePlayerPlaybackStateDidChangeNotification) name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMPMoviePlayerLoadStateDidChangeNotification) name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMPMoviePlayerReadyForDisplayDidChangeNotification) name:MPMoviePlayerReadyForDisplayDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMPMovieDurationAvailableNotification) name:MPMovieDurationAvailableNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMPMoviePlayerPlaybackDidFinishNotification) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
}

#pragma mark - 移除观察者
- (void)cancelObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 点击事件
- (void)configControlAction {
    [self.videoControl.playButton addTarget:self action:@selector(playButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.pauseButton addTarget:self action:@selector(pauseButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.backButton addTarget:self action:@selector(bcakButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.fullScreenButton addTarget:self action:@selector(fullScreenButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.shrinkScreenButton addTarget:self action:@selector(shrinkScreenButtonClick) forControlEvents:UIControlEventTouchUpInside];
    
    [self.videoControl.progressSlider addTarget:self action:@selector(progressSliderTouchBegan:) forControlEvents:UIControlEventTouchDown];
    [self.videoControl.progressSlider addTarget:self action:@selector(progressSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.videoControl.progressSlider addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside];
    [self.videoControl.progressSlider addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents:UIControlEventTouchUpOutside];
    [self.videoControl.progressSlider addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents:UIControlEventTouchCancel];
    [self setProgressSliderMaxMinValues];
    [self monitorVideoPlayback];
}

#pragma mark - 拖动进度条，播放完成
- (void)onMPMoviePlayerPlaybackStateDidChangeNotification {
    if (self.playbackState == MPMoviePlaybackStatePlaying) {
        self.videoControl.pauseButton.hidden = NO;
        self.videoControl.playButton.hidden = YES;
        [self startDurationTimer];
        [self.videoControl.indicatorView stopAnimating];
        [self.videoControl autoFadeOutControlBar];
    } else {
        self.videoControl.pauseButton.hidden = YES;
        self.videoControl.playButton.hidden = NO;
        [self stopDurationTimer];
    }
}

#pragma mark - 网络负载状态的变化(拖动进度条加载视频)
- (void)onMPMoviePlayerLoadStateDidChangeNotification {
    if (self.loadState & MPMovieLoadStateStalled) {
        [self.videoControl.indicatorView startAnimating];
    }else {
        [self.videoControl.indicatorView stopAnimating];
    }
}

- (void)onMPMoviePlayerReadyForDisplayDidChangeNotification {
    
}

- (void)onMPMovieDurationAvailableNotification {
    [self setProgressSliderMaxMinValues];
}

#pragma mark - 视频播放结束
- (void)onMPMoviePlayerPlaybackDidFinishNotification {
    [self.videoControl animateShow];
    [self shrinkScreenButtonClick];
}

#pragma mark - 播放
- (void)playButtonClick {
    [self play];
    self.videoControl.playButton.hidden = YES;
    self.videoControl.pauseButton.hidden = NO;
    self.videoControl.progressTimeView.alpha = 0.0;
}

#pragma mark - 暂停
- (void)pauseButtonClick {
    [self pause];
    self.videoControl.playButton.hidden = NO;
    self.videoControl.pauseButton.hidden = YES;
    self.videoControl.progressTimeView.alpha = 0.0;
}

#pragma mark - 关闭视频
- (void)bcakButtonClick {
//    [self dismiss];
    [self shrinkScreenButtonClick];
}

#pragma mark - 全屏播放
- (void)fullScreenButtonClick {
    if (self.isFullscreenMode) {
        return;
    }
    [self setDeviceOrientationLandscapeRight];
}

#pragma mark - 关闭全屏
- (void)shrinkScreenButtonClick {
    if (!self.isFullscreenMode) {
        return;
    }
    [self backOrientationPortrait];
}

#pragma mark -- 设备旋转监听 改变视频全屏状态显示方向 --
//监听设备旋转方向
- (void)ListeningRotating {
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil
     ];
}

- (void)onDeviceOrientationChange {
    
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    switch (interfaceOrientation) {
            
        case UIInterfaceOrientationPortrait:{
            [self backOrientationPortrait];
            NSLog(@"1.旋转方向：状态栏在上方");
        }
            break;
        case UIInterfaceOrientationLandscapeRight:{
            [self setDeviceOrientationLandscapeRight];
            NSLog(@"2.旋转方向：状态栏在右方");
        }
            break;
        case UIInterfaceOrientationLandscapeLeft:{
            [self setDeviceOrientationLandscapeLeft];
            NSLog(@"3.旋转方向：状态栏在左方");
        }
            break;
        case UIInterfaceOrientationPortraitUpsideDown:{
            [self backOrientationPortrait];
            NSLog(@"4.旋转方向：状态栏在下方");
        }
            break;
        
        default:
            break;
    }
}

#pragma mark - 返回小屏幕
- (void)backOrientationPortrait {
    if (!self.isFullscreenMode) {
        return;
    }
    [UIView animateWithDuration:0.3f animations:^{
        [self.view setTransform:CGAffineTransformIdentity];
        self.frame = self.originFrame;
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    } completion:^(BOOL finished) {
        self.isFullscreenMode = NO;
        self.videoControl.fullScreenButton.hidden = NO;
        self.videoControl.shrinkScreenButton.hidden = YES;
        if (self.willBackOrientationPortrait) {
            self.willBackOrientationPortrait();
        }
    }];
}

#pragma mark - 电池栏所在位置：右、左
- (void)setDeviceOrientationLandscapeRight {
    if (self.isFullscreenMode) {
        return;
    }
    
    self.originFrame = self.view.frame;
    CGFloat height = [[UIScreen mainScreen] bounds].size.width;
    CGFloat width = [[UIScreen mainScreen] bounds].size.height;
    CGRect frame = CGRectMake((height - width) / 2, (width - height) / 2, width, height);;
    [UIView animateWithDuration:0.3f animations:^{
        self.frame = frame;
        [self.view setTransform:CGAffineTransformMakeRotation(M_PI_2)];
    } completion:^(BOOL finished) {
        self.isFullscreenMode = YES;
        self.videoControl.fullScreenButton.hidden = YES;
        self.videoControl.shrinkScreenButton.hidden = NO;
        if (self.willChangeToFullscreenMode) {
            self.willChangeToFullscreenMode();
        }
    }];
}

- (void)setDeviceOrientationLandscapeLeft {
    if (self.isFullscreenMode) {
        return;
    }
    self.originFrame = self.view.frame;
    CGFloat height = [[UIScreen mainScreen] bounds].size.width;
    CGFloat width = [[UIScreen mainScreen] bounds].size.height;
    CGRect frame = CGRectMake((height - width) / 2, (width - height) / 2, width, height);
    self.frame = frame;

    [UIView animateWithDuration:0.3f animations:^{
        [self.view setTransform:CGAffineTransformMakeRotation(-M_PI_2)];
    } completion:^(BOOL finished) {
        self.isFullscreenMode = YES;
        self.videoControl.fullScreenButton.hidden = YES;
        self.videoControl.shrinkScreenButton.hidden = NO;
        if (self.willChangeToFullscreenMode) {
            self.willChangeToFullscreenMode();
        }
    }];
}

#pragma mark - 设置进度滑块最大最小值
- (void)setProgressSliderMaxMinValues {
    CGFloat duration = self.duration;
    self.videoControl.progressSlider.minimumValue = 0.f;
    self.videoControl.progressSlider.maximumValue = duration;
}

#pragma mark - 拖动进度条的状态：开始/结束、进度条值得改变
- (void)progressSliderTouchBegan:(UISlider *)slider {
    [self pause];
    [self.videoControl cancelAutoFadeOutControlBar];
    self.videoControl.progressTimeView.alpha = 1.0;
}

- (void)progressSliderTouchEnded:(UISlider *)slider {
    [self setCurrentPlaybackTime:floor(slider.value)];
    [self play];
    [self.videoControl autoFadeOutControlBar];
    self.videoControl.progressTimeView.alpha = 0.0;
}

- (void)progressSliderValueChanged:(UISlider *)slider {
    double currentTime = floor(slider.value);
    double totalTime = floor(self.duration);
    [self setTimeLabelValues:currentTime totalTime:totalTime];
    self.videoControl.progressTimeLable.text = _timeElapsedString;
}

#pragma mark - 监控视频播放：时间显示
- (void)monitorVideoPlayback {
    double currentTime = floor(self.currentPlaybackTime);
    double totalTime = floor(self.duration);
    [self setTimeLabelValues:currentTime totalTime:totalTime];
    self.videoControl.progressSlider.value = ceil(currentTime);
}

- (void)setTimeLabelValues:(double)currentTime totalTime:(double)totalTime {
    double minutesElapsed = floor(currentTime / 60.0);
    double secondsElapsed = fmod(currentTime, 60.0);
    _timeElapsedString = [NSString stringWithFormat:@"%02.0f:%02.0f", minutesElapsed, secondsElapsed];
    
    double minutesRemaining = floor(totalTime / 60.0);;
    double secondsRemaining = floor(fmod(totalTime, 60.0));;
    _timeRmainingString = [NSString stringWithFormat:@"%02.0f:%02.0f", minutesRemaining, secondsRemaining];
    
    self.videoControl.timeLabel.text = [NSString stringWithFormat:@"%@/%@",_timeElapsedString,_timeRmainingString];
}

#pragma mark - 开启视频时间定时器：定时器开始/结束
- (void)startDurationTimer {
    self.durationTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(monitorVideoPlayback) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.durationTimer forMode:NSDefaultRunLoopMode];
}

- (void)stopDurationTimer {
    [self.durationTimer invalidate];
}

- (void)fadeDismissControl {
    [self.videoControl animateHide];
}

#pragma mark - full screen controller
- (void)handlePan:(UIPanGestureRecognizer*)gesture {
    // 根据上次和本次移动的位置，算速率
    CGPoint veloctyPoint = [gesture velocityInView:self.videoControl];

    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:{
            //开始
            // 使用绝对值来判断移动的方向
            CGFloat x = fabs(veloctyPoint.x);
            CGFloat y = fabs(veloctyPoint.y);
            if (x > y) {
                [self progressSliderTouchBegan:self.videoControl.progressSlider];
            }
            break;
        }

        case UIGestureRecognizerStateChanged:{
            //改变
            [self horizontalMoved:veloctyPoint.x]; // 水平移动的方法只要x方向的值
            [self progressSliderValueChanged:self.videoControl.progressSlider];
            break;
        }

        case UIGestureRecognizerStateEnded:{
            //结束
            [self progressSliderTouchEnded:self.videoControl.progressSlider];
            break;
        }
            
        default:
            break;
    }
}

/**
 *  计算progressSlider的移动的值
 *
 *  @param value
 */
- (void)horizontalMoved:(CGFloat)value {
    NSLog(@"---滑动x--%f",value);
    CGFloat screenW = [[UIScreen mainScreen] bounds].size.width;
    CGFloat sliderMax = self.videoControl.progressSlider.maximumValue;
    
    CGFloat slider_x = fabs(value) / screenW * sliderMax / 100;
    
    if (value > 0) {
        //快进
        self.videoControl.progressSlider.value += slider_x;
    }else if(value < 0) {
        //快退
        self.videoControl.progressSlider.value -= slider_x;
    }
    NSLog(@"------%f",self.videoControl.progressSlider.value);
}

#pragma mark - Property setter
- (AVMoviePlayerView *)videoControl {
    if (!_videoControl) {
        _videoControl = [[AVMoviePlayerView alloc] init];
    }
    return _videoControl;
}

- (UIView *)movieBackgroundView {
    if (!_movieBackgroundView) {
        _movieBackgroundView = [UIView new];
        _movieBackgroundView.alpha = 0.0;
        _movieBackgroundView.backgroundColor = [UIColor blackColor];
    }
    return _movieBackgroundView;
}

- (void)setFrame:(CGRect)frame {
    [self.view setFrame:frame];
    [self.videoControl setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    [self.videoControl setNeedsLayout];
    [self.videoControl layoutIfNeeded];
}

/*
#pragma mark - 取出视频图片
+ (UIImage*) thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time {
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    NSParameterAssert(asset);
    AVAssetImageGenerator *assetImageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    
    CGImageRef thumbnailImageRef = NULL;
    CFTimeInterval thumbnailImageTime = time;
    NSError *thumbnailImageGenerationError = nil;
    thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:CMTimeMake(thumbnailImageTime, 60) actualTime:NULL error:&thumbnailImageGenerationError];
    
    if (!thumbnailImageRef)
        NSLog(@"thumbnailImageGenerationError %@", thumbnailImageGenerationError);
    
    UIImage *thumbnailImage = thumbnailImageRef ? [[UIImage alloc] initWithCGImage:thumbnailImageRef] : nil;
    
    return thumbnailImage;
}
 */

@end
