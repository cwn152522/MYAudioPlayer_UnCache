//
//  ViewController.m
//  MYMusicPlayer
//
//  Created by 伟南 陈 on 2017/7/11.
//  Copyright © 2017年 chenweinan. All rights reserved.
//

#import "ViewController.h"
#import "AVPlayer_Plus.h"

@interface ViewController ()<AVPlayer_PlusDelegate>

@property (strong, nonatomic) AVPlayer_Plus *player;//播放器
@property (weak, nonatomic) IBOutlet UIButton *playBtn;//播放按钮

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.player = [[AVPlayer_Plus alloc] init];
    self.player.currentMode = AVPlayerPlayModeSequenceList;//顺序播放
    self.player.delegate = self;
    self.player.playListArray = @[
                                  [NSURL URLWithString:@"http://audio.xmcdn.com/group29/M04/BE/DA/wKgJWVle4BjzvgpgAS4Y4A7PBjQ631.m4a"],
                                  [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"a" ofType:@"m4a"]]
                                  ];//设置播放列表
    
    
    //接收后台音频播放器的远程控制
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    //接收音频源改变监听事件，比如更换了输出源，由耳机播放拔掉耳机后，应该把音乐暂停(参照酷狗应用)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(routeChange:) name:AVAudioSessionRouteChangeNotification object:nil];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)routeChange:(NSNotification *)notification{
    //TODO: 接收音频源改变监听事件，比如更换了输出源，由耳机播放拔掉耳机后，应该把音乐暂停(参照酷狗应用)
    NSDictionary *dic=notification.userInfo;
    int changeReason= [dic[AVAudioSessionRouteChangeReasonKey] intValue];
    //等于AVAudioSessionRouteChangeReasonOldDeviceUnavailable表示旧输出不可用
    if (changeReason==AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
        AVAudioSessionRouteDescription *routeDescription=dic[AVAudioSessionRouteChangePreviousRouteKey];
        AVAudioSessionPortDescription *portDescription= [routeDescription.outputs firstObject];
        //原设备为耳机说明由耳机拔出来了，则暂停
        if ([portDescription.portType isEqualToString:@"Headphones"]) {
            [self.player pause];
        }
    }
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent {
    //TODO: 响应远程音乐播放控制消息
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        switch (receivedEvent.subtype) {
            case UIEventSubtypeRemoteControlTogglePlayPause:{
                [self.player pause];
            }
                break;
            case UIEventSubtypeRemoteControlNextTrack:
                [self.player turnNext];
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
                [self.player turnLast];
                break;
            case UIEventSubtypeRemoteControlPause:{
                [self.player pause];
            }
                break;
            case UIEventSubtypeRemoteControlPlay:{
                [self.player play];
            }
                break;
            default:
                break;
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - AVPlayer_PlusDelegate

- (void)player:(AVPlayer_Plus *)player playerSateDidChanged:(AVPlayerStatus)playerStatus{
    //TODO: 获取当前播放器状态
    if(playerStatus == AVPlayerStatusReadyToPlay){
        [self onClickButton:_playBtn];//开始播放
    }
}

- (void)player:(AVPlayer_Plus *)player playingSateDidChanged:(BOOL)isPlaying{
    //TODO: 监听当前播放状态改变
    [_playBtn setTitle:isPlaying == YES ? @"暂停": @"播放" forState:UIControlStateNormal];
}

- (void)player:(AVPlayer_Plus *)player playerIsPlaying:(NSTimeInterval)currentTime restTime:(NSTimeInterval)restTime progress:(CGFloat)progress{
    //TODO: 获取当前播放进度
    NSLog(@"当前播放时间:%.0f\n剩余播放时间:%.0f\n当前播放进度:%.2f\n总时长为:%.0f", currentTime, restTime, progress, player.duration);
}

#pragma mark - 事件处理
- (IBAction)onClickButton:(UIButton *)sender {
    switch (sender.tag) {
        case 0:
            [self.player turnLast];//播放上一首
            break;
        case 1:{
            if(self.player.isPlaying == YES){
                [self.player pause];
            }else{
                [self.player play];
            }
        }
            break;
        case 2:{
            if(self.player.currentMode == AVPlayerPlayModeSingleLoop){
                self.player.currentMode = AVPlayerPlayModeSequenceList;
            }else{
                self.player.currentMode ++;
            }
            
            switch (self.player.currentMode) {
                case AVPlayerPlayModeSingleLoop:
                    [sender setTitle:@"单曲循环" forState:UIControlStateNormal];
                    break;
                case AVPlayerPlayModeOnce:
                    [sender setTitle:@"单曲播放" forState:UIControlStateNormal];
                    break;
                case AVPlayerPlayModeRandomList:
                    [sender setTitle:@"随机播放" forState:UIControlStateNormal];
                    break;
                case AVPlayerPlayModeSequenceList:
                    [sender setTitle:@"顺序播放" forState:UIControlStateNormal];
                    break;
                default:
                    break;
            }
        }
            break;
        case 3:
            [self.player turnNext];//播放下一首
            break;
        default:
            break;
    }
}




@end
