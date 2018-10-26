//
//  ViewController.m
//  TestScaleWithScreen
//
//  Created by lbs on 2018/10/26.
//  Copyright © 2018 lbs. All rights reserved.
//

#import "ViewController.h"
#import "UIView+AdaptScreen.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view adaptScreenWidthWithType:AdaptScreenWidthTypeAll exceptViews:nil];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSLog(@"\n当前屏幕：%@",NSStringFromCGRect([UIApplication sharedApplication].keyWindow.bounds));
    NSLog(@"\nlabel size:%@ fontSize=%lf",NSStringFromCGSize(self.label.frame.size), self.label.font.pointSize);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
