//
//  ViewController.m
//  AVMoviePlayer
//
//  Created by HuaTiKeJi on 2017/2/22.
//  Copyright © 2017年 HuaTiKeJi. All rights reserved.
//

#import "ViewController.h"
#import "AVMoviePlayerController.h"

@interface ViewController ()

@property (nonatomic, strong) AVMoviePlayerController  *videoController;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //把使用视频播放View的控制器 设置背景色为黑色
    self.view.backgroundColor = [UIColor blackColor];
    self.navigationController.navigationBarHidden = YES;
    [self playVideo];
}


#pragma mark - 播放视频
- (void)playVideo{
    //http://krtv.qiniudn.com/150522nextapp
    //http://devimages.apple.com/iphone/samples/bipbop/gear1/prog_index.m3u8
    //http://61.140.13.170/vhot2.qqvideo.tc.qq.com/w0371wnzjsf.p712.1.mp4?sdtfrom=v1010&amp;guid=3f62c7dc22413c368afac887ce2f7ca6&amp;vkey=4303FD3F4FCC3935EDDF75E0DF775D25FCBBBFDC515C03218AE1C042B9F8995BBF26480865EC7D2E87689D949BECE29C1FBF24A213921E71824F3B2469EF77FBA9F922AB3A6D6806624FD20A0C2F7FE0C302623645D322A7DF58FBA4D3EA93568563A2E808F9634927409ED246CBDB17
    NSURL *url = [NSURL URLWithString:@"http://devimages.apple.com/iphone/samples/bipbop/gear1/prog_index.m3u8"];
    [self addVideoPlayerWithURL:url];
}

- (void)addVideoPlayerWithURL:(NSURL *)url{
    if (!self.videoController) {
        self.videoController = [[AVMoviePlayerController alloc] initWithFrame:CGRectMake(0, 0, KSCREEN_WIDTH, KSCREEN_HEIGHT) movieTitle:@"播放时间.M3U8格式"];
        
        __weak typeof(self)weakSelf = self;
        
        [self.videoController setWillBackOrientationPortrait:^{
            [weakSelf toolbarHidden:NO];
        }];
        [self.videoController setWillChangeToFullscreenMode:^{
            [weakSelf toolbarHidden:YES];
        }];
        [self.view addSubview:self.videoController.view];
    }
    self.videoController.contentURL = url;
    
}

/**
 *  隐藏navigation tabbar 电池栏
 *
 *  @param Bool YES/NO
 */
- (void)toolbarHidden:(BOOL)Bool {
    self.navigationController.navigationBar.hidden = Bool;
    self.tabBarController.tabBar.hidden = Bool;
    [[UIApplication sharedApplication] setStatusBarHidden:Bool withAnimation:UIStatusBarAnimationFade];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
