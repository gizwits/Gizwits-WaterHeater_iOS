/**
 * IoTPatternCell.m
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

#import "IoTPatternListCell.h"

@interface IoTPatternListCell()

@end

@implementation IoTPatternListCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

//更新功能模式
- (void)updatePatternCellWithIndex:(NSInteger)row isShow:(BOOL)isShow{
    //图片列表
    NSArray *imageList = @[@"pattern_intelligence_icon@2x.png",
                           @"pattern_energy_icon@2x.png",
                           @"power_fullpower@2x.png",
                           @"pattern_heating_icon@2x.png",
                           @"pattern_temperature_icon@2x.png",
                           @"pattern_safe_icon@2x.png"];
    //题目
    NSArray *titleList = @[@"智能模式",
                           @"节能模式",
                           @"速热模式",
                           @"加热模式",
                           @"保温模式",
                           @"安全模式"];
    
    //图片
    self.imagePattern.image = [UIImage imageNamed:[imageList objectAtIndex:row]];
    
    //标题
    self.labelPatternTitle.text = [titleList objectAtIndex:row];
    
    if(isShow){
        self.imagePatternMark.hidden = NO;
    }else{
        self.imagePatternMark.hidden = YES;
    }
}

@end
