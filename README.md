简书文章：(https://www.jianshu.com/p/cf049bebdc6c)[https://www.jianshu.com/p/cf049bebdc6c]
## 前言
  
&emsp; &emsp;在此我不是和大家讨论，xib相对约束的使用，因为这些文章网上有一大堆的资料，这也不是我今天想要讲的东西。 
&emsp; &emsp;不知道大家平常有没有碰到过这样的情况。相信很多人在开发中都会使用storyboard和xib来写界面，所见即所得，拖拖拽拽就大工告成了,爽的很。不像纯代码写界面，还要各种alloc、addSubview。可提测后，UI设计师坐在你身边，对UI各种细节调整席卷而来。因为一般设计师是按照4.7屏幕来设计的，这个屏幕下的显示效果没问题，到了小点的屏幕或者大点屏幕的时候，就各种不满意了，各个控件的比例关系并不是他们想要的。每当这个时候就要从xib拉出NSLayoutConstraint属性来动态设置了。还有字体也是，xib设置了，还要钻进代码里面再动态设置一番，真是恶心死了！
&emsp; &emsp; 所以我在想为什么不能像安卓屏幕适配一样，一切都是等比例适配，我们只要对着一个屏幕尺寸去做开发，其他的自动等比例缩放（按照基准屏幕的宽度去缩放，比如屏幕宽度375的控件width = 10pt,那么屏幕宽度750时就是width = 20pt了）。
## 解决方案
&emsp; &emsp; 下文就是我针对上面的问题，提出的三种解决方案。
### 第一种：纯代码实现
&emsp; &emsp; 为了能够更加好的控制这些UI控件的布局和设置，我开始在新项目中用纯代码去写界面了。虽然用的是Masonnry自动布局，但也难免要设置具体的值，在设值时，我会在加一层AdaptW(floatValue)宏定义包装。

```
- (void)private_addConstraintForSubViews
{ 
    [self.titleView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(AdaptW(55));
        make.left.right.equalTo(self);
        make.top.equalTo(self);
    }];
    
    [self.pageCtl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.right.equalTo(self);
        make.height.mas_equalTo(AdaptW(8));
    }];
}
```
&emsp; &emsp;AdaptW(floatValue)其实就是一个BSFitdpiUtil工具类方法的调用，以常用的基准屏幕，iphone 6 的375x667尺寸去换算的。代码如下：

```
#define kRefereWidth 375.0 // 参考宽度
#define kRefereHeight 667.0 // 参考高度

#define AdaptW(floatValue) [BSFitdpiUtil adaptWidthWithValue:floatValue]

#import <Foundation/Foundation.h>

@interface BSFitdpiUtil : NSObject


/**
 以屏幕宽度为固定比例关系，来计算对应的值。假设：参考屏幕宽度375，floatV=10；当前屏幕宽度为750时，那么返回的值为20
 @param floatV 参考屏幕下的宽度值
 @return 当前屏幕对应的宽度值
 */
+ (CGFloat)adaptWidthWithValue:(CGFloat)floatV;

@end
```
```
#import "BSFitdpiUtil.h"

@implementation BSFitdpiUtil

+ (CGFloat)adaptWidthWithValue:(CGFloat)floatV;
{
    return floatV*[[UIScreen mainScreen] bounds].size.width/kRefereWidth;
}
@end
```
&emsp; &emsp; 字体大小的设置，我也是用这种工具类的换算的包装来实现的。

```
    self.bottomLab = [UILabel new];
    [self addSubview:self.bottomLab];
    self.bottomLab.font = kDefaultFont(Adapt(15));
    self.bottomLab.textColor = kFirstTextColor;
    self.bottomLab.textAlignment = NSTextAlignmentCenter;
```
&emsp; &emsp; 从此我再也不怕UI设计师来对UI细节了，你要等比例我就等比例给你看，不需要我就在BSFitdpiUtil工具类的adaptWidthWithValue方法，return一个原始值floatV。


### 第二种：利用IBInspectable关键字和分类
&emsp; &emsp;后来我到了新公司接手了个旧项目，工程里几乎所有的界面都是用xib来写的。惨了，UI设计师同事还跟我说，新写的界面都要等比例缩放，不然就要各种大小不一的屏幕对一下，我累她也累。
&emsp; &emsp;就是因为这种适配的问题，我两年前开始放弃了可视化的布局界面方式，改用纯代码。这次我想保持项目风格的统一，而且也想再次拥抱storyboard和xib,通过查找资料找到利用IBInspectable关键字和分类来实现等比例缩放的功能 （ IBInspectable 就是能够让你的自定义 UIView 的属性出现在 IB 中 Attributes inspector）。具体做法就是：

1.写一个NSLayoutConstraint的分类 
2.添加adapterScreen的属性（Bool 值，yes代表需要对屏幕进行等比例适配） 

```
 #import <UIKit/UIKit.h>

@interface NSLayoutConstraint (BSIBDesignable)

@property(nonatomic, assign) IBInspectable BOOL adapterScreen;

@end
```
3.在adapterScreen的set方法里面对NSLayoutConstraint对象的constant值进行换算

```
#import "NSLayoutConstraint+BSIBDesignable.h"
#import <objc/runtime.h>

// 基准屏幕宽度
#define kRefereWidth 375.0
// 以屏幕宽度为固定比例关系，来计算对应的值。假设：基准屏幕宽度375，floatV=10；当前屏幕宽度为750时，那么返回的值为20
#define AdaptW(floatValue) (floatValue*[[UIScreen mainScreen] bounds].size.width/kRefereWidth)


@implementation NSLayoutConstraint (BSIBDesignable)

//定义常量 必须是C语言字符串
static char *AdapterScreenKey = "AdapterScreenKey";

- (BOOL)adapterScreen{
    NSNumber *number = objc_getAssociatedObject(self, AdapterScreenKey);
    return number.boolValue;
}

- (void)setAdapterScreen:(BOOL)adapterScreen {
    
    NSNumber *number = @(adapterScreen);
    objc_setAssociatedObject(self, AdapterScreenKey, number, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (adapterScreen){
        self.constant = AdaptW(self.constant);
    }
}

@end
```

4.将该分类导入到工程中，就可以看到xib所有的约束有adapterScreen的属性了，切换至on，就可以达到想要的等比例适配效果了。
![xib等比例.png](https://upload-images.jianshu.io/upload_images/1280054-3ce76ef06636abee.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)



&emsp; &emsp; 除了给NSLayoutConstraint添加adapterScreen属性，也可以用同样的方式给UILabel、UIButton等对字体大小等比例缩放。但有个很大的缺点就是一个界面有很多控件，每个控件都有Constraints，这个集合里面每个约束都要设置adapterScreen的开关，太麻烦了，而且一旦要对旧的界面也行进同样的操作，想死的心都有。为了解决这个问题，想了个第三种方法。

### 第三种：用分类去遍历一个view上需要操作的目标并换算
&emsp; &emsp;这个方法其实原理很简单，核心就是一个个遍历换算。代码如下

```
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, BSAdaptScreenWidthType) {
    AdaptScreenWidthTypeNone = 0, 
    BSAdaptScreenWidthTypeConstraint = 1<<0, /**< 对约束的constant等比例 */
    BSAdaptScreenWidthTypeFontSize = 1<<1, /**< 对字体等比例 */
    BSAdaptScreenWidthTypeCornerRadius = 1<<2, /**< 对圆角等比例 */
    BSAdaptScreenWidthTypeAll = 1<<3, /**< 对现有支持的属性等比例 */
};

@interface UIView (BSAdaptScreen)

/**
 遍历当前view对象的subviews和constraints，对目标进行等比例换算
 
 @param type 想要和基准屏幕等比例换算的属性类型
 @param exceptViews 需要对哪些类进行例外
 */
- (void)adaptScreenWidthWithType:(BSAdaptScreenWidthType)type
                     exceptViews:(NSArray<Class> *)exceptViews;

@end
```

```
#import "UIView+BSAdaptScreen.h"

// 基准屏幕宽度
#define kRefereWidth 375.0
// 以屏幕宽度为固定比例关系，来计算对应的值。假设：基准屏幕宽度375，floatV=10；当前屏幕宽度为750时，那么返回的值为20
#define AdaptW(floatValue) (floatValue*[[UIScreen mainScreen] bounds].size.width/kRefereWidth)

@implementation UIView (BSAdaptScreen)

- (void)adaptScreenWidthWithType:(BSAdaptScreenWidthType)type
                      exceptViews:(NSArray<Class> *)exceptViews {
    if (type == AdaptScreenWidthTypeNone)  return;
    if (![self isExceptViewClassWithClassArray:exceptViews]) {
     
        // 是否要对约束进行等比例
        BOOL adaptConstraint = ((type & BSAdaptScreenWidthTypeConstraint) || type == BSAdaptScreenWidthTypeAll);
        
        // 是否对字体大小进行等比例
        BOOL adaptFontSize = ((type & BSAdaptScreenWidthTypeFontSize) || type == BSAdaptScreenWidthTypeAll);
        
        // 是否对圆角大小进行等比例
        BOOL adaptCornerRadius = ((type & BSAdaptScreenWidthTypeCornerRadius) || type == BSAdaptScreenWidthTypeAll);
        
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

```

最后，不管是用xib拖控件拉约束，还是用纯代码的形式写界面，只要在代码里对父视图调个方法就可以对其本身和子视图，进行约束和字体大小等比例换算了。例如对某个viewcontroller上所有的view进行等比例换算的布局

```
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setup];
    [self.view adaptScreenWidthWithType:BSAdaptScreenWidthTypeAll exceptViews:nil];
}
```
另外我写了个小小的demo: https://github.com/LvBisheng/TestScaleWithScreen。 我只是提供了一个思路，大家可以根据需要自行对分类进行更改。

PS: 由于现在笔者用的是Swift开发，写了个Swift Demo，并支持cocopod导入（[https://github.com/LvBisheng/BSAdaptScreen-swift](https://github.com/LvBisheng/BSAdaptScreen-swift)
）。

##总结
&emsp; &emsp;这个问题其实之前困扰我蛮久的，每次想解决，可搜了下网上相关的资料和讨论很少。有时觉得是不是这个等比例换算的需求，本身就需要再斟酌斟酌?还是说大家都有更好更方便的解决方案了......
