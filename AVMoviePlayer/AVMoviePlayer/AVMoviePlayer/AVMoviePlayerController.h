//
//  AVMoviePlayerController.h
//  AVMoviePlayerDemo
//
//  Created by HuaTiKeJi on 2017/2/17.
//  Copyright © 2017年 HuaTiKeJi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AVMoviePlayerView.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface AVMoviePlayerController : MPMoviePlayerController <UIGestureRecognizerDelegate>

//消失
@property (nonatomic, copy)void(^dimissCompleteBlock)(void);

//进入最小化状态
@property (nonatomic, copy)void(^willBackOrientationPortrait)(void);

//进入全屏状态
@property (nonatomic, copy)void(^willChangeToFullscreenMode)(void);
@property (nonatomic, assign) CGRect frame;

- (instancetype)initWithFrame:(CGRect)frame movieTitle:(NSString *)movieTitle;
- (void)showInWindow;
- (void)dismiss;

//获取视频截图
//+ (UIImage*) thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time;

@end
