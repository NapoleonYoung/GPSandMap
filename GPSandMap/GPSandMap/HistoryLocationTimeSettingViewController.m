//
//  HistoryLocationTimeSettingViewController.m
//  GPS_MAP_3D
//
//  Created by NapoleonYoung on 16/2/29.
//  Copyright © 2016年 DoubleWood. All rights reserved.
//

#import "HistoryLocationTimeSettingViewController.h"
#import "Header.h"

@interface HistoryLocationTimeSettingViewController ()

@property (nonatomic, strong) UILabel *noticeLabel;
@property (nonatomic, strong) UILabel *startingTimeLabel;
@property (nonatomic, strong) UITextField *startingTimeTextField;

@property (nonatomic, strong) UILabel *endingTimeLabel;
@property (nonatomic, strong) UITextField *endingTimeTextField;

@property (nonatomic, strong) UIButton *finishedButton;

@end

@implementation HistoryLocationTimeSettingViewController

- (void)viewDidLoad
{
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.title = @"历史轨迹查询";

    [self createUI];
}

/**
 *  创建页面
 */
- (void)createUI
{
    //左上角返回按钮
    UIButton *leftTopButton = [UIButton buttonWithType:UIButtonTypeSystem];
    leftTopButton.frame = CGRectMake(0, 0, 60, 115/3);
    
    [leftTopButton setTitle:@"返回" forState:UIControlStateNormal];

    [leftTopButton addTarget:self action:@selector(leftButtonClick) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backNavigationItem = [[UIBarButtonItem alloc] initWithCustomView:leftTopButton];
    self.navigationItem.leftBarButtonItem = backNavigationItem;
    
    //第一行label
    CGRect noticeLabelRect = CGRectMake(15, navigationBarHeight * 1.5, screenWidth - 15, 30);
    self.noticeLabel = [self makeLabelWithRect:noticeLabelRect title:@"请输入历史轨迹查询起止时间"];
    
    //起始时间Label
    CGRect startingTimeRect = CGRectMake(15, self.noticeLabel.frame.origin.y + self.noticeLabel.frame.size.height + 10, 90, 30);
    self.startingTimeLabel = [self makeLabelWithRect:startingTimeRect title:@"起始时间："];
   
    //起始时间TextField
    CGRect startingTimeTextFieldRect = CGRectMake(self.startingTimeLabel.frame.origin.x + self.startingTimeLabel.frame.size.width, self.startingTimeLabel.frame.origin.y, screenWidth - 30 - self.startingTimeLabel.frame.size.width, 30);
    self.startingTimeTextField = [self makeTextFieldWithRect:startingTimeTextFieldRect placeholder:@"151208201112"];
    self.startingTimeTextField.text = @"160425201020";
    
    //终止时间Label
    CGRect endingTimeRect = CGRectMake(15, self.startingTimeLabel.frame.origin.y + self.startingTimeLabel.frame.size.height + 10, 90, 30);
    self.endingTimeLabel = [self makeLabelWithRect:endingTimeRect title:@"终止时间："];
    
    //终止时间TextField
    CGRect endingTimeTextFieldRect = CGRectMake(self.endingTimeLabel.frame.origin.x + self.endingTimeLabel.frame.size.width, self.endingTimeLabel.frame.origin.y, screenWidth - 30 - self.endingTimeLabel.frame.size.width, 30);
    self.endingTimeTextField = [self makeTextFieldWithRect:endingTimeTextFieldRect placeholder:@"160208201112"];
    self.endingTimeTextField.text = @"160425201205";
    
    //完成button
    UIButton *searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    searchButton.frame = CGRectMake(15, self.endingTimeLabel.frame.origin.y + self.endingTimeLabel.frame.size.height + 20, screenWidth - 30, screenHeight / 15);
    searchButton.backgroundColor = [UIColor blueColor];
    [searchButton setTitle:@"查询" forState:UIControlStateNormal];
    searchButton.layer.cornerRadius = 8;
    [searchButton addTarget:self action:@selector(searchButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:searchButton];
}

/**
 *  左上角返回按钮被按下
 */
- (void)leftButtonClick
{
    [self backToLastViewController];
}

/**
 *  查询button
 */
- (void)searchButtonClicked
{
    if (self.startingTimeTextField.text != nil && self.endingTimeTextField.text != nil ) {
        NSString *string = [self.startingTimeTextField.text stringByAppendingString:@","];
        NSString *historyTime = [string stringByAppendingString:self.endingTimeTextField.text];
        [self.delegate passValue:historyTime];
        [self backToLastViewController];
    } else {
        NSLog(@"历史轨迹查询时间不能为空");
    }
}

/**
 *  创建label
 *
 *  @param rect  label frame
 *  @param title label title
 */
- (UILabel *)makeLabelWithRect:(CGRect)rect title:(NSString *)title
{
    UILabel *label = [[UILabel alloc] initWithFrame:rect];
    //label.textColor = [UIColor grayColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = title;
    [self.view addSubview:label];
    return label;
}

/**
 *  创建TextField
 *
 *  @param rect        TextField rect
 *  @param placeholder TextField placeholder
 *
 *  @return TextField
 */
- (UITextField *)makeTextFieldWithRect:(CGRect)rect placeholder:(NSString *)placeholder
{
    UITextField *textField = [[UITextField alloc] initWithFrame:rect];
    
    textField.placeholder = placeholder;
    textField.layer.cornerRadius = 4;
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.font = [UIFont systemFontOfSize:13];
    
    [self.view addSubview:textField];
    
    return textField;
}

/**
 *  消掉历史轨迹查询界面，返回上一个界面
 */
- (void)backToLastViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
