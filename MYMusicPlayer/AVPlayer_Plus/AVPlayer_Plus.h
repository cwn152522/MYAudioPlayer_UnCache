//
//  AVPlayer_Plus.h
//  MYMusicPlayer
//
//  Created by 伟南 陈 on 2017/7/11.
//  Copyright © 2017年 chenweinan. All rights reserved.
//
/*
 说明：后台远程控制(如锁屏下的播放器的事件)由于要求接受事件的必需时controller或者appdelegate，故本封装内没法集成。
            后台远程控制步骤：
            (1)开始接收后台音频播放器远程控制
                 [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
            (2)接收音频源改变监听事件，比如更换了输出源，由耳机播放拔掉耳机后，应该把音乐暂停(参照酷狗应用)
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(routeChange:) name:AVAudioSessionRouteChangeNotification object:nil];
                 -(void)routeChange:(NSNotification *)notification{
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
             (3)响应远程音乐播放控制消息
                 - (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent {
                     if (receivedEvent.type == UIEventTypeRemoteControl) {
                         switch (receivedEvent.subtype) {
                         case UIEventSubtypeRemoteControlTogglePlayPause:
                         [self.player pause];
                         break;
                         case UIEventSubtypeRemoteControlNextTrack:
                         [self.player turnNext];
                         break;
                         case UIEventSubtypeRemoteControlPreviousTrack:
                         [self.player turnLast];
                         break;
                         case UIEventSubtypeRemoteControlPause:
                         [self.player pause];
                         break;
                         case UIEventSubtypeRemoteControlPlay:
                         [self.player play];
                         break;
                         default:
                         break;
                         }
                     }
                 }

 */


#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
@class AVPlayer_Plus;

typedef NS_ENUM(NSInteger, AVPlayerPlayMode) {
    AVPlayerPlayModeSequenceList,//顺序播放，列表循环
    AVPlayerPlayModeRandomList,//随机播放
    AVPlayerPlayModeOnce, //单曲播放，播完结束
    AVPlayerPlayModeSingleLoop//单曲循环
};


#pragma mark - AVPlayer_PlusDelegate

@protocol AVPlayer_PlusDelegate <NSObject>

@optional

/**
 监听播放器状态改变

 @param player 播放器
 @param playerStatus 播放器状态：播放器失败(不能播放了)、播放器正常(可以播放)、或出现未知异常(不能播放了)
 @note 应用场景：当播放器状态为正常时，才允许播放按钮响应事件
 */
- (void)player:(AVPlayer_Plus *)player playerSateDidChanged:(AVPlayerStatus)playerStatus;

/**
 监听播放器播放状态改变

 @param isPlaying 是否正在播放
 */
- (void)player:(AVPlayer_Plus *)player playingSateDidChanged:(BOOL)isPlaying;

/**
 监听播放器音乐播放时间

 @param player 播放器
 @param currentTime 当前播放时间，单位为秒
 @param restTime 剩余播放时间，单位为秒
 @param progress 当前播放进度，范围0~1
 @note 应用场景：显示实时播放进度
 */
- (void)player:(AVPlayer_Plus *)player playerIsPlaying:(NSTimeInterval)currentTime restTime:(NSTimeInterval)restTime progress:(CGFloat)progress;

/**
 播放器即将播放

 @param player 播放器
 @param music_url 待播放url
 @return 处理过的待播放url，返回不为空，则加载，否则仍加载music_url
 @note 应用场景：提供外界进行本地缓存逻辑处理的时机，若存在本地缓存，则可返回本地文件对应的fileUrl地址进行播放
 */
- (NSURL *)player:(AVPlayer_Plus *)player willPlayUrl:(NSURL *)music_url;

@end


#pragma mark - AVPlayer_Plus

@interface AVPlayer_Plus : AVPlayer

- (instancetype)init;

@property (assign, nonatomic) id <AVPlayer_PlusDelegate> delegate;

/**
 播放音乐的地址列表
 */
@property (strong, nonatomic) NSArray <NSURL *> *playListArray;

/**
 当前播放模式
 */
@property (assign, nonatomic) AVPlayerPlayMode currentMode;

/**
 当前播放音乐的下标
 */
@property (assign, nonatomic, readonly) NSInteger currentIndex;

/**
 播放状态，是否正在播放
 */
@property (assign, nonatomic, getter=isPlaying, readonly) BOOL playing;

/**
 当前音乐总时长，单位为秒
 */
@property (assign, nonatomic, readonly) NSTimeInterval duration;


#pragma mark - 播放控制

/**
 开始播放
 
 @note 默认播放从第一首开始播放
 */
- (void)play;

/**
 播放指定音乐

 @param itemIndex 指定待播放音乐的下标
 */
- (void)playItem:(NSInteger)itemIndex;

/**
 暂停播放
 */
- (void)pause;

/**
 下一首
 */
- (void)turnNext;

/**
 上一首
 */
- (void)turnLast;

/**
 快进到某个进度

 @param progress 进度，范围为0～1
 */
- (void)seekToProgress:(CGFloat)progress;


@end
