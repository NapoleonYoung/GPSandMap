//
//  HistoryLocationTimeSettingViewController.h
//  GPS_MAP_3D
//
//  Created by NapoleonYoung on 16/2/29.
//  Copyright © 2016年 DoubleWood. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HistoryLocationTimeDelegate.h"


@interface HistoryLocationTimeSettingViewController : UIViewController

@property (nonatomic, assign) NSObject<HistoryLocationTimeDelegate> *delegate;

@end
