//
//  XLViewController.m
//  XL_PageContainerController
//
//  Created by X-Liang on 2016/11/15.
//  Copyright © 2016年 X-Liang. All rights reserved.
//

#import "XLViewController.h"
#import "XLPageContainerController.h"

@interface XLViewController ()<XLPageContainerControllerDataSource>
@property (nonatomic, strong) XLPageContainerController *pageContaienrController;
@property (nonatomic, copy) NSArray *colors;
@end

@implementation XLViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.pageContaienrController = [[XLPageContainerController alloc] init];
    self.pageContaienrController.dataSource = self;
    [self.pageContaienrController addToParentViewController:self];
    [self.pageContaienrController registerViewController:[UIViewController class] forIdentifier:@"id"];
    _colors = @[
                        [UIColor whiteColor],
                        [UIColor redColor],
                        [UIColor blueColor],
                        [UIColor orangeColor],
                        [UIColor greenColor],
                        [UIColor grayColor],
                        [UIColor purpleColor],
                        [UIColor cyanColor],
                        [UIColor magentaColor],
                        [UIColor darkGrayColor]
                        ];
}

- (NSInteger)numberOfControllerInPageContainerViewController {
    return _colors.count;
}

- (UIViewController *)pageContainerViewController:(XLPageContainerController *)pageContainerController
                                          atIndex:(NSInteger)index {
    UIViewController *viewController = [pageContainerController dequeueReuseViewControllerWithIdentifier:@"id"];
    viewController.reuseIdentifier = @"id";
    viewController.view.backgroundColor = _colors[index];
    return viewController;
}


@end
