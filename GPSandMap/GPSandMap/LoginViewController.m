//
//  LoginViewController.m
//  GPS_MAP_3D
//
//  Created by NapoleonYoung on 16/2/26.
//  Copyright © 2016年 DoubleWood. All rights reserved.
//

#import "LoginViewController.h"
#import "NetWork.h"//网络连接

#import <MessageUI/MessageUI.h>//短信功能
#import "Header.h"
#import "NYKeychain.h"//keychain存储密码

@interface LoginViewController ()<MFMessageComposeViewControllerDelegate>//发送短信需要委托

@property (weak, nonatomic) IBOutlet UITextField *socketHostTextField;
@property (weak, nonatomic) IBOutlet UITextField *socketPortTextField;

@property (weak, nonatomic) IBOutlet UIButton *connectOrCutOffButton;

@property (weak, nonatomic) IBOutlet UITextField *userNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *userKeywordTextField;
@property (weak, nonatomic) IBOutlet UIButton *longinButton;

@property (strong, nonatomic) NSString *dataString;//用于存储接收到的位置数据信息

@property (weak, nonatomic) IBOutlet UITextField *phoneNumberTextField;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) NSTimer *timer;

@property (weak, nonatomic) IBOutlet UILabel *connectFlagLabel;

@property (nonatomic) NSTimeInterval timeInterval;//联网发送时间timeout

@end

@implementation LoginViewController

- (void)initSocket
{
    SOCKET.socketHost = self.socketHostTextField.text;
    SOCKET.socketPort = self.socketPortTextField.text;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //[self initSocket];
    
    self.socketHostTextField.delegate = self;
    self.socketPortTextField.delegate = self;
    self.userNameTextField.delegate = self;
    self.userKeywordTextField.delegate = self;
    self.phoneNumberTextField.delegate = self;
    
    //郭晓宇服务器IP，Port
    self.socketHostTextField.text = @"219.218.126.183";
    self.socketPortTextField.text = @"20002";
    
    //用户名，密码
    self.userNameTextField.text = @"gxy3k";
    //self.userKeywordTextField.text = @"gxy3k";
    self.phoneNumberTextField.text = @"18769781618";
    
    self.dataString = @"";
    
    //[self initSocket];//放在此处而不是放在前面的原因是：如果放在前面，socketHost以及socketPort还没有被初始化。

}


#pragma mark - NetWork


- (IBAction)connectOrCutOffNetwork:(UIButton *)sender
{
    [self.view endEditing:YES];//首先消掉键盘
    if (SOCKET.onLineFlag) {//网络连接状态
        [SOCKET cutOffSocket];
        
    } else {//网络断开状态
        
        if (![self.connectFlagLabel.text isEqualToString:@"连接中"]) {
            
            NSLog(@"LoginViewController:Host:%@,Port:%@", self.socketHostTextField.text, self.socketPortTextField.text);
            //[SOCKET connectToHost];
            
            self.timeInterval = 7;
            [SOCKET connectToHost:self.socketHostTextField.text Port:[self.socketPortTextField.text intValue] withTimeout:self.timeInterval];
            
            [self startTimer:self.timeInterval];//开启定时器，时间为timeout

        } else {
            NSLog(@"正在连接，请稍后");
        }
        
    }
}

//登录到服务器
- (IBAction)loginToServer:(id)sender
{
    [self.view endEditing:YES];//首先消掉键盘

    if (self.userKeywordTextField.text.length) {
        [NYKeychain setPassword:self.userKeywordTextField.text forService:ServiceName account:self.userNameTextField.text];
    }

    if (([self.userKeywordTextField.text length] > 0)&([self.userNameTextField.text length] > 0)) {
        NSString *string = [NSString stringWithFormat:@"310,%@,%@#",self.userNameTextField.text,self.userKeywordTextField.text];
        [SOCKET sendOutData:string withTag:0];
    } else {
        NSLog(@"用户名或密码不能为空");
    }
}
- (IBAction)sendingMessages:(UIButton *)sender
{
    [self.view endEditing:YES];//首先消掉键盘

    if ([MFMessageComposeViewController canSendText]) {
        NSLog(@"YES");
        MFMessageComposeViewController *mFMsgVC = [[MFMessageComposeViewController alloc] init];
        
        //mFMsgVC.navigationItem.title = @"GPS端激活短信发送";
        
        mFMsgVC.messageComposeDelegate = self;
        mFMsgVC.recipients = @[self.phoneNumberTextField.text];
        NSString *string;
        if (self.socketHostTextField.text.length && self.socketPortTextField.text.length) {
            string = [[[@"GPRS" stringByAppendingString:self.socketHostTextField.text] stringByAppendingString:@":"] stringByAppendingString:self.socketPortTextField.text];
        } else {
            string = @"格式为：GPRSHost:Port";
        }
        mFMsgVC.body = string;
        
        [self presentViewController:mFMsgVC animated:YES completion:nil];
        
    } else {
        
        NSLog(@"NO");
    }
}

//视图出现的时候监听通知
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setConnectOrCutoffButtonTitle];//当视图disAppear后，网络在线状态标志位onLineFlag改变了，然后视图appear，那么这个notification不会被监听到，因此需要在这里加上这行代码，视图出现，先检测onLineFlag，设置按钮标签
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLineFlagChanged:) name:OnLineFlagChangedNotification object:SOCKET];//网络状态标志位发生变化,添加通知和移除通知必须成对出现
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveData:) name:DidReceiveDataNotification object:SOCKET];//接收到来自服务器的数据,添加通知和移除通知必须成对出现
}

//监听到通知后执行的方法
- (void)onLineFlagChanged:(NSNotification *)notification
{
    if (SOCKET.onLineFlag) {
        //[self.activityIndicator stopAnimating];
        [self stopTimer];
    } else {
        [self cannotConnect];
    }
    [self setConnectOrCutoffButtonTitle];
    
}

//设置按钮标签
- (void)setConnectOrCutoffButtonTitle
{
    if (SOCKET.onLineFlag) {// 如果此时网络连接状态，将按钮标签设为“断开”
        [self.connectOrCutOffButton setTitle:@"断开" forState:UIControlStateNormal];
        //self.longinButton.titleLabel.text = @"请登录";
    } else {// 如果此时网络断开状态，将按钮标签设为“连接”
        [self.connectOrCutOffButton setTitle:@"连接" forState:UIControlStateNormal];
        self.longinButton.titleLabel.text = @"请登录";
    }
}

- (void)setLoginButtonTitle
{
    if (SOCKET.onLineFlag) {// 如果此时网络连接状态，将按钮标签设为“断开”
        [self.connectOrCutOffButton setTitle:@"断开" forState:UIControlStateNormal];
    } else {// 如果此时网络断开状态，将按钮标签设为“连接”
        [self.connectOrCutOffButton setTitle:@"连接" forState:UIControlStateNormal];
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
            
        }
        
        self.dataString = @"";
    }
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
            self.longinButton.titleLabel.text = @"登录成功";
            [self.longinButton setTitle:@"登录成功" forState:UIControlStateNormal];
            break;
        }
        case 150:
            NSLog(@"GPS连接断开");
            break;
            
        case 154:
            NSLog(@"GPS运行正常，未发数据");
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

#pragma mark - 定时器

- (void)startTimer:(NSTimeInterval)timeout
{
    //首先设置buttontitle
    self.connectFlagLabel.text = @"连接中";
    //设置连接状态
    [self.activityIndicator startAnimating];//开启转轮
    
    self.timer = [NSTimer timerWithTimeInterval:timeout
                                         target:self
                                       selector:@selector(timeFireMethod:)
                                       userInfo:nil
                                        repeats:NO];//NO, the timer will be invalidated after it fires.
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
}

- (void)stopTimer
{
    [self.timer invalidate];
    
    self.connectFlagLabel.text = @"连接成功";
    [self.activityIndicator stopAnimating];//转轮停止
}

- (void)timeFireMethod:(NSTimer *)timer
{
    [self cannotConnect];
}

/**
 *  未连接状态
 */
- (void)cannotConnect
{
    self.connectFlagLabel.text = @"未连接";
    [self.activityIndicator stopAnimating];
}

#pragma mark - 触摸背景关闭键盘
- (IBAction)backgroundTap:(UIControl *)sender
{/*
    [self.socketHostTextField resignFirstResponder];
    [self.socketPortTextField resignFirstResponder];
    [self.userNameTextField resignFirstResponder];
    [self.userKeywordTextField resignFirstResponder];
    [self.phoneNumberTextField resignFirstResponder];*/
    [self.view endEditing:YES];
}


#pragma mark -  MFMessageComposeViewControllerDelegate
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [controller dismissViewControllerAnimated:YES completion:nil];
    switch (result) {
        case MessageComposeResultCancelled:
            NSLog(@"取消发送短信");
            break;
            
        case MessageComposeResultSent:
            NSLog(@"成功发送短信");
            break;

        case MessageComposeResultFailed:
            NSLog(@"发送短信失败");
            break;

        default:
            break;
    }
}

#pragma mark - textfiled

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [super textFieldDidEndEditing:textField];
    
    if (textField == self.userNameTextField) {
        NSString *myPassword = [NYKeychain passwordForService:ServiceName account:self.userNameTextField.text];
        if (myPassword) {
            self.userKeywordTextField.text = myPassword;
        } else {
            NSLog(@"之前没有存储过该账户的密码");
        }
    }
}


@end
