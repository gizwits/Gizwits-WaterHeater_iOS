/**
 * IoTAdvancedFeatures.m
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

#import "IoTAdvancedFeatures.h"
#import "UICircularSlider.h"
#import "IoTMainController.h"
#import "IoTFaultList.h"
#import "IoTAlertView.h"
#import <QuartzCore/QuartzCore.h>

@interface IoTAdvancedFeatures ()<UIAlertViewDelegate,IoTAlertViewDelegate>
{
    float iSensitivityValue;
    float iFilterLifeValue;
    
    //提示框
    IoTAlertView *_alertView;
}

@property (weak, nonatomic  ) IBOutlet UIButton         *btnSenstitvity;
@property (weak, nonatomic  ) IBOutlet UIButton         *btnFilter;
@property (weak, nonatomic  ) IBOutlet UIButton         *btnFault;

@property (weak, nonatomic  ) IBOutlet UIView           *sensitivityView;
@property (weak, nonatomic  ) IBOutlet UIView           *filterView;
@property (weak, nonatomic  ) IBOutlet UIView           *faultListView;

@property (weak, nonatomic  ) IBOutlet UICircularSlider *sliderCircular;

@property (weak, nonatomic  ) IBOutlet UISlider         *slider;
@property (weak, nonatomic  ) IBOutlet UILabel          *sliderState;

//滤网剩余寿命数值
@property (weak, nonatomic  ) IBOutlet UILabel          *labelFilterNumber;
//滤网寿命状态
@property (weak, nonatomic  ) IBOutlet UILabel          *labelFilterState;

@property (nonatomic, strong) XPGWifiDevice *device;
@property (nonatomic,strong ) IoTFaultList  *faultListCtrl;

@end

@implementation IoTAdvancedFeatures

- (id)initWithDevice:(XPGWifiDevice *)device
{
    self = [super init];
    if(self)
    {
        self.device = device;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //设置 IoTMainController 实例
    self.mainCtrl = [IoTMainController currentController];
    if(nil == self.mainCtrl)
    {
        NSLog(@"[IoTMainController currentController] cause error, abort.");
        abort();
    }

    self.navigationItem.title = @"故障信息";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"return_icon"] style:UIBarButtonItemStylePlain target:self action:@selector(onBack)];

    self.sliderCircular.transform = CGAffineTransformMakeRotation(M_PI);
    self.sliderCircular.sliderStyle = UICircularSliderStyleCircle;
    self.sliderCircular.minimumValue = 0;
    self.sliderCircular.maximumValue = 100;
    self.sliderCircular.minimumTrackTintColor = [UIColor colorWithRed:0.22 green:0.75 blue:0.91 alpha:1];
    self.sliderCircular.maximumTrackTintColor = [UIColor grayColor];
    [self setSliderEnabled:YES];
    self.slider.continuous = NO;
    self.btnFault.selected = YES;
    
    self.faultListCtrl = [[IoTFaultList alloc] init];
    self.faultListCtrl.view.frame = CGRectMake(0, 0, self.faultListView.frame.size.width, self.faultListView.frame.size.height);
    [self.faultListView addSubview:self.faultListCtrl.view];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.mainCtrl addObserver:self forKeyPath:@"airSensitivity" options:(NSKeyValueObservingOptionNew) context:nil];
    
    [self.mainCtrl addObserver:self forKeyPath:@"filterLife" options:(NSKeyValueObservingOptionNew) context:nil];
    
    //初始化控件的值
    [self ChangeSelect:self.slider];
    [self setNumberVaule:self.sliderCircular];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.mainCtrl removeObserver:self forKeyPath:@"airSensitivity"];
    [self.mainCtrl removeObserver:self forKeyPath:@"filterLife"];
    
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0)
    {
        self.sliderCircular.value = 100;
        self.labelFilterNumber.text = @"100";
        self.labelFilterState.text = @"正常";
    }
}

#pragma mark - Action
- (void)onBack
{
    if(self.navigationController.viewControllers.lastObject == self)
        [self.navigationController popViewControllerAnimated:YES];
}

//灵敏度
- (IBAction)SliderValue:(id)sender
{
    UISlider * Slider = sender;
    float i = 0;
    
    if (Slider.value < 1)
    {
        i = 0;
        self.sliderState.text = @"零档";
    }
    else if (Slider.value >1 && Slider.value < 2)
    {
        i = 1;
        self.sliderState.text = @"一档";
    }
    else if (Slider.value >2 && Slider.value <3)
    {
        i = 2;
        self.sliderState.text = @"二档";
    }
    else if (Slider.value >3 && Slider.value <4)
    {
        i = 3;
        self.sliderState.text = @"三档";
    }
    else if (Slider.value >=4)
    {
        i = 4;
        self.sliderState.text = @"四档";
    }
    
    self.slider.value = i;
}

- (void)ChangeSelect:(UISlider *)slider
{
    self.slider.value = iSensitivityValue;
    if (iSensitivityValue< 1)
        self.sliderState.text = @"零档";
    else if (iSensitivityValue == 1)
        self.sliderState.text = @"一档";
    else if (iSensitivityValue == 2)
        self.sliderState.text = @"二档";
    else if (iSensitivityValue == 3)
        self.sliderState.text = @"三档";
    else if (iSensitivityValue == 4)
        self.sliderState.text = @"四档";
}

- (void)setSliderEnabled:(BOOL)enabled
{
    self.sliderCircular.userInteractionEnabled = NO;
    if(!enabled)
        self.sliderCircular.thumbTintColor = [UIColor clearColor];
    else
        self.sliderCircular.thumbTintColor = [UIColor colorWithRed:0 green:0.89453125 blue:0.984375 alpha:1];
}

- (IBAction)onSensitivity:(id)sender {
    self.sensitivityView.alpha   = 1;
    self.filterView.alpha        = 0;
    self.faultListView.alpha     = 0;
    self.btnSenstitvity.selected = YES;
    self.btnFault.selected       = NO;
    self.btnFilter.selected      = NO;
}

- (IBAction)onFilter:(id)sender {
    self.sensitivityView.alpha   = 0;
    self.filterView.alpha        = 1;
    self.faultListView.alpha     = 0;
    self.btnSenstitvity.selected = NO;
    self.btnFilter.selected      = YES;
    self.btnFault.selected       = NO;
}

//滤网复位
- (IBAction)onScreenReset:(id)sender {
    //弹出滤网复位提示
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"温罄提示" message:@"是否复位" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alert addButtonWithTitle:@"取消"];
    [alert show];
}

- (IBAction)onAlarm:(id)sender {
    self.sensitivityView.alpha   = 0;
    self.filterView.alpha        = 0;
    self.faultListView.alpha     = 1;
    self.btnSenstitvity.selected = NO;
    self.btnFilter.selected      = NO;
    self.btnFault.selected       = YES;
}

- (void)setNumberVaule:(UICircularSlider *)slider{
    self.sliderCircular.value = iFilterLifeValue;
    int filter = self.sliderCircular.value;
    self.labelFilterNumber.text = [NSString stringWithFormat:@"%@",@(filter)];
    
    if (self.sliderCircular.value == 0)
        self.labelFilterState.text = @"故障";
    else
        self.labelFilterState.text = @"正常";
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
  
    if ([keyPath isEqualToString:@"airSensitivity"]) {
        float sensitivityValue = [[change objectForKey:@"new"] floatValue];
        
        iSensitivityValue = sensitivityValue;
        [self performSelector:@selector(ChangeSelect:) withObject:self.slider afterDelay:0.2f];
    }
    
    if ([keyPath isEqualToString:@"filterLife"]) {
        float filterLifeValue = [[change objectForKey:@"new"] floatValue];
        
        iFilterLifeValue = filterLifeValue;
        [self performSelector:@selector(setNumberVaule:) withObject:self.sliderCircular afterDelay:0.2f];
    }
}

@end
