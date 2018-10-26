//
//  UIView+AdaptScreenWidth.m
//  TestXib
//
//  Created by lbs on 2018/8/14.
//  Copyright © 2018年 by. All rights reserved.
//

#import "UIView+AdaptScreen.h"

// 基准屏幕宽度
#define kRefereWidth 375.0
// 以屏幕宽度为固定比例关系，来计算对应的值。假设：基准屏幕宽度375，floatV=10；当前屏幕宽度为750时，那么返回的值为20
#define AdaptW(floatValue) (floatValue*[[UIScreen mainScreen] bounds].size.width/kRefereWidth)

@implementation UIView (AdaptScreen)

- (void)adaptScreenWidthWithType:(AdaptScreenWidthType)type
                      exceptViews:(NSArray<Class> *)exceptViews {
    if (![self isExceptViewClassWithClassArray:exceptViews]) {
     
        // 是否要对约束进行等比例
        BOOL adaptConstraint = ((type & AdaptScreenWidthTypeConstraint) || type == AdaptScreenWidthTypeAll);
        
        // 是否对字体大小进行等比例
        BOOL adaptFontSize = ((type & AdaptScreenWidthTypeFontSize) || type == AdaptScreenWidthTypeAll);
        
        // 是否对圆角大小进行等比例
        BOOL adaptCornerRadius = ((type & AdaptScreenWidthTypeCornerRadius) || type == AdaptScreenWidthTypeAll);
        
        // 约束
        if (adaptConstraint) {
            [self.constraints enumerateObjectsUsingBlock:^(__kindof NSLayoutConstraint * _Nonnull subConstraint, NSUInteger idx, BOOL * _Nonnull stop) {
                subConstraint.constant = AdaptW(subConstraint.constant);
            }];
        }
        
        // 字体大小
        if (adaptFontSize) {
            
            if ([self isKindOfClass:[UILabel class]] && ![self isKindOfClass:NSClassFromString(@"UIButtonLabel")]) {
                UILabel *labelSelf = (UILabel *)self;
                labelSelf.font = [UIFont systemFontOfSize:AdaptW(labelSelf.font.pointSize)];
            }
            else if ([self isKindOfClass:[UITextField class]]) {
                UITextField *textFieldSelf = (UITextField *)self;
                textFieldSelf.font = [UIFont systemFontOfSize:AdaptW(textFieldSelf.font.pointSize)];
            }
            else  if ([self isKindOfClass:[UIButton class]]) {
                UIButton *buttonSelf = (UIButton *)self;
                buttonSelf.titleLabel.font = [UIFont systemFontOfSize:AdaptW(buttonSelf.titleLabel.font.pointSize)];
            }
            else  if ([self isKindOfClass:[UITextView class]]) {
                UITextView *textViewSelf = (UITextView *)self;
                textViewSelf.font = [UIFont systemFontOfSize:AdaptW(textViewSelf.font.pointSize)];
            }
        }
        
        // 圆角
        if (adaptCornerRadius) {
            if (self.layer.cornerRadius) {
                self.layer.cornerRadius = AdaptW(self.layer.cornerRadius);
            }
        }
        
        [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull subView, NSUInteger idx, BOOL * _Nonnull stop) {
            // 继续对子view操作
            [subView adaptScreenWidthWithType:type exceptViews:exceptViews];
        }];
    }
}

// 当前view对象是否是例外的视图
- (BOOL)isExceptViewClassWithClassArray:(NSArray<Class> *)classArray {
    __block BOOL isExcept = NO;
    [classArray enumerateObjectsUsingBlock:^(Class  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([self isKindOfClass:obj]) {
            isExcept = YES;
            *stop = YES;
        }
    }];
    return isExcept;
}


@end
