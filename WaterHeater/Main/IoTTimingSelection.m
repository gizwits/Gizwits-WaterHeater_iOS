/**
 * IoTTimingSelection.m
 *
 * Copyright (c) 2014~2015 Xtreme Programming Group, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "IoTTimingSelection.h"

@interface IoTTimingSelection () <UIPickerViewDataSource, UIPickerViewDelegate>
{
    __strong IoTTimingSelection *showingCtrl;
    BOOL isSpecial;
    NSInteger hourPicker;
    NSInteger minPiker;
}

@property (weak, nonatomic  ) IBOutlet UILabel      *textTitle;
@property (weak, nonatomic  ) IBOutlet UIPickerView *picker;

@property (strong, nonatomic) NSString     *title;
@property (assign, nonatomic) NSInteger    selectedIndex;

@property (assign, nonatomic) id <IoTTimingSelectionDelegate> delegate;

@end

@implementation IoTTimingSelection

- (id)initWithTitle:(NSString *)title delegate:(id <IoTTimingSelectionDelegate>)delegate  currentHour:(NSInteger)hourValue currentMin:(NSInteger)minHour
{
    self = [super init];
    if(self)
    {
        self.title    = title;
        self.delegate = delegate;
        hourPicker    = hourValue;
        minPiker      = minHour;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    isSpecial = NO;
    self.textTitle.text = self.title;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onConfirm:(id)sender {
    if([self.delegate respondsToSelector:
        @selector(IoTTimingSelectionDidConfirm:WithHour:WithMin:WithType:)])
    {
        [self.delegate IoTTimingSelectionDidConfirm:self
                                           WithHour:hourPicker
                                            WithMin:minPiker
                                           WithType:_selectType];
    }
    [self hide:YES];
}

- (IBAction)onCancel:(id)sender {
    [self hide:YES];
}

- (void)show:(BOOL)animated
{
    showingCtrl = self;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationsEnabled:animated];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [[UIApplication sharedApplication].keyWindow addSubview:self.view];
    [UIView commitAnimations];
    self.view.frame = [UIApplication sharedApplication].keyWindow.frame;
    [self.picker selectRow:hourPicker inComponent:0 animated:YES];
    [self.picker selectRow:minPiker inComponent:1 animated:YES];
}

- (void)hide:(BOOL)animated
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationsEnabled:animated];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [self.view removeFromSuperview];
    [UIView commitAnimations];
    
    showingCtrl = nil;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    int rows = 0;
    if (component == APPOINTMENT_HOUR) {
        if(_selectType == APPOINTMENT_COUNT_DOWN){
            rows = 25;
        }
        else if (_selectType == APPOINTMENT_TIMING){
            rows = 24;
        }
    }
    else if (component == APPOINTMENT_MIN){
        if(_selectType == APPOINTMENT_COUNT_DOWN){
            if(isSpecial){
                rows = 1;
            }else if(hourPicker == 24){
                rows = 1;
            }else{
                rows = 60;
            }
            
        }
        else if (_selectType == APPOINTMENT_TIMING){
            rows = 60;
        }
    }
    
    return rows;
}

//picker的标题设置
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *title = @"";
//    预约小时
    if (component == APPOINTMENT_HOUR) {
        //倒计时预约
        if(_selectType == APPOINTMENT_COUNT_DOWN){
            title = [NSString stringWithFormat:@"%i 小时", (int)(row)];
        }
        //定时预约
        else if (_selectType == APPOINTMENT_TIMING){
            title = [NSString stringWithFormat:@"%i 时", (int)(row)];
        }
    }
//    预约分钟
    else if (component == APPOINTMENT_MIN){
        //倒计时预约
        if(_selectType == APPOINTMENT_COUNT_DOWN){
            title = [NSString stringWithFormat:@"%i 分钟 后", (int)(row)];
        }
        //定时预约
        else if (_selectType == APPOINTMENT_TIMING){
            title = [NSString stringWithFormat:@"%i 分", (int)(row)];
        }
    }
    return title;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if(row == 24 && component == 0){
        isSpecial = YES;
        minPiker = 0;
    }
    else if(row == 0 && component ==1){
        isSpecial = YES;
    }
    else{
        if(isSpecial){
            isSpecial = NO;
        }
    }
    
    if(component == 0){
        hourPicker = row;
    }else if(component == 1){
        minPiker = row;
    }
    
    [self.picker reloadAllComponents];
}

#pragma mark - Utils
- (NSArray *)hourProdutor:(int)type WithMax:(int)max{
    NSMutableArray *hourList = [[NSMutableArray alloc] init];
    
    //倒计时
    if(type == ONE_TO_MAX){
        for (int hour =1;hour<= max;hour++){
            [hourList addObject:@(hour)];
        }
    }
    else if (type == ZERO_TO_MAX){
        for (int hour =0;hour<= max;hour++){
            [hourList addObject:@(hour)];
        }
    }
    return hourList;
}

- (NSArray *)minProductor:(int)type WithMax:(int)max{
    NSMutableArray *minList = [[NSMutableArray alloc] init];
    
    //倒计时
    if(type == ONE_TO_MAX){
        for (int min =1; min<= max;min++){
            [minList addObject:@(min)];
        }
    }
    else if (type == ZERO_TO_MAX){
        for (int min =0;min<= max;min++){
            [minList addObject:@(min)];
        }
    }
    return minList;
}

@end
