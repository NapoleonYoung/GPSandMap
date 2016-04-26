//
//  ShowTextFieldViewController.m
//  TCPAssistant
//
//  Created by NapoleonYoung on 16/3/25.
//  Copyright © 2016年 DoubleWood. All rights reserved.
//

#import "ShowTextFieldViewController.h"

@interface ShowTextFieldViewController ()


@property (nonatomic) int previewTag;//上次编辑的TextField Tag
@property (nonatomic) float previewMoveY;//上次移动的TextField Y坐标距离


@end

@implementation ShowTextFieldViewController


#pragma mark - TextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}


- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    float textFieldY = textField.frame.origin.y + textField.frame.size.height;//textField最下端Y坐标
    float bottomY = self.view.frame.size.height - textFieldY;//textField最下端距离屏幕底部坐标
    if (bottomY >= 264) {//tabbar.height:48;keyboard.height:216;20为余量，可为零，因为此视图中第二行textField位置在第一行textfield的keyboard出现时可能被挡住
        self.previewTag = -1;
        return;
    }
    
    //float moveY = self.keyboardHeight - bottomY;//view要往上移动的距离
    float moveY = 48 + 216 - bottomY - 5;//view要往上移动的距离;tabbar.height:48;keyboard.height:216;-5为余量，可为零，也可为正因为此视图中第二行textField位置在第一行textfield的keyboard出现时可能被挡住
    
    self.previewMoveY = moveY;
    self.previewTag = textField.tag;
    
    CGRect newViewFrame = self.view.frame;
    newViewFrame.origin.y -= moveY;
    
    NSTimeInterval animationDuration = 0.80f;
    [UIView beginAnimations:@"ResizeView" context:nil];
    [UIView setAnimationDuration:animationDuration];
    
    self.view.frame = newViewFrame;
    [UIView commitAnimations];
    
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (self.previewTag == -1) {
        return;
    } else if (self.previewTag == textField.tag) {
        float moveY = self.previewMoveY;//要还原的距离
        CGRect newViewFrame = self.view.frame;
        newViewFrame.origin.y += moveY;
        
        NSTimeInterval animationDuration = 0.80f;
        [UIView setAnimationDuration:animationDuration];
        [UIView beginAnimations:@"ResizeviewContext" context:nil];
        
        self.view.frame = newViewFrame;
        [UIView commitAnimations];
    }
    
    
}


@end
