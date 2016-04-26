//
//  NetWork.h
//  GPS_Map
//
//  Created by NapoleonYoung on 15/10/28.
//  Copyright (c) 2015年 DoubleWood. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetWork : NSObject

@property (strong, nonatomic) NSString *socketHost;
@property (strong, nonatomic) NSString *socketPort;
@property (strong, nonatomic) NSString *sendingData;
@property (strong, nonatomic) NSData *receivedData;
@property (nonatomic) BOOL onLineFlag;//网络是否在线标志位，1在线；0断开


/*
    当网络状态标志位onLineFlag值改变时发送通知即onLineFlagChanged
    当收到数据后发送通知，即didReceiveData
 */
#define OnLineFlagChangedNotification @"onLineFlagChanged"
#define DidReceiveDataNotification @"didReceiveData"

/**
 单例
 */
+ (instancetype)sharedInstance;

/**
 连接网络
 */
- (void)connectToHost;

/**
 *  连接网络
 *
 *  @param host     host
 *  @param port     port
 *  @param interval timeInterval
 */
- (void)connectToHost:(NSString *)host Port:(uint16_t)port withTimeout:(NSTimeInterval)interval;

/**
 发送数据
 */
- (void)sendOutData:(NSString *)willBeSendedData withTag:(long)tag;

/**
 断开连接
 */
- (void)cutOffSocket;



@end
