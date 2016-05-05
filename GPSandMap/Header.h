//
//  Header.h
//  GPSandMap
//
//  Created by NapoleonYoung on 16/3/14.
//  Copyright © 2016年 DoubleWood. All rights reserved.
//

#ifndef Header_h
#define Header_h

#define Map_Key @"9f734bb4d794208f43cd4b649c6b96fa"

#define SOCKET [NetWork sharedInstance]//网络单例

//Segmented Control按钮index
#define  kAllTimesLocation 0    //实时定位按钮
#define  kHistoryLocation 1     //历史轨迹定位按钮
#define  kStopLocation 2        //停止定位按钮
#define  kWaitingLocation 3     //待机

//适配屏幕的宏
#define screenHeight [UIScreen mainScreen].bounds.size.height
#define screenWidth  [UIScreen mainScreen].bounds.size.width

#define navigationBarHeight 64

//NSUserDefaults
#define UserDefaults [NSUserDefaults standardUserDefaults]

#endif /* Header_h */
