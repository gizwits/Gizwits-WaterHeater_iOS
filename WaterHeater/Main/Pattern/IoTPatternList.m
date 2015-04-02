/**
 * IoTPatternList.m
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

#import "IoTPatternList.h"
#import "IoTPatternListCell.h"
#import "IoTAppointmentListCell.h"
#import "IoTMainController.h"

@interface IoTPatternList (){
    NSInteger hourPicker;
    NSInteger minPicker;
    NSInteger modeIndex;
}

@property (nonatomic, strong) IoTMainController *mainCtrl;
@property (nonatomic, assign) NSInteger observedMode;
@property (nonatomic, assign) NSInteger observedCountDown_Reserve;
@property (nonatomic, assign) NSInteger observedReserveOnOff;
@property (nonatomic, assign) NSInteger observedReserveTimeOut;

@end

@implementation IoTPatternList

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    [self initMainCtrl];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"return_icon"] style:UIBarButtonItemStylePlain target:self action:@selector(onBack)];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (self.modeSelect == APPOINTMENT_MODE ){
        self.title = @"预约用水";
    }
    else if(self.modeSelect == PATTERN_MODE ){
        self.title = @"模式";
    }
    [self.mainCtrl addObserver:self forKeyPath:@"observedMode" options:NSKeyValueObservingOptionNew context:nil];
    [self.mainCtrl addObserver:self forKeyPath:@"observedCountDown_Reserve" options:NSKeyValueObservingOptionNew context:nil];
    [self.mainCtrl addObserver:self forKeyPath:@"observedReserveOnOff" options:NSKeyValueObservingOptionNew context:nil];
    [self.mainCtrl addObserver:self forKeyPath:@"observedTimeOut" options:NSKeyValueObservingOptionNew context:nil];
    [self.mainCtrl writeDataPoint:IoTDeviceWriteUpdateData value:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.mainCtrl removeObserver:self forKeyPath:@"observedMode"];
    [self.mainCtrl removeObserver:self forKeyPath:@"observedCountDown_Reserve"];
    [self.mainCtrl removeObserver:self forKeyPath:@"observedReserveOnOff"];
    [self.mainCtrl removeObserver:self forKeyPath:@"observedTimeOut"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//初始化mainctrl
- (void)initMainCtrl{
    self.mainCtrl = [IoTMainController currentController];
}

- (void)onBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -tableview delegate and datasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (self.modeSelect == APPOINTMENT_MODE ){
        return 2;
    }
    else if(self.modeSelect == PATTERN_MODE ){
        return 6;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *customCellIdentifier = @"";
    static NSString *className = @"";
    
    //预约模式
    if (self.modeSelect == APPOINTMENT_MODE){
        customCellIdentifier = @"IoTAppointmentListCell";
        className = @"IoTAppointmentListCell";
        IoTAppointmentListCell *cell = [tableView dequeueReusableCellWithIdentifier:customCellIdentifier];
        if(cell == nil){
            UINib *nib = [UINib nibWithNibName:customCellIdentifier bundle:nil];
            [tableView registerNib:nib forCellReuseIdentifier:className];
            cell = [tableView dequeueReusableCellWithIdentifier:customCellIdentifier];
        }
        if (indexPath.row == 0)
            [cell updateAppointmentCellWithIndex:indexPath.row isOpen:[self countDowToShowBoolean:indexPath.row] WithMin:_observedCountDown_Reserve];
        else
            [cell updateAppointmentCellWithIndex:indexPath.row isOpen:[self countDowToShowBoolean:indexPath.row] WithMin:_observedReserveTimeOut];
        return cell;
    }
    
    //功能模式
    else if (self.modeSelect == PATTERN_MODE)
    {
        customCellIdentifier = @"IoTPatternListCell";
        className = @"IoTPatternListCell";
        IoTPatternListCell *cell = [tableView dequeueReusableCellWithIdentifier:customCellIdentifier];
        if(cell == nil){
            UINib *nib = [UINib nibWithNibName:customCellIdentifier bundle:nil];
            [tableView registerNib:nib forCellReuseIdentifier:className];
            cell = [tableView dequeueReusableCellWithIdentifier:customCellIdentifier];
        }
        [cell updatePatternCellWithIndex:indexPath.row
                                  isShow:[self sModeToShowBoolean:indexPath.row]];
        return cell;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 80;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.modeSelect == PATTERN_MODE){
        [self.mainCtrl writeDataPoint:IoTDeviceWriteMode value:@(indexPath.row)];
        self.observedMode = indexPath.row;
        [self.tableView reloadData];
    }
}

#pragma mark - observe
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"observedMode"]){
       _observedMode = [[change objectForKey:@"new"] integerValue];
    }else if([keyPath isEqualToString:@"observedCountDown_Reserve"]){
        _observedCountDown_Reserve = [[change objectForKey:@"new"] integerValue];
        
    }else if ([keyPath isEqualToString:@"observedReserveOnOff"]){
        _observedReserveOnOff = [[change objectForKey:@"new"] integerValue];
    }
    else if([keyPath isEqualToString:@"observedTimeOut"]){
        _observedReserveTimeOut = [[change objectForKey:@"new"] integerValue];
    }
    [self.tableView reloadData];
}

#pragma mark - Utils
- (BOOL)sModeToShowBoolean:(NSUInteger)row{
    if(row == _observedMode){
        return YES;
    }else{
        return NO;
    }
}

- (BOOL)countDowToShowBoolean:(NSUInteger)row{
    if (row == 0){
        if( _observedCountDown_Reserve > 0){
            return YES;
        }else{
            return NO;
        }
    }
    else if (row == 1){
        if(_observedReserveOnOff){
            return YES;
        }else{
            return NO;
        }
    }
    return NO;
}

@end