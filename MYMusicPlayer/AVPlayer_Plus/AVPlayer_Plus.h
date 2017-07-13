//
//  AVPlayer_Plus.h
//  MYMusicPlayer
//
//  Created by 伟南 陈 on 2017/7/11.
//  Copyright © 2017年 chenweinan. All rights reserved.
//
/*
 说明：后台远程控制(如锁屏下的播放器的事件)由于要求接受事件的必需时controller或者appdelegate，故本封装内没法集成。
 后台远程控制步骤(使用avplayer的视图或视图控制器中，完成以下步骤即可)：
 (1)开始接收后台音频播放器远程控制
 [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
 (2)响应远程音乐播放控制消息
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
 (3)更新锁屏播放器播放信息(含歌曲名、专辑名、歌曲图片、进度条、时间信息等)
 只需在代理方法-player:playerIsPlaying:restTime:progress:中调用如下方法即可
 - (void)updateLockedScreenMusic{
 //TODO: 锁屏时候的音乐信息更新，建议1秒更新一次
 NSLog(@"当前播放的是第%ld首歌", self.player.currentIndex);//获取当前播放的歌曲，然后，取model数据，填充播放信息中心内容
 // 播放信息中心
 MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
 
 // 初始化播放信息
 NSMutableDictionary *info = [NSMutableDictionary dictionary];
 // 专辑名称
 info[MPMediaItemPropertyAlbumTitle] = @"啊啊啊";
 // 歌手
 info[MPMediaItemPropertyArtist] = @"哈哈哈";
 // 歌曲名称
 info[MPMediaItemPropertyTitle] = @"呵呵呵";
 // 设置图片
 info[MPMediaItemPropertyArtwork] = [[MPMediaItemArtwork alloc] initWithImage:[UIImage imageNamed:@"Icon-58"]];
 // 设置持续时间（歌曲的总时间）
 [info setObject:[NSNumber numberWithFloat:CMTimeGetSeconds([self.player.currentItem duration])] forKey:MPMediaItemPropertyPlaybackDuration];
 // 设置当前播放进度
 [info setObject:[NSNumber numberWithFloat:CMTimeGetSeconds([self.player.currentItem currentTime])] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
 
 // 切换播放信息
 center.nowPlayingInfo = info;
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
 @note 应用场景：改变播放按钮的状态
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
 播放器即将播放，仅在需要本地缓存时才实现，缓存逻辑需要外界来实现
 
 @param player 播放器
 @param music_url 待播放url
 @param response 回调回来的asset不为空则以asset方式进行加载网络音乐；如果返回的是fileUrl则以url方式进行加载本地音乐(bundle或缓存文件)
 @note 应用场景：提供外界进行本地缓存逻辑处理的时机
 */
- (void)player:(AVPlayer_Plus *)player willPlayUrl:(NSURL *)music_url withResponse:(void(^)(AVURLAsset *asset, NSURL *fileUrl))response;

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
