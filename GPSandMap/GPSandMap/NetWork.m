//
//  NetWork.m
//  GPS_Map
//
//  Created by NapoleonYoung on 15/10/28.
//  Copyright (c) 2015年 DoubleWood. All rights reserved.
//

#import "NetWork.h"
#import "GCDAsyncSocket.h"

@interface NetWork()<GCDAsyncSocketDelegate>

@property (strong, nonatomic) GCDAsyncSocket *gcdAnsynSocket;

@end

@implementation NetWork

//单例
+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    static NetWork *sharedInstance;
    
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
    
}

- (GCDAsyncSocket *)gcdAnsynSocket
{
    if (!_gcdAnsynSocket) {
        _gcdAnsynSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return _gcdAnsynSocket;
}

//当onLineFlag值改变时，发送通知
- (void)setOnLineFlag:(BOOL)onLineFlag
{
    _onLineFlag = onLineFlag;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:OnLineFlagChangedNotification object:self];
}

//当接收到数据后，发送通知
- (void)setReceivedData:(NSData *)receivedData
{
    _receivedData = receivedData;
    [[NSNotificationCenter defaultCenter] postNotificationName:DidReceiveDataNotification object:self];
    NSLog(@"接收到新数据");
}

//连接网络
- (void)connectToHost
{
    NSError *error;
    [self.gcdAnsynSocket connectToHost:self.socketHost onPort:[self.socketPort intValue] withTimeout:-1 error:&error];
    
    NSLog(@"Host:%@, Port:%@", self.socketHost, self.socketPort);
    
    if (error.code == 1) {
        NSLog(@"socket已经连接，请勿重复连接");
    } else {
        NSLog(@"正在连接");
    }
}


//连接网络
- (void)connectToHost:(NSString *)host Port:(uint16_t)port withTimeout:(NSTimeInterval)interval
{
    NSError *error;
    BOOL result = [self.gcdAnsynSocket connectToHost:host onPort:port withTimeout:interval error:&error];
    
    NSLog(@"Host:%@, Port:%hu", host, port);
    NSLog(@"连接结果：%hhd", result);
    
    if (error.code == 1) {
        NSLog(@"socket已经连接，请勿重复连接");
    } else {
        NSLog(@"正在连接");
    }

}

//发送数据
- (void)sendOutData:(NSString *)willBeSendedData withTag:(long)tag
{
    NSData *data = [willBeSendedData dataUsingEncoding:NSUTF8StringEncoding];
    [self.gcdAnsynSocket writeData:data withTimeout:-1 tag:tag];
}

//断开连接
- (void)cutOffSocket
{
    [self.gcdAnsynSocket disconnect];
}

#pragma mark - GCDAsyncSocketDelegate

//连接上指定的Host和Port
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    NSLog(@"连接成功");
    
    self.onLineFlag = YES;
    [sock readDataWithTimeout:-1 tag:0];//首先读取数据，－1永不超时
}

//接收到数据
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    self.receivedData = data;
    //self.receiveData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    //随时准备读数据，－1永不超时
    [sock readDataWithTimeout:-1 tag:0];
}

//发送数据成功
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"发送成功");
    
    //随时准备读数据，－1永不超时
    [sock readDataWithTimeout:-1 tag:0];
}

//断开连接
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSLog(@"已断开连接");
    self.onLineFlag = NO;
    NSLog(@"Error:%@",err);
}

@end
