/**
 * IoTTimingSelection.h
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

#import <UIKit/UIKit.h>

#define ONE_TO_MAX 0
#define ZERO_TO_MAX 1

//倒计时预约
#define APPOINTMENT_COUNT_DOWN 0
//定时预约
#define APPOINTMENT_TIMING 1
#define APPOINTMENT_HOUR 0
#define APPOINTMENT_MIN 1

@class IoTTimingSelection;

@protocol IoTTimingSelectionDelegate <NSObject>
@optional

/**
 * @brief 选中后的事件
 * @param value 0-34 分别对应 1-24，25 关闭
 */
- (void)IoTTimingSelectionDidConfirm:(IoTTimingSelection *)selection WithHour:(NSInteger)hourValue WithMin:(NSInteger)minValue WithType:(NSInteger)type;

@end

@interface IoTTimingSelection : UIViewController

- (id)initWithTitle:(NSString *)title delegate:(id <IoTTimingSelectionDelegate>)delegate  currentHour:(NSInteger)hourValue currentMin:(NSInteger)minHour;
- (void)show:(BOOL)animated;
- (void)hide:(BOOL)animated;

@property (nonatomic, assign) NSInteger selectType;

@end
