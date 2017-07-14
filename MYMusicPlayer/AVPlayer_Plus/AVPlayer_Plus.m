//
//  AVPlayer_Plus.m
//  MYMusicPlayer
//
//  Created by 伟南 陈 on 2017/7/11.
//  Copyright © 2017年 chenweinan. All rights reserved.
//

#import "AVPlayer_Plus.h"

@interface AVPlayer_Plus ()

@end

@implementation AVPlayer_Plus

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeObserver:self forKeyPath:@"status"];
}


#pragma mark - 播放器初始化

- (instancetype)init{
    if(self = [super init]){
        
        //监听是否后台播放
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setCategory:AVAudioSessionCategoryPlayback error:nil];
        [session setActive:YES error:nil];//开始监听后台播放
        
        //监听音乐播放结束，播放下一首
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(musicPlayDidAutoFinished) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        
        //监听音乐被打断，继续播放
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionInterrupted:) name:AVAudioSessionInterruptionNotification object:nil];
        
        //增加观测者,播放状态切换时处理
        [self addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        
        //接收音频源改变监听事件，比如更换了输出源，由耳机播放拔掉耳机后，应该把音乐暂停(参照酷狗应用)
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(routeChange:) name:AVAudioSessionRouteChangeNotification object:nil];
        
        //监听app准备挂起，申请后台任务
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActiveNotification) name:UIApplicationWillResignActiveNotification object:nil];
        
        __weak typeof(self) weakSelf = self;
        //获取播放时间，通知外界
        [self addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) usingBlock:^(CMTime time) {
            NSTimeInterval current = CMTimeGetSeconds(time);
            _duration = CMTimeGetSeconds(weakSelf.currentItem.duration);
            float progress = current / _duration;
            if(progress >= 0){
                NSTimeInterval rest = _duration - current;
                if([weakSelf.delegate respondsToSelector:@selector(player:playerIsPlaying:restTime:progress:)]){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf.delegate player:weakSelf playerIsPlaying:current restTime:rest progress:progress];
                    });
                }
            }
        }];
    }
    return self;
}

- (void)setPlayListArray:(NSArray *)playListArray{
    _playListArray = playListArray;
    
    [self pause];
    
    _currentIndex = 0;
    
    __block AVPlayerItem *item = [self getCurrentPlayerItem];//获取当前播放音乐
    [self replaceCurrentItemWithPlayerItem:item];
}


#pragma mark - 播放控制

- (void)play{
    //TODO: 播放
    if(self.playListArray == 0)
        return;
    
    if(self.playing == NO){
        if(self.currentItem != nil){
            [super play];
            _playing = YES;
            if([_delegate respondsToSelector:@selector(player:playingSateDidChanged:)]){
                [_delegate player:self playingSateDidChanged:YES];
            }
        }
    }
}

- (void)playItem:(NSInteger)itemIndex{
    //TODO: 播放指定音乐
    if(self.playListArray == 0)
        return;
    
    if(itemIndex == self.currentIndex){
        [self play];
        return;
    }
    
    if(itemIndex < [self.playListArray count]){
        _currentIndex = itemIndex;
        [self play];
    }
}

- (void)pause{
    //TODO: 暂停
    if(self.playListArray == 0)
        return;
    
    if(self.playing == YES){
        [super pause];
        _playing = NO;
        if([_delegate respondsToSelector:@selector(player:playingSateDidChanged:)]){
            [_delegate player:self playingSateDidChanged:NO];
        }
    }
}

- (void)turnLast{
    //TODO: 上一首
    if(self.playListArray == 0)
        return;
    
    [self pause];
    
    NSInteger currentIndex = _currentIndex;
    switch (_currentMode) {
        case AVPlayerPlayModeOnce:
        case AVPlayerPlayModeSequenceList:{//仅播放一次或顺序播放
            currentIndex --;
            currentIndex = currentIndex == -1 ? ([_playListArray count] - 1) : currentIndex;
        }
            break;
        case AVPlayerPlayModeSingleLoop:{//单曲循环
        }
            break;
        case AVPlayerPlayModeRandomList:{//随机播放
            currentIndex = [self getRandomItem];
        }
            break;
        default:
            break;
    }
    
    if(_currentIndex != currentIndex){//下一首不是当前歌曲
        _currentIndex = currentIndex;
        NSURL *url = _playListArray[_currentIndex];
        if([self.delegate respondsToSelector:@selector(player:willPlayUrl:)]){
            NSURL *url1 = [self.delegate player:self willPlayUrl:url];
            url = url1 != nil ? url1 : url;
        }

        AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
        [self replaceCurrentItemWithPlayerItem:item];
    }else{//下一首还是当前首
        [self seekToProgress:0.0f];
    }
    
    [self play];
}

- (void)turnNext{
    //TODO: 下一首
    if(self.playListArray == 0)
        return;
    
    [self pause];
    
    NSInteger currentIndex = _currentIndex;
    switch (_currentMode) {
        case AVPlayerPlayModeOnce:
        case AVPlayerPlayModeSequenceList:{//仅播放一次或顺序播放
            currentIndex ++;
            currentIndex = currentIndex == [_playListArray count] ? 0 : currentIndex;
        }
            break;
        case AVPlayerPlayModeSingleLoop:{//单曲循环
        }
            break;
        case AVPlayerPlayModeRandomList:{//随机播放
            currentIndex = [self getRandomItem];
        }
            break;
        default:
            break;
    }
    
    if(_currentIndex != currentIndex){
        _currentIndex = currentIndex;
        NSURL *url = _playListArray[_currentIndex];
        if([self.delegate respondsToSelector:@selector(player:willPlayUrl:)]){
            NSURL *url1 = [self.delegate player:self willPlayUrl:url];
            url = url1 != nil ? url1 : url;
        }
        
        AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
        [self replaceCurrentItemWithPlayerItem:item];
    }else{
        [self seekToProgress:0.0f];
    }
    
    [self play];
}

- (void)musicPlayDidAutoFinished{
    //TODO: 音乐播放结束，下一首
    if(_currentMode == AVPlayerPlayModeOnce){//当前模式为只播一次，所以音乐停止播放
        [self seekToProgress:0.0f];//不写，再进行播放，又会走播放结束，未解～
        if([_delegate respondsToSelector:@selector(player:playingSateDidChanged:)]){
            _playing = NO;
            [_delegate player:self playingSateDidChanged:NO];
        }
        return;
    }
    
    [self turnNext];//当前模式为其他模式，播放下一首
}

- (void)seekToProgress:(CGFloat)progress{
    //TODO: 快进到某个进度
    if(self.currentItem == nil)
        return;
    
    [self seekToTime:CMTimeMake(CMTimeGetSeconds(self.currentItem.duration) * progress, 1)];//播放速率为1倍
}

#pragma mark - 其他事件处理

- (NSInteger)getRandomItem{
    //TODO: 从播放列表获取一个随机音乐下标
    NSInteger random = arc4random() % [_playListArray count];
    if(_currentIndex == random)
        if([_playListArray count] > 1){
            return [self getRandomItem];
        }
    
    return random;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    //TODO: 监听播放器状态监听，通知外界
    if([keyPath isEqualToString:@"status"]){
        if([self.delegate respondsToSelector:@selector(player:playerSateDidChanged:)]){
            [self.delegate player:self playerSateDidChanged:self.status];
        }
    }
}

- (void)applicationWillResignActiveNotification{
    //TODO: 监听应用准备挂起，申请后台播放任务
    __block NSString *key;
    [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"UIBackgroundModes"] enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isEqualToString:@"audio"]){
            key = obj;
            *stop = YES;
        }
    }];
    
    if([key length] == 0){
        NSAssert(1 < 0, @"warm：注意，后台任务没有开启！！！\n请在info.plist文件中添加Required background modes数组，新增一项App plays audio or streams audio/video using AirPlay字符串");
        return;
    }
}

- (void)audioSessionInterrupted:(NSNotification *)notification{
    //TODO: 监听音乐打断处理(如某个电话来了、电话结束了)
    NSDictionary * info = notification.userInfo;
    if ([[info objectForKey:AVAudioSessionInterruptionTypeKey] integerValue] == 1) {
        [self pause];
    }else{
        [self play];
    }
}

-(void)routeChange:(NSNotification *)notification{
    //TODO: 监听音频源改变监听事件，比如更换了输出源，由耳机播放拔掉耳机后，应该把音乐暂停(参照酷狗应用)
    NSDictionary *dic=notification.userInfo;
    int changeReason= [dic[AVAudioSessionRouteChangeReasonKey] intValue];
    //等于AVAudioSessionRouteChangeReasonOldDeviceUnavailable表示旧输出不可用
    if (changeReason==AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
        AVAudioSessionRouteDescription *routeDescription=dic[AVAudioSessionRouteChangePreviousRouteKey];
        AVAudioSessionPortDescription *portDescription= [routeDescription.outputs firstObject];
        //原设备为耳机说明由耳机拔出来了，则暂停
        if ([portDescription.portType isEqualToString:@"Headphones"]) {
            [self pause];
        }
    }
}

- (AVPlayerItem *)getCurrentPlayerItem{
    NSURL *url = _playListArray[_currentIndex];
    __block AVPlayerItem *item;
    if([self.delegate respondsToSelector:@selector(player:willPlayUrl:withResponse:)]){
        [self.delegate player:self willPlayUrl:url withResponse:^(AVURLAsset *asset, NSURL *fileUrl) {
            if(asset == nil && fileUrl == nil){
                item = [AVPlayerItem playerItemWithURL:url];
            }else if(asset != nil){
                item = [AVPlayerItem playerItemWithAsset:asset];
            }else{
                item = [AVPlayerItem playerItemWithURL:fileUrl];
            }
        }];
    }else{
        item = [AVPlayerItem playerItemWithURL:url];
    }
    
    return item;
}

@end
