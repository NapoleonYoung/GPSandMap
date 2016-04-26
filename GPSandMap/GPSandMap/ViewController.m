//
//  ViewController.m
//  GPSandMap
//
//  Created by NapoleonYoung on 16/3/14.
//  Copyright © 2016年 DoubleWood. All rights reserved.
//

#import "ViewController.h"
#import <MAMapKit/MAMapKit.h>//地图

#import "NetWork.h"//网络连接
#import "JZLocationConverter.h"//地理坐标系转换

#import "Header.h"

#import "HistoryLocationTimeSettingViewController.h"

#import "HistoryLocationTimeDelegate.h"//为了将HistoryLocationViewController中的时间数据传回


@interface ViewController ()<MAMapViewDelegate, HistoryLocationTimeDelegate>

@property (weak, nonatomic) IBOutlet MAMapView *mapView;//地图
@property (strong, nonatomic) NSMutableArray *locationAnnotationsNow;//当前定位端的位置坐标
@property (strong, nonatomic) MAPolyline *commonPolyline;
@property (nonatomic) CLLocationCoordinate2D startLocationOfHistory;//历史轨迹起始坐标
@property (strong, nonatomic) NSString *dataString;//用于存储接收到的位置数据信息

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@property (strong, nonatomic) NSString *historyLocationTime;//历史轨迹开始时间设置

@property (weak, nonatomic) IBOutlet UILabel *onlineFlagLabel;

@end

@implementation ViewController

- (void)setHistoryLocationTime:(NSString *)historyLocationTime {
    _historyLocationTime = historyLocationTime;
    NSLog(@"已设定历史轨迹查询时间");
    [self locationAtHistory];

}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self initMapView];
    
    self.segmentedControl.selectedSegmentIndex = -1;
    
    self.dataString = @"";

}



//视图出现的时候监听通知
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLineFlagChanged:) name:OnLineFlagChangedNotification object:SOCKET];//网络状态标志位发生变化,添加通知和移除通知必须成对出现
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveData:) name:DidReceiveDataNotification object:SOCKET];//接收到来自服务器的数据,添加通知和移除通知必须成对出现
    
    [self onlineFlagShow];

}

//监听到通知后执行的方法
- (void)onLineFlagChanged:(NSNotification *)notification
{
    //[self setConnectOrCutoffButtonTitle];
    [self onlineFlagShow];
}

- (void)onlineFlagShow
{
    if (SOCKET.onLineFlag) {
        self.onlineFlagLabel.hidden = YES;
        NSLog(@"onlineFlagLabel hidden YES");
    } else {
        self.onlineFlagLabel.hidden = NO;
        NSLog(@"onlineFlagLabel hidden NO");
    }
}

//监听到接收数据通知执行的方法
- (void)didReceiveData:(NSNotification *)notification
{
    [self handlingReceivedDataNew];//处理接收到的数据
}

- (void)handlingReceivedDataNew
{
    NSString *receivedString = [[NSString alloc] initWithData:SOCKET.receivedData encoding:NSUTF8StringEncoding];
    
    NSLog(@"本次接收到的数据是：%@", receivedString);
    
    self.dataString = [self.dataString stringByAppendingString:receivedString];
    
    if ([[self.dataString substringToIndex:7] isEqualToString:@"{\"data\""] && [[self.dataString substringFromIndex:(self.dataString.length - 2)] isEqualToString:@"]}"]) {//首先判断数据结构是否完整
        
        NSData *fullData = [self.dataString dataUsingEncoding:NSUTF8StringEncoding];//将数据转换成NSData
        NSDictionary *results = [NSJSONSerialization JSONObjectWithData:fullData options:NSJSONReadingMutableContainers error:NULL];//通过接收到的json数据获得NSDictionary
        
        NSArray *commandReceived = [results valueForKeyPath:@"data.response"];//状态信息
        
        if ([commandReceived count]) {//接收到命令
            NSString  *numofString = (NSString *)[commandReceived objectAtIndex:0];
            NSInteger num = [numofString integerValue];
            NSLog(@"接收的数据是：%ld",(long)num);
            
            [self resultOfLoginToServer:num];
            
            if ([numofString isEqualToString:@"160"]) {
                [self convertToGPSDataFromDictionary:results];
            }
        }
        
        self.dataString = @"";
    }
}

- (void)convertToGPSDataFromDictionary:(NSDictionary *)resultsDictionary
{
    NSArray *dataReceivedArray = [resultsDictionary valueForKeyPath:@"data"];//地理坐标数据，是个数组，每个数组是一个时间点的数据字典
    NSLog(@"%@", dataReceivedArray);
    NSLog(@"dataReceviedArray count is:%d", dataReceivedArray.count);
    if ([dataReceivedArray count]) {
        
        if ([dataReceivedArray count] == 1) {//单用户连续定位
            
            NSLog(@"经纬度数据：%@", dataReceivedArray);
            NSLog(@"经纬度数据数量：%lu", (unsigned long)[dataReceivedArray count]);
            
            NSDictionary *dataReceivedDictionary = [dataReceivedArray firstObject];
            NSString *GPSUserName = [dataReceivedDictionary valueForKeyPath:@"userName"];
            
            CLLocationCoordinate2D locationDataNow = [self dataDictionaryConvertedToCLLocationCoordinate2D:dataReceivedDictionary];
            
            if ((locationDataNow.latitude > 0) && (locationDataNow.longitude > 50)) {
                [self addAnnotationsToMapWithAnnotationCoordinate:locationDataNow andUserName:GPSUserName];//向地图上添加annotation
            }
            
        } else if ([dataReceivedArray count] == 2) {
            for (NSUInteger i = 0; i < 2; i ++) {
                NSDictionary *dataReceivedDictionary = [dataReceivedArray objectAtIndex:i];
                NSString *userName = [dataReceivedDictionary valueForKeyPath:@"userName"];
                
                CLLocationCoordinate2D GPRSLatitudeOfGCJ02 = [self dataDictionaryConvertedToCLLocationCoordinate2D:dataReceivedDictionary];//接收的经纬度数据字符串以度为单位表示
                if ((GPRSLatitudeOfGCJ02.latitude > 0) && (GPRSLatitudeOfGCJ02.longitude > 50)) {
                    [self initAnnotationWithCoordinate:GPRSLatitudeOfGCJ02 andUsername:userName];
                }
            }
            [self addAnnotationsToMapWithAnnotationCoordinate];
            
        } else if ([dataReceivedArray count] > 2) {//历史轨迹定位
            
            NSLog(@"经纬度数据：%@", dataReceivedArray);
            NSLog(@"经纬度数据数量：%lu", (unsigned long)[dataReceivedArray count]);
            
            NSUInteger countOfDataReceived = [dataReceivedArray count];
            
            CLLocationCoordinate2D *coordinates = (CLLocationCoordinate2D *)malloc(countOfDataReceived * sizeof(CLLocationCoordinate2D));
            NSString *userName;
            NSUInteger j = 0;
            for (NSUInteger i = 0; i < countOfDataReceived; i ++) {
                NSDictionary *dataReceivedDictionary = [dataReceivedArray objectAtIndex:i];
                
                userName = [dataReceivedDictionary valueForKeyPath:@"userName"];
                
                CLLocationCoordinate2D GPRSLatitudeOfGCJ02 = [self dataDictionaryConvertedToCLLocationCoordinate2D:dataReceivedDictionary];
                
                if ((GPRSLatitudeOfGCJ02.latitude > 0) && (GPRSLatitudeOfGCJ02.longitude > 50)) {
                    
                    coordinates[j] = GPRSLatitudeOfGCJ02;
                    j++;
                }
            }
            
            //[self addAnnotationsToMapWithAnnotationCoordinate:coordinates[0] andUserName:userName];
            [self addPolylinesToMapWithPolylinesCoordinates:coordinates coordinatesCount:countOfDataReceived];
        }
        
    }
}

/**
 *  将数据字典转换为地图可识别的GPS坐标
 *
 *  @param dataDictionary 数据字典
 *
 *  @return 地图可识别的GPS坐标
 */
- (CLLocationCoordinate2D)dataDictionaryConvertedToCLLocationCoordinate2D:(NSDictionary *)dataDictionary
{
    
    NSString *latitudeString = @"0";
    NSString *longitudeString = @"0";
    
    NSString *GPRSLatitudeString = [dataDictionary valueForKeyPath:@"GPRSLatitude"];//纬度字符
    NSString *GPRSLongitudeString = [dataDictionary valueForKeyPath:@"GPRSLongitude"];//经度字符
    
    NSString *GPSLatitudeString = [dataDictionary valueForKeyPath:@"GPSLatitude"];//纬度字符
    NSString *GPSLongitudeString = [dataDictionary valueForKeyPath:@"GPSLongitude"];//经度字符
    
    
    if ((![GPSLatitudeString isEqualToString:@"0"]) && (![GPSLongitudeString isEqualToString:@"0"])) {
        latitudeString = GPSLatitudeString;
        longitudeString = GPSLongitudeString;
    } else if ((![GPRSLatitudeString isEqualToString:@"0"]) && (![GPRSLongitudeString isEqualToString:@"0"])) {
        latitudeString = GPRSLatitudeString;
        longitudeString = GPRSLongitudeString;
    }
    
    //CLLocationCoordinate2D locationDataNow = [self wgs84ToGcj02WithLatitudeString:GPRSLatitudeString andLongitudeString:GPRSLongitudeString];//接收的经纬度数据字符串以度分为单位表示
    
    CLLocationCoordinate2D locationDataNow = [self wgs84DegreeToGCJ02WithLatitudeString:latitudeString andLongitudeString:longitudeString];
    
    return locationDataNow;
}

/**
 *  将WGS-84以度为单位表示的坐标字符串转换成GCJ－02坐标
 *
 *  @param latitudeString  WGS－84纬度字符串，单位是“度”
 *  @param longitudeString WGS－84经度字符串，单位是“度”
 *
 *  @return GCJ-02坐标
 */
- (CLLocationCoordinate2D)wgs84DegreeToGCJ02WithLatitudeString:(NSString *)latitudeString andLongitudeString:(NSString *)longitudeString
{
    CGFloat GPRSLatitudeOfDegree = [latitudeString floatValue];
    CGFloat GPRSLongitudeOfDegree = [longitudeString floatValue];
    
    CLLocationCoordinate2D GPRSCoordinate = CLLocationCoordinate2DMake(GPRSLatitudeOfDegree, GPRSLongitudeOfDegree);
    
    CLLocationCoordinate2D GPRSLatitudeOfGCJ02 = [JZLocationConverter wgs84ToGcj02:GPRSCoordinate];
    
    NSLog(@"坐标值测试：%f,%f",GPRSLatitudeOfGCJ02.latitude, GPRSLatitudeOfGCJ02.longitude);
    
    return GPRSLatitudeOfGCJ02;
}


/**
 *  将WGS-84以度分为单位表示的坐标字符串转换成GCJ－02坐标
 *
 *  @param latitudeString  WGS－84纬度字符串，单位是“度分”
 *  @param longitudeString WGS－84经度字符串，单位是“度分”
 *
 *  @return GCJ-02坐标
 */
- (CLLocationCoordinate2D)wgs84ToGcj02WithLatitudeString:(NSString *)latitudeString andLongitudeString:(NSString *)longitudeString
{
    CGFloat GPRSLatitudeOfDegree = [self gPSCoordinateInMinuteConvertToDegreeWithCoordinateString:latitudeString];//以度为单位表示的经度数
    
    //NSString *GPRSLongitudeString = [dataReceivedDictionary valueForKeyPath:@"GPRSLongitude"];//经度字符
    CGFloat GPRSLongitudeOfDegree = [self gPSCoordinateInMinuteConvertToDegreeWithCoordinateString:longitudeString];//以度为单位表示的纬度数
    NSLog(@"经纬度坐标：%f,%f",GPRSLatitudeOfDegree,GPRSLongitudeOfDegree);
    
    CLLocationCoordinate2D GPRSCoordinate = CLLocationCoordinate2DMake(GPRSLatitudeOfDegree, GPRSLongitudeOfDegree);
    
    CLLocationCoordinate2D GPRSLatitudeOfGCJ02 = [JZLocationConverter wgs84ToGcj02:GPRSCoordinate];
    
    return GPRSLatitudeOfGCJ02;
}

/**
 *  将以度分为单位表示的GPS坐标转换成以度为单位表示的GPS坐标
 *
 *  @param coordinateString 度分为单位表示的GPS坐标字符
 *
 *  @return 度为单位表示的GPS坐标
 */
- (CGFloat)gPSCoordinateInMinuteConvertToDegreeWithCoordinateString:(NSString *)coordinateString
{
    
    if (coordinateString.length >6) {
        // NSLog(@"度分坐标：%@",coordinateString);
        NSString *xiaoshuCoordinateString = [coordinateString substringFromIndex:(coordinateString.length - 6)];
        CGFloat xiaoshuCoordinate = [xiaoshuCoordinateString floatValue] /10000;//小数部分
        xiaoshuCoordinate /= 60;//分转换成度
        // NSLog(@"除法：%f",xiaoshuCoordinate);
        
        NSRange rangeOfZhengshu = [coordinateString rangeOfString:@"."];
        //  NSLog(@"小数点位置：%lu",(unsigned long)rangeOfZhengshu.location);
        NSString *zhengshuCoordinate = [coordinateString substringToIndex:rangeOfZhengshu.location];//整数部分
        // NSLog(@"整数部分%@", zhengshuCoordinate);
        
        CGFloat coordinateWithDegree = [zhengshuCoordinate floatValue] + xiaoshuCoordinate;//转换后坐标，以度为单位表示
        // NSLog(@"转换后坐标：%f", coordinateWithDegree);
        return coordinateWithDegree;
        
    } else {
        NSLog(@"坐标数据不合格");
    }
    return 0.0;
}


- (void)addPolylinesToMapWithPolylinesCoordinates:(CLLocationCoordinate2D *)coordinates coordinatesCount:(NSUInteger)count
{
    self.mapView.centerCoordinate = coordinates[0];
    self.commonPolyline = [MAPolyline polylineWithCoordinates:coordinates count:count];
    [self.mapView addOverlay:self.commonPolyline];
    free(coordinates), coordinates = NULL;
    
}

/**
 登录状态显示
 */
- (void)resultOfLoginToServer:(NSInteger)result
{
    switch (result) {
        case 106:
            NSLog(@"错误异常返回命令");
            break;
            
        case 107:
            NSLog(@"无查询数据返回");
            break;
            
        case 110:
            NSLog(@"输入错误");
            break;
            
        case 111:
            NSLog(@"用户不存在");
            break;
            
        case 112:
            NSLog(@"密码错误");
            break;
        case 113:
        {
            NSLog(@"登录成功");
            break;
        }
        case 150:
            NSLog(@"GPS连接断开");
            break;
            
        case 154:
            NSLog(@"GPS端未接收到命令");
            break;
            
        case 159:
            NSLog(@"GPS端连接网络（开机）");
            break;
            
        default:
            NSLog(@"未知的登陆状态:%ld", (long)result);
            break;
    }
}

//视图消失前移除监听
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OnLineFlagChangedNotification object:nil];//移除网络状态标志位监听者，移除通知和添加通知必须成对出现
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DidReceiveDataNotification object:nil];//移除接收数据监听者，移除通知和添加通知必须成对出现
}

#pragma mark - ButtonAction

- (IBAction)locateWayChanged:(UISegmentedControl *)sender
{
    switch (sender.selectedSegmentIndex) {
        case kAllTimesLocation://实时定位
        {
            [self locationAtNow];
            break;
        }
        case kHistoryLocation://历史定位
        {
            HistoryLocationTimeSettingViewController *hVC = [[HistoryLocationTimeSettingViewController alloc] init];
            
            hVC.delegate = self;//非常重要，两个页面的delegate变为同一个，从而将两个页面联系在一起
            
            UINavigationController *nVC = [[UINavigationController alloc] initWithRootViewController:hVC];
            [self presentViewController:nVC animated:YES completion:nil];
            break;
        }
            
        case kStopLocation://停止接收位置信息
        {
            [SOCKET sendOutData:@"322,330#" withTag:0];
            break;
        }
            
        case kWaitingLocation://使GPS端待机
        {
            [SOCKET sendOutData:@"350#" withTag:0];
            break;
        }
        default:
            NSLog(@"未按下任何按钮");
            break;
    }
}


#pragma mark - MAMapView

- (void)initMapView
{
    self.mapView.delegate = self;
    self.mapView.centerCoordinate = CLLocationCoordinate2DMake(36.7, 117.1);
    self.mapView.zoomLevel = 15.0;//设置缩放级别
}

#pragma mark - MAAnnotation


- (NSMutableArray *)locationAnnotationsNow
{
    if (!_locationAnnotationsNow) {
        _locationAnnotationsNow = [[NSMutableArray alloc] init];
    }
    return _locationAnnotationsNow;
}

/**
 初始化一个annotation,坐标是coordinate
 */
- (void)initAnnotationWithCoordinate:(CLLocationCoordinate2D)coordinate andUsername:(NSString *)name
{
    MAPointAnnotation *annotation = [[MAPointAnnotation alloc] init];
    annotation.coordinate = coordinate;
    annotation.title = name;
    [self.locationAnnotationsNow  addObject:annotation];
    
    self.mapView.centerCoordinate = coordinate;
    
}

/**
 *  向地图上添加一个Annotation
 *
 *  @param coordinate2D GPS坐标
 *  @param name         该坐标点的用户名
 */
- (void)addAnnotationsToMapWithAnnotationCoordinate:(CLLocationCoordinate2D)coordinate2D andUserName:(NSString *)name
{
    //添加地图前先移除地图上所有的annotation
    [self removeAllAnnotationsInMap];
    
    //在地图上添加annotation
    [self initAnnotationWithCoordinate:coordinate2D andUsername:name];
    [self.mapView addAnnotations:self.locationAnnotationsNow];
    [self.mapView setSelectedAnnotations:self.locationAnnotationsNow];//annotation初始为选中状态，气泡信息弹出
    
}

/**
 *  将所有的Annotation添加到地图上
 */
- (void)addAnnotationsToMapWithAnnotationCoordinate
{
    [self removeAllAnnotationsInMap];
    [self.mapView addAnnotations:self.locationAnnotationsNow];
    [self.mapView setSelectedAnnotations:self.locationAnnotationsNow];
}

- (void)removeAllAnnotationsInMap
{
    if ([self.locationAnnotationsNow count]) {
        [self.mapView removeAnnotations:self.locationAnnotationsNow];
        [self.locationAnnotationsNow removeAllObjects];
    }
}

#pragma mark - MAMapViewDelegate

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MAPointAnnotation class]]) {
        static NSString *reuseIndetifier = @"annotationReuseIndetifier";
        MAAnnotationView *annotationView = (MAPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseIndetifier];
        if (annotationView == nil) {
            annotationView = [[MAAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIndetifier];
        }
        
        UIImage *map_marker;
        //if (self.historyLocationTime.length) {
          //  map_marker = [UIImage imageNamed:@"start_marker"];
        //}   else {
        map_marker = [UIImage imageNamed:@"map_marker"];
        //}
        
        annotationView.image = map_marker;
        annotationView.centerOffset = CGPointMake(0, -1 * map_marker.size.height / 2);//图像偏移，使得图像下方正中为实际GPS坐标点
        //annotationView.selected = YES;
        
        annotationView.canShowCallout = YES;//设置气泡可以弹出
        //annotationView.animatesDrop = YES;//设置标注动画显示
        
        return annotationView;
    }
    return nil;
}

- (MAOverlayView *)mapView:(MAMapView *)mapView viewForOverlay:(id<MAOverlay>)overlay
{
    if ([overlay isKindOfClass: [MAPolyline class]]) {
        MAPolylineView *polylineView = [[MAPolylineView alloc] initWithPolyline:overlay];
        polylineView.lineWidth = 5.f;
        polylineView.strokeColor = [UIColor blueColor];
        polylineView.lineCapType = kMALineCapArrow;
        
        return polylineView;
    }
    return nil;
}

#pragma mark - NetWork

/**
 *  实时定位
 */
- (void)locationAtNow
{
    [self.mapView removeOverlay:self.commonPolyline];
    [self removeAllAnnotationsInMap];
    [SOCKET sendOutData:@"322,331#" withTag:0];//321:快速定位；322:精确定位
}

/**
 *  查询历史轨迹,查询前，首先清楚地图上的所有大头针和轨迹
 */
- (void)locationAtHistory
{
    [self.mapView removeOverlay:self.commonPolyline];
    [self removeAllAnnotationsInMap];//清除Annotation
    NSString *timeString = [@"320," stringByAppendingString:self.historyLocationTime];
    timeString = [timeString stringByAppendingString:@"#"];
    NSLog(@"历史轨迹查询时间设定：%@",timeString);
    [SOCKET sendOutData:timeString withTag:0];//发送历史轨迹查询命令
}

#pragma mark - HistoryLocationTimeDelegate

- (void)passValue:(NSString *)historyLocationTimeValue
{
    self.historyLocationTime = historyLocationTimeValue;
}

@end
