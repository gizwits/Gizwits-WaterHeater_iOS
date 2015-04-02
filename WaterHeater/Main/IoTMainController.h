/**
 * IoTMainController.h
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

typedef enum
{
    // writable
    IoTDeviceWriteUpdateData = 0,           //更新数据
    IoTDeviceWriteOnOff,                    //开关
    IoTDeviceWriteTimeOn,                   //定时预约
    IoTDeviceWriteTimeReserve,              //定时预约开关
    IoTDeviceWriteCountDown,                //倒计时预约
    IoTDeviceWriteSetTemp,                  //设定温度
    IoTDeviceWriteRoomTemp,                 //目标温度
    IoTDeviceWriteMode,                     //模式
    
    // fault
    IoTDeviceFaultBurning,                  //干烧故障
    IoTDeviceFaultSensorOpen,               //传感器开路故障
    IoTDeviceFaultSensorShort,              //传感器短路故障
    IoTDeviceFaultOverTemp,                 //超温故障
    
}IoTDeviceDataPoint;

typedef enum
{
    IoTDeviceCommandWrite    = 1,//写
    IoTDeviceCommandRead     = 2,//读
    IoTDeviceCommandResponse = 3,//读响应
    IoTDeviceCommandNotify   = 4,//通知
}IoTDeviceCommand;

#define DATA_CMD                        @"cmd"                  //命令
#define DATA_ENTITY                     @"entity0"              //实体
#define DATA_ATTR_SWITCH                @"Switch"               //属性：开关
#define DATA_ATTR_TIME_ON               @"Reserve_OnOff"        //属性：定时预约
#define DATA_ATTR_TIME_RESERVE          @"Time_Reserve"         //属性：定时预约开关
#define DATA_ATTR_COUNT_DOWN            @"CountDown_Reserve"    //属性：倒计时预约
#define DATA_ATTR_SET_TEMP              @"Set_Temp"             //属性：目标温度
#define DATA_ATTR_ROOM_TEMP             @"Room_Temp"            //属性：室内温度
#define DATA_ATTR_MODE                  @"Mode"                 //属性：模式设置
#define DATA_ATTR_FAULT_BURNING         @"Fault_burning"        //属性：干烧故障
#define DATA_ATTR_FAULT_SENSOROPEN      @"Fault_SensorOpen"     //属性：传感器开路故障
#define DATA_ATTR_FAULT_SENSORSHORT     @"Fault_SensorShort"    //属性：传感器短路故障
#define DATA_ATTR_FAULT_OVERTEMP        @"Fault_OverTemp"       //属性：超温故障


@interface IoTMainController : UIViewController<XPGWifiDeviceDelegate>

//用于切换设备
@property (nonatomic, strong) XPGWifiDevice *device;

@property (nonatomic, strong) NSArray       *appointmentImageList;
@property (nonatomic, strong) NSArray       *patternImageList;
@property (nonatomic, strong) NSArray       *appointmentTitleList;
@property (nonatomic, strong) NSArray       *patternTitleList;

//数据信息
@property (nonatomic,assign ) NSInteger     observedMode;
@property (nonatomic,assign ) NSInteger     observedReserveOnOff;
@property (nonatomic,assign ) NSInteger     observedCountDown_Reserve;
@property (nonatomic,assign ) NSInteger     observedTimeOut;
@property (nonatomic,assign ) NSInteger     observedRoomTemp;

@property (nonatomic, strong) NSArray       * lastFaults;

//写入数据接口
- (void)writeDataPoint:(IoTDeviceDataPoint)dataPoint value:(id)value;

- (id)initWithDevice:(XPGWifiDevice *)device;
- (id)initCurrentWithDevice:(XPGWifiDevice *)dev;

//获取当前实例
+ (IoTMainController *)currentController;

- (void)setUICircularSliderHide;
- (void)setUICircularSliderShow;

//关机、开机
- (void)onPower;

@end
