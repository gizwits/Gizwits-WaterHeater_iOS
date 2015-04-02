/**
 * IoTShutdownStatus.m
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

#import "IoTShutdownStatus.h"
#import "IoTMainController.h"
#import "IoTMainMenu.h"

@interface IoTShutdownStatus ()
{
    __strong IoTShutdownStatus * shutdownStatusCtrl;
}

@property (nonatomic, strong) XPGWifiDevice *device;

@property (weak, nonatomic  ) IBOutlet UILabel       *labelRoomTemp;

@end

@implementation IoTShutdownStatus

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
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.labelRoomTemp setText:[NSString stringWithFormat:@"%ld",_roomTemp]];
    [self.mainCtrl addObserver:self forKeyPath:@"observedRoomTemp" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.mainCtrl removeObserver:self forKeyPath:@"observedRoomTemp"];
}

#pragma mark - action

- (IBAction)onPowerOn:(id)sender {
    [self hide:YES];
    [self.mainCtrl setUICircularSliderShow];
    [self.mainCtrl writeDataPoint:IoTDeviceWriteOnOff value:@1];
    [self.mainCtrl writeDataPoint:IoTDeviceWriteUpdateData value:nil];
    [IoTMainController currentController].lastFaults = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSInteger roomTemp = [[change objectForKey:@"new"] integerValue];
    [self.labelRoomTemp setText:[NSString stringWithFormat:@"%ld",(long)roomTemp]];
}

#pragma mark - delegate
- (void)show:(BOOL)animated
{
    shutdownStatusCtrl = self;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationsEnabled:animated];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [[UIApplication sharedApplication].keyWindow addSubview:self.view];
    [UIView commitAnimations];
    CGRect frame = CGRectMake(0,
                               60,
                               [UIApplication sharedApplication].keyWindow.frame.size.width,
                               [UIApplication sharedApplication].keyWindow.frame.size.height-60);
    self.view.frame = frame;
    self.mainCtrl.navigationItem.rightBarButtonItem = nil;
}

- (void)hide:(BOOL)animated
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationsEnabled:animated];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    [self.view removeFromSuperview];
    [UIView commitAnimations];
    self.mainCtrl.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"water_heating_start_icon"] style:UIBarButtonItemStylePlain target:self.mainCtrl action:@selector(onPower)];
    shutdownStatusCtrl = nil;
}

@end
