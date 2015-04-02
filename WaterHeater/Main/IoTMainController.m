/**
 * IoTMainController.m
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

#import "IoTMainController.h"
#import "IoTShutdownStatus.h"
#import "IoTTimingSelection.h"
#import "IoTRecord.h"
#import "IoTAlertView.h"
#import "IoTMainMenu.h"
#import "UICircularSlider.h"
#import <CoreLocation/CoreLocation.h>
#import "IoTPatternList.h"
#import "IoTChangePassword.h"
#import "IoTAdvancedFeatures.h"

#define ALERT_TAG_SHUTDOWN          1

@interface IoTMainController ()<UIAlertViewDelegate,IoTAlertViewDelegate,IoTTimingSelectionDelegate,CLLocationManagerDelegate>
{
    //提示框
    IoTAlertView *_alertView;
    
    //数据点的临时变量
    BOOL bSwitch;
    BOOL bReserveOnOff;
    NSInteger iSetTemp;
    NSInteger iMode;
    NSInteger iRoomTemp;
    NSInteger iCountDown;
    NSInteger iTimeOut;
    
    //临时数据
    NSArray *modeImages, *modeTexts;
    BOOL isReiveSuccess;
    
    //时间选择
    IoTTimingSelection *_timingSelection;
}

@property (weak, nonatomic  ) IBOutlet UIView                    *sliderContainer;
@property (weak, nonatomic  ) IBOutlet UILabel                   *labelRoomTemp;
@property (weak, nonatomic  ) IBOutlet UILabel                   *labelSetTemp;
@property (weak, nonatomic  ) IBOutlet UILabel                   *labelWaterHeaterStatus;
@property (weak, nonatomic  ) IBOutlet UIButton                  *buttonAppointment;
@property (weak, nonatomic  ) IBOutlet UIButton                  *buttonPattern;
@property (weak, nonatomic  ) IBOutlet UIImageView               *imageAppointment;
@property (weak, nonatomic  ) IBOutlet UIImageView               *imagePattern;
@property (weak, nonatomic  ) IBOutlet UICircularSlider          *sliderCircular;

@property (nonatomic, strong) IoTShutdownStatus         * shutdownStatusCtrl;
@property (nonatomic, strong) NSArray                   * alerts;
@property (nonatomic, strong) NSArray                   * faults;
@property (nonatomic, strong) NSString                  * currentdid;
@property (strong, nonatomic) SlideNavigationController *navCtrl;

@end

@implementation IoTMainController

#pragma mark - controller
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    isReiveSuccess = NO;
    [self initDevice];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showOrHideWithIsMenuOpen)
                                                 name:SlideNavigationControllerDidClose object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //设备已解除绑定，或者断开连接，退出
    if(![self.device isBind:[IoTProcessModel sharedModel].currentUid] || !self.device.isConnected)
    {
        [self onDisconnected];
        return;
    }
    
    //更新侧边菜单数据
    [((IoTMainMenu *)[SlideNavigationController sharedInstance].leftMenu).tableView reloadData];
    
    //在页面加载后，自动更新数据
    if(self.device.isOnline)
    {
        IoTAppDelegate.hud.labelText = @"正在更新数据...";
        [IoTAppDelegate.hud showAnimated:YES whileExecutingBlock:^{
            sleep(30);
        }];
        [self writeDataPoint:IoTDeviceWriteUpdateData value:nil];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDeivceLogin) name:@"deviceLogin" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if([self.navigationController.viewControllers indexOfObject:self] > self.navigationController.viewControllers.count)
        self.device.delegate = nil;

    //防止 delegate 出错，退出之前先关掉弹出框
    [_alertView hide:YES];
    [_timingSelection hide:YES];
    [_shutdownStatusCtrl hide:YES];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initNavigationItem];
    [self initButtonImage];
    [self initButtonTitle];
    [self initCircucal];
}

#pragma mark - 圆圈控件设置
- (void)setTempSliderEnabled:(BOOL)enabled
{
    self.sliderCircular.userInteractionEnabled = enabled;
    if(!enabled)
        self.sliderCircular.thumbTintColor = [UIColor clearColor];
    else
        self.sliderCircular.thumbTintColor = [UIColor whiteColor];
}

//隐藏圆圈调温
- (void)setUICircularSliderHide{
    self.sliderContainer.alpha = 0;
    self.labelWaterHeaterStatus.alpha = 0;
}

//显示圆圈调温
- (void)setUICircularSliderShow{
    self.sliderContainer.alpha = 1;
    self.labelWaterHeaterStatus.alpha = 1;
}

//===========圆圈控件===========
- (void)onUpdateProgress:(UICircularSlider *)slider{
    [self onUpdateTemp:NO];
}

- (void)onSliderTouchedUpInside:(UICircularSlider *)slider{
    [self onUpdateTemp:NO];
    iSetTemp = ((int)slider.value);
    [self writeDataPoint:IoTDeviceWriteSetTemp value:@(iSetTemp)];
    [self writeDataPoint:IoTDeviceWriteUpdateData value:nil];
}

- (void)onUpdateTemp:(BOOL)updateSlider {
    if(updateSlider)
        self.sliderCircular.value = iSetTemp;
    _labelSetTemp.text = [NSString stringWithFormat:@"%d",(int)self.sliderCircular.value];
}

#pragma mark - 发送数据
- (void)writeDataPoint:(IoTDeviceDataPoint)dataPoint value:(id)value{
    
    NSDictionary *data = nil;
    
    switch (dataPoint)
    {
        case IoTDeviceWriteUpdateData:
            data = @{DATA_CMD: @(IoTDeviceCommandRead)};
            break;
        case IoTDeviceWriteOnOff:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_SWITCH: value}};
            break;
        case IoTDeviceWriteCountDown:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_COUNT_DOWN: value}};
            break;
        case IoTDeviceWriteTimeOn:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_TIME_ON: value}};
            break;
        case IoTDeviceWriteTimeReserve:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_TIME_RESERVE: value}};
            break;
        case IoTDeviceWriteSetTemp:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_SET_TEMP: value}};
            break;
        case IoTDeviceWriteRoomTemp:
            data = @{DATA_CMD:@(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_ROOM_TEMP: value}};
            break;
        case IoTDeviceWriteMode:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_MODE: value}};
            break;
        default:
            NSLog(@"Error: write invalid datapoint, skip.");
            return;
    }
    NSLog(@"Write data: %@", data);
    [self.device write:data];
}

#pragma mark - 读取数据
- (id)readDataPoint:(IoTDeviceDataPoint)dataPoint data:(NSDictionary *)data
{
    if(![data isKindOfClass:[NSDictionary class]])
    {
        NSLog(@"Error: could not read data, error data format.");
        return nil;
    }
    
    NSNumber *nCommand = [data valueForKey:DATA_CMD];
    if(![nCommand isKindOfClass:[NSNumber class]])
    {
        NSLog(@"Error: could not read cmd, error cmd format.");
        return nil;
    }
    
    int nCmd = [nCommand intValue];
    if(nCmd != IoTDeviceCommandResponse && nCmd != IoTDeviceCommandNotify)
    {
        NSLog(@"Error: command is invalid, skip.");
        return nil;
    }
    
    NSDictionary *attributes = [data valueForKey:DATA_ENTITY];
    if(![attributes isKindOfClass:[NSDictionary class]])
    {
        NSLog(@"Error: could not read attributes, error attributes format.");
        return nil;
    }
    
    switch (dataPoint)
    {
        case IoTDeviceWriteOnOff:
            return [attributes valueForKey:DATA_ATTR_SWITCH];
        case IoTDeviceWriteMode:
            return [attributes valueForKey:DATA_ATTR_MODE];
        case IoTDeviceWriteSetTemp:
            return [attributes valueForKey:DATA_ATTR_SET_TEMP];
        case IoTDeviceWriteRoomTemp:
            return [attributes valueForKey:DATA_ATTR_ROOM_TEMP];
        case IoTDeviceWriteTimeReserve:
            return [attributes valueForKey:DATA_ATTR_TIME_RESERVE];
        case IoTDeviceWriteCountDown:
            return [attributes valueForKey:DATA_ATTR_COUNT_DOWN];
        case IoTDeviceWriteTimeOn:
            return [attributes valueForKey:DATA_ATTR_TIME_ON];
        default:
            NSLog(@"Error: read invalid datapoint, skip.");
            break;
            
    }
    return nil;
}

#pragma mark - delegate 接收数据
- (BOOL)XPGWifiDevice:(XPGWifiDevice *)device didReceiveData:(NSDictionary *)data result:(int)result{
    
    isReiveSuccess = YES;
    if(![device.did isEqualToString:self.device.did])
        return YES;
    
    [IoTAppDelegate.hud hide:YES];
    [self.shutdownStatusCtrl hide:YES];
    
    self.alerts = [data valueForKey:@"alerts"];
    self.faults = [data valueForKey:@"faults"];
    
    /**
     * 数据部分
     */
    NSDictionary *_data = [data valueForKey:@"data"];
    if(nil != _data)
    {
        NSString *onOff            = [self readDataPoint:IoTDeviceWriteOnOff data:_data];
        NSString *mode             = [self readDataPoint:IoTDeviceWriteMode data:_data];
        NSString *roomTemp         = [self readDataPoint:IoTDeviceWriteRoomTemp data:_data];
        NSString *setTemp          = [self readDataPoint:IoTDeviceWriteSetTemp data:_data];
        NSString *reserveOnOff     = [self readDataPoint:IoTDeviceWriteTimeOn data:_data];
        NSString *countDown        = [self readDataPoint:IoTDeviceWriteCountDown data:_data];
        NSString *timeReserve      = [self readDataPoint:
                                       IoTDeviceWriteTimeReserve data:_data];
        
        
        bSwitch                    = [self prepareForUpdateFloat:onOff value:bSwitch];
        bReserveOnOff              = [self prepareForUpdateFloat:reserveOnOff value:bReserveOnOff];
        iMode                      = [self prepareForUpdateFloat:mode value:iMode];
        iSetTemp                   = [self prepareForUpdateFloat:setTemp value:iSetTemp];
        iRoomTemp                  = [self prepareForUpdateFloat:roomTemp value:iRoomTemp];
        iCountDown                 = [self prepareForUpdateFloat:countDown value:iCountDown];
        iTimeOut                   = [self prepareForUpdateFloat:timeReserve value:iTimeOut];
        
        //添加被观察者值
        self.observedMode = iMode;
        self.observedCountDown_Reserve = iCountDown;
        self.observedReserveOnOff = bReserveOnOff;
        self.observedTimeOut = iTimeOut;
        self.observedRoomTemp = iRoomTemp;
        
        /**
         * 更新到 UI
         */
        [self updateRoomTemp];
        [self updateSetTemp];
        
        [self selectPattern:iMode];
        [self selectAppointmentWithReserveTime:bReserveOnOff WithCountDown:iCountDown];
        [self updateWaterHeaterStatus];
        [self onUpdateTemp:YES];
        
        self.view.userInteractionEnabled = bSwitch;
        
        if(!_device.isOnline){
          self.view.userInteractionEnabled = NO;
        }else{
          self.view.userInteractionEnabled = YES;
        }
        //没有开机，切换页面
        if(!bSwitch)
        {
            [self onPower];
            [self setUICircularSliderHide];
        }else{
            [self setUICircularSliderShow];
        }
       
    }
   
    /**
     * 报警和错误
     */
    if([self.navigationController.viewControllers lastObject] != self)
        return YES;
    
    /**
     * 清理旧报警及故障
     */
    [[IoTRecord sharedInstance] clearAllRecord];
    
    //判断状态给的faultslist 和 上次的 faultslist 不同，从而确定是否弹出alarm对话框。
    if([self onComparedFaultsListAndNew]){
        [self onAlarmAlertView];
        [self onUpdateAlarm];
    }
    if(self.alerts.count == 0 && self.faults.count == 0)
    {
        [self onUpdateAlarm];
        return YES;
    }
    /**
     * 添加当前故障
     */
    NSDate *date = [NSDate date];
    if(self.alerts.count > 0)
    {
        for(NSDictionary *dict in self.alerts)
        {
            for(NSString *name in dict.allKeys)
            {
                [[IoTRecord sharedInstance] addRecord:date information:name];
            }
        }
    }
    
    if(self.faults.count > 0)
    {
        for(NSDictionary *dict in self.faults)
        {
            for(NSString *name in dict.allKeys)
            {
                [[IoTRecord sharedInstance] addRecord:date information:name];
            }
        }
    }
    
    [self onUpdateAlarm];
    
    return YES;
}

- (CGFloat)prepareForUpdateFloat:(NSString *)str value:(CGFloat)value
{
    if([str isKindOfClass:[NSNumber class]] ||
       ([str isKindOfClass:[NSString class]] && str.length > 0))
    {
        CGFloat newValue = [str floatValue];
        if(newValue != value)
        {
            value = newValue;
        }
    }
    return value;
}

- (NSInteger)prepareForUpdateInteger:(NSString *)str value:(NSInteger)value
{
    if([str isKindOfClass:[NSNumber class]] ||
       ([str isKindOfClass:[NSString class]] && str.length > 0))
    {
        NSInteger newValue = [str integerValue];
        if(newValue != value)
        {
            value = newValue;
        }
    }
    return value;
}

#pragma mark - Properties
- (void)setDevice:(XPGWifiDevice *)device
{
    _device.delegate = nil;
    _device = device;
    [self initDevice];
}

#pragma mark - XPGWifiDeviceDelegate
- (void)XPGWifiDeviceDidDisconnected:(XPGWifiDevice *)device
{
    if(![device.did isEqualToString:self.device.did])
        return;
    
    [self onDisconnected];
}

#pragma mark - Actions
//关机
- (void)onPower {

    //不在线就不能点
    if(!self.device.isOnline)
        return;
    
    if(bSwitch)
    {
        //关机
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"是否确定关机？" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
        alertView.tag = ALERT_TAG_SHUTDOWN;
        [alertView show];
        
    }
    else
    {
        //开机
        self.shutdownStatusCtrl = [[IoTShutdownStatus alloc]init];
        self.shutdownStatusCtrl.roomTemp = iRoomTemp;
        self.shutdownStatusCtrl.mainCtrl = self;
        [self.shutdownStatusCtrl show:YES];
        [self showOrHideWithIsMenuOpen];
    }
}

- (void)onDisconnected {
    //断线且页面在控制页面时才弹框
    UIViewController *currentController = self.navigationController.viewControllers.lastObject;
    
    if(!self.device.isConnected &&
       ([currentController isKindOfClass:[IoTMainController class]] ||
        [currentController isKindOfClass:[IoTShutdownStatus class]]))
    {
        [IoTAppDelegate.hud hide:YES];
        [_alertView hide:YES];
        [[[IoTAlertView alloc] initWithMessage:@"连接已断开" delegate:nil titleOK:@"确定"] show:YES];
        [self onExitToDeviceList];
    }
    else {
        [self onDeivceLogin];
    }
}

- (void)onExitToDeviceList{
    //退出到列表
     UIViewController *currentController = self.navigationController.viewControllers.lastObject;
    for(int i=(int)(self.navigationController.viewControllers.count-1); i>0; i--)
    {
        UIViewController *controller = self.navigationController.viewControllers[i];
        if(([controller isKindOfClass:[IoTDeviceList class]] && [currentController isKindOfClass:[IoTMainController class]]) || [currentController isKindOfClass:[IoTShutdownStatus class]])
        {
            [self.navigationController popToViewController:controller animated:YES];
        }
    }
}

- (void)onDeivceLogin{
    [_device login:[IoTProcessModel sharedModel].currentUid token:[IoTProcessModel sharedModel].currentToken];
}

- (IBAction)onAppointment:(id)sender {
    //进入预约列表
    IoTPatternList *appoinmentList = [[IoTPatternList alloc] init];
    //预约列表
    appoinmentList.modeSelect = APPOINTMENT_MODE;
    [self.navigationController pushViewController:appoinmentList animated:YES];
}

- (IBAction)onPattern:(id)sender {
    //进入功能模式列表
    IoTPatternList *appoinmentList = [[IoTPatternList alloc] init];
    //功能模式列表
    appoinmentList.modeSelect = PATTERN_MODE;
    [self.navigationController pushViewController:appoinmentList animated:YES];
}

//弹出警报对话框
- (void)onUpdateAlarm {
    //自定义标题
    CGRect rc = CGRectMake(0, 0, 180, 64);
    
    UILabel *label = [[UILabel alloc] initWithFrame:rc];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"热水器";
    label.font = [UIFont boldSystemFontOfSize:label.font.pointSize];
    
    UIButton *view = [UIButton buttonWithType:UIButtonTypeCustom];
    [view addTarget:self action:@selector(onAlarmList) forControlEvents:UIControlEventTouchUpInside];
    view.frame = rc;
    [view addSubview:label];
    
    //故障条目数，原则上不大于65535
    NSInteger count = [IoTRecord sharedInstance].recordedCount;
    if(count > 65535)
        count = 65535;
    //故障条数目的气泡写法
    if(count > 0)
    {
        double n = log10(count);
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(125, 23, 22+n*8, 18)];
        imageView.image = [[UIImage imageNamed:@"fault_tips.png"] stretchableImageWithLeftCapWidth:11 topCapHeight:0];
        [view addSubview:imageView];
        
        UILabel *labelBadge = [[UILabel alloc] initWithFrame:imageView.bounds];
        labelBadge.textColor = [UIColor colorWithRed:0.1484375 green:0.49609375 blue:0.90234375 alpha:1.00];
        labelBadge.textAlignment = NSTextAlignmentCenter;
        labelBadge.text = [NSString stringWithFormat:@"%@", @(count)];
        [imageView addSubview:labelBadge];
    }
    self.navigationItem.titleView = view;
}

//弹出报警提示
- (void)onAlarmAlertView{
    [_alertView hide:YES];
    _alertView = [[IoTAlertView alloc] initWithMessage:@"设备故障" delegate:self titleOK:@"暂不处理" titleCancel:@"拨打客服"];
    [_alertView show:YES];
}

//跳入警报详细页面
- (void)onAlarmList {
    if(self.alerts.count == 0 && self.faults.count == 0)
    {
        NSLog(@"没有报警");
    }else{
        IoTAdvancedFeatures *faultList = [[IoTAdvancedFeatures alloc] init];
        [self.navigationController pushViewController:faultList animated:YES];
    }
}

- (void)onToggleLeft{
    [[SlideNavigationController sharedInstance] toggleLeftMenu];
    [self showOrHideWithIsMenuOpen];
}

- (void)showOrHideWithIsMenuOpen{
    if([SlideNavigationController sharedInstance].isMenuOpen){
        [self updateShutDownStatusHide];
    }else{
        [self updateShutDownStatusShow];
    }
}

- (BOOL)onComparedFaultsListAndNew{
    NSArray *newList = self.faults;
    NSArray *lastList = self.lastFaults;
    
    if(_currentdid == nil){
        _currentdid = _device.did;
    }
    if(_lastFaults == nil && [self.faults count] > 0){
        _lastFaults = [self.faults copy];
        return YES;
    }
    
    if([newList count] > 0){
        for (int i = 0; i < [newList count] ; i++){
            if (![lastList containsObject:[newList objectAtIndex:i]]){
                self.lastFaults  = [self.faults copy];
                return YES;
            }
        }
    }else{
        self.lastFaults  = [self.faults copy];
        return NO;
    }
    self.lastFaults  = [self.faults copy];
    return NO;
}

#pragma mark - alertview delegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == 1 && buttonIndex == 0)
    {
        IoTAppDelegate.hud.labelText = @"正在关机...";
        [IoTAppDelegate.hud showAnimated:YES whileExecutingBlock:^{
            sleep(61);
        }];
        [self writeDataPoint:IoTDeviceWriteOnOff value:@0];
        [self writeDataPoint:IoTDeviceWriteUpdateData value:nil];
        [self setUICircularSliderHide];
    }
}

- (void)IoTAlertViewDidDismissButton:(IoTAlertView *)alertView withButton:(BOOL)isConfirm
{
    //拨打客服
    if(!isConfirm)
        [IoTAppDelegate callServices];
}

#pragma mark - 取得当前maincontroller实例
+ (IoTMainController *)currentController
{
    SlideNavigationController *navCtrl = [SlideNavigationController sharedInstance];
    for(int i=(int)(navCtrl.viewControllers.count-1); i>0; i--)
    {
        if([navCtrl.viewControllers[i] isKindOfClass:[IoTMainController class]])
            return navCtrl.viewControllers[i];
    }
    return nil;
}

#pragma mark - ui更新操作
- (void)updateShutDownStatusShow{
    self.shutdownStatusCtrl.view.alpha = 0.75f;
}

- (void)updateShutDownStatusHide{
    self.shutdownStatusCtrl.view.alpha = 0.0f;
}

- (void)updateWaterHeaterStatus{
     dispatch_async(dispatch_get_main_queue(), ^{
        if(iSetTemp - iRoomTemp > 5){
            _labelWaterHeaterStatus.text = @"正在加热状态";
        }else if (iSetTemp - iRoomTemp <= 5 && iSetTemp - iRoomTemp >= 0){
            _labelWaterHeaterStatus.text = @"热水器保温中";
        }else{
            _labelWaterHeaterStatus.text = @"";
        }
    });
}

- (void)updateSetTemp{
    if(iSetTemp >= 30 && iSetTemp <= 75){
        _labelSetTemp.text = [NSString stringWithFormat:@"%ld",(long)iSetTemp];
    }
}

- (void)updateRoomTemp{
    _labelRoomTemp.text = [NSString stringWithFormat:@"%ld",(long)iRoomTemp];
}

- (void)selectAppointment:(NSInteger)index{
    _imageAppointment.image = [UIImage imageNamed:[_appointmentImageList objectAtIndex:index]];
    [_buttonAppointment setTitle:[_appointmentTitleList objectAtIndex:index] forState:UIControlStateNormal];
}

- (void)selectPattern:(NSInteger)index{
    _imagePattern.image = [UIImage imageNamed:[_patternImageList objectAtIndex:index]];
    [_buttonPattern setTitle:[_patternTitleList objectAtIndex:index] forState:UIControlStateNormal];
}

- (void)selectAppointmentWithReserveTime:(NSInteger)reserveTime
                           WithCountDown:(NSInteger)coutdown{
    if(reserveTime || coutdown > 0){
        [self.buttonAppointment setTitle:@"已预约" forState:UIControlStateNormal];
    }else{
        [self.buttonAppointment setTitle:@"预约用水" forState:UIControlStateNormal];
    }
}

#pragma mark - 初始化
//初始化按钮图片
- (void)initButtonImage{
    
    _patternImageList =
                @[@"home_tab_intelligence_icon@2x.png",
                  @"home_tab_energy_icon@2x.png",
                  @"home_tab_fullpower@2x.png",
                  @"home_tab_heating_icon@2x.png",
                  @"home_tab_temperature_icon@2x.png",
                  @"home_tab_safe_icon@2x.png"];
    
    _appointmentImageList =  @[@"pattern_alarm_icon@2x.png",
                               @"pattern_alarm_icon@2x.png"];
}

//初始化按钮题目
- (void)initButtonTitle{
    _patternTitleList     = @[  @"智能模式",
                                @"节能模式",
                                @"速热模式",
                                @"加热模式",
                                @"保温模式",
                                @"安全模式"];
    
    _appointmentTitleList = @[@"倒计时预约",
                              @"定时预约"];
}

//初始化圆圈空间
- (void)initCircucal{
    //圈圈控件属性设置
    self.sliderCircular.transform = CGAffineTransformMakeRotation(M_PI);
    self.sliderCircular.sliderStyle = UICircularSliderStyleCircle;
    self.sliderCircular.minimumValue = 30;
    self.sliderCircular.maximumValue = 75;
    self.sliderCircular.minimumTrackTintColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"water_heating_setting_round3"]];
    [self.sliderCircular addTarget:self action:@selector(onUpdateProgress:) forControlEvents:UIControlEventValueChanged];
    [self.sliderCircular addTarget:self action:@selector(onSliderTouchedUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [self.sliderCircular addTarget:self action:@selector(onSliderTouchedUpInside:) forControlEvents:UIControlEventTouchUpOutside];
    [self setTempSliderEnabled:YES];
    [self setUICircularSliderShow];
}

//初始化导航栏按钮
- (void)initNavigationItem{
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"water_heating_menu_icon"] style:UIBarButtonItemStylePlain target:self action:@selector(onToggleLeft)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"water_heating_start_icon"] style:UIBarButtonItemStylePlain target:self action:@selector(onPower)];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStyleBordered target:self action:NULL];
    self.navigationItem.backBarButtonItem = backItem;
}

//初始化设备
- (void)initDevice{
    //加载页面时，清除旧的故障报警记录
    [[IoTRecord sharedInstance] clearAllRecord];
    [self onUpdateAlarm];
    
    bSwitch       = 0;
    iMode         = 0;
    iRoomTemp     = 0;
    self.device.delegate = self;
}

//初始化controller并且传递设备
- (id)initWithDevice:(XPGWifiDevice *)device
{
    self = [super init];
    if(self)
    {
        if(nil == device)
        {
            NSLog(@"warning: device can't be null.");
            return nil;
        }
        self.device = device;
    }
    return self;
}

- (id)initCurrentWithDevice:(XPGWifiDevice *)dev{
    self = [IoTMainController currentController];
    if(self)
    {
        if(nil == dev)
        {
            NSLog(@"warning: device can't be null.");
            return nil;
        }
        self.device = dev;
    }
    return self;
}

@end
