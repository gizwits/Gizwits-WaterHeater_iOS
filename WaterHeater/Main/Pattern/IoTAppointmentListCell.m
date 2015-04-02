/**
 * IoTAppointmentListCell.m
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

#import "IoTAppointmentListCell.h"
#import "IoTMainController.h"

@interface IoTAppointmentListCell(){
    BOOL open;
}

@property (nonatomic,strong) IoTTimingSelection *timingSelection;
@property (nonatomic,strong) NSString *timingTitle;
@property (nonatomic,assign) NSInteger row;
@property (nonatomic,strong) IoTMainController *mainCtrl;

@property (nonatomic,assign) NSInteger hourPicker;
@property (nonatomic,assign) NSInteger minPicker;

@end

@implementation IoTAppointmentListCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    if (selected){
        [self onShowTimeSelection];
    }
}

//更新功能模式
- (void)updateAppointmentCellWithIndex:(NSInteger)row isOpen:(BOOL)isOpen WithMin:(NSInteger)min
{
    //图片列表
    NSArray *imageList = @[@"pattern_alarm_icon@2x.png",
                           @"pattern_alarm_icon@2x.png"];
    //题目
    NSArray *titleList = @[@"倒计时预约",
                           @"定时预约"];
    
    //设置cell 图片
    self.imageAppointment.image = [UIImage imageNamed:[imageList objectAtIndex:row]];
    //设置cell 标题
    self.labelAppointmentTitle.text = [titleList objectAtIndex:row];
    //设置timing标题
    self.timingTitle = [titleList objectAtIndex:row];
    _row = row;
    self.mainCtrl = [IoTMainController currentController];
    
    [self.switchOpen setOn:isOpen];
    
    if(row == 0){
        self.labelTimeout.text = [NSString stringWithFormat:@"%@后",[self minToTime:min]];
    }else{
        self.labelTimeout.text = [self minToTime:min];
    }
    
    
    _hourPicker = min / 60;
    _minPicker = min % 60;
    open = isOpen;
}

#pragma mark - timingselection delegate
- (void)IoTTimingSelectionDidConfirm:(IoTTimingSelection *)selection WithHour:(NSInteger)hourValue WithMin:(NSInteger)minValue WithType:(NSInteger)type{
    
    _minPicker = minValue;
    _hourPicker = hourValue;
    
    NSInteger totalMin = [self timeToMinWithHour:hourValue WithMin:minValue];
    if (type == APPOINTMENT_COUNT_DOWN){
        [self.mainCtrl writeDataPoint:IoTDeviceWriteCountDown value:@(totalMin)];
        if(hourValue > 0 || minValue > 0){
            [_switchOpen setOn:YES animated:YES];
            [_switchOpen setHighlighted:YES];
        }else{
            [_switchOpen setOn:NO animated:NO];
        }
        _labelTimeout.text = [NSString stringWithFormat:@"%02ld : %02ld后",(long)hourValue,(long)minValue];
    }
    else if (type == APPOINTMENT_TIMING) {
        [self.mainCtrl writeDataPoint:IoTDeviceWriteTimeReserve value:@(totalMin)];
        [self.mainCtrl writeDataPoint:IoTDeviceWriteTimeOn value:@(1)];
        [_switchOpen setOn:YES animated:YES];
        [_switchOpen setHighlighted:YES];
        _labelTimeout.text = [NSString stringWithFormat:@"%02ld : %02ld ",(long)hourValue,(long)minValue];
    }
}

#pragma mark - switch listener
- (IBAction)switchValueChange:(id)sender {
    UISwitch *switchButton = (UISwitch*)sender;
    BOOL isButtonOn = [switchButton isOn];
    [self.mainCtrl writeDataPoint:IoTDeviceWriteTimeOn value:@(isButtonOn)];
    if(_row == 0){
        if(isButtonOn)
            [self onShowTimeSelection];
        else{
            _hourPicker = 0;
            _minPicker = 0;
            [self.mainCtrl writeDataPoint:IoTDeviceWriteCountDown value:@0];
            _labelTimeout.text = [NSString stringWithFormat:@"%02d : %02d后",0,0];
        }
    }
}

#pragma mark - Action
//显示时间选择器
- (void)onShowTimeSelection{
    _timingSelection = [[IoTTimingSelection alloc] initWithTitle:_timingTitle delegate:self currentHour:_hourPicker currentMin:_minPicker];
    _timingSelection.selectType = _row;
    [_timingSelection show:YES];
}

#pragma mark - Utils
- (NSString *)minToTime:(NSInteger)min{
    int mins = min % 60;
    int hours = (int)(min / 60);
    return [NSString stringWithFormat:@"%02d : %02d",hours,mins];
}

- (NSInteger)timeToMinWithHour:(NSInteger)hour WithMin:(NSInteger)min{
    NSInteger totalMin = hour * 60 + min;
    return totalMin;
}

@end
