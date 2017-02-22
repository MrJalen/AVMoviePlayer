//
//  AVMoviePlayerView.h
//  AVMoviePlayerDemo
//
//  Created by HuaTiKeJi on 2017/2/17.
//  Copyright © 2017年 HuaTiKeJi. All rights reserved.
//

#import <UIKit/UIKit.h>

#define KSCREEN_WIDTH   [UIScreen mainScreen].bounds.size.width
#define KSCREEN_HEIGHT  [UIScreen mainScreen].bounds.size.height

@interface AVMoviePlayerView : UIView

@property (nonatomic, strong, readonly) UIView *addGestureView;
@property (nonatomic, strong, readonly) UIView *topBar;
@property (nonatomic, strong, readonly) UIView *bottomBar;
@property (nonatomic, strong, readonly) UIView *progressTimeView;
@property (nonatomic, strong, readonly) UILabel *progressTimeLable;//时间显示

@property (nonatomic, strong, readonly) UIButton *backButton;
@property (nonatomic, strong, readonly) UILabel *titleLabel;

@property (nonatomic, strong, readonly) UIButton *playButton;
@property (nonatomic, strong, readonly) UIButton *pauseButton;
@property (nonatomic, strong, readonly) UIButton *fullScreenButton;
@property (nonatomic, strong, readonly) UIButton *shrinkScreenButton;
@property (nonatomic, strong, readonly) UISlider *progressSlider;
@property (nonatomic, strong, readonly) UILabel *timeLabel;
@property (nonatomic, assign, readonly) BOOL isBarShowing;
@property (nonatomic, strong, readonly) UIActivityIndicatorView *indicatorView;

@property (nonatomic, copy) void (^TouchesBeganBlock)(NSSet *touches, UIEvent *event);
@property (nonatomic, copy) void (^TouchesMovedBlock)(NSSet *touches, UIEvent *event);
@property (nonatomic, copy) void (^TouchesEndedBlock)(NSSet *touches, UIEvent *event);

- (void)animateHide;
- (void)animateShow;
- (void)autoFadeOutControlBar;
- (void)cancelAutoFadeOutControlBar;

@end
