# AVMoviePlayer

AVMoviePlayer 是使用系统框架 MPMoviePlayerController 封装的视频播放器</br>
功能：1.根据手机旋转自由切换横竖屏；</br>
     2.手势轻点显示/隐藏topView/bottomView；</br>
     3.视频开始播放几秒后topView/bottomView自动隐藏；</br>
     4.手势左右滑动加载视频快进/快退；</br>
     5.格式支持：MOV、MP4、M4V、3GP、M3U8等。</br>


# 使用：
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //把使用视频播放View的控制器 设置背景色为黑色
    self.view.backgroundColor = [UIColor blackColor];
    self.navigationController.navigationBarHidden = YES;
    [self playVideo];
}


pragma mark - 播放视频
- (void)playVideo{
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


# plist文件添加相关key
<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsArbitraryLoads</key>
		<true/>
	</dict>
  
  
# 添加系统依赖框架： AVFoundation.framework MediaPlayer.framework
