//
//  XL_PageContainerController.h
//  XL_PageContainerController
//
//  Created by X-Liang on 2016/11/15.
//  Copyright © 2016年 X-Liang. All rights reserved.
//

#import <UIKit/UIKit.h>
@interface UIViewController (ReuseExtension)
@property (nonatomic, copy) NSString *reuseIdentifier;
@end

@class XLPageContainerController;
@protocol XLPageContainerControllerDataSource <NSObject>

- (NSInteger)numberOfControllerInPageContainerViewController;

- (UIViewController*)pageContainerViewController:(XLPageContainerController *)pageContainerController
                                          atIndex:(NSInteger)index;

@end

@interface XLPageContainerController : UIViewController

@property (nonatomic, weak) id<XLPageContainerControllerDataSource> dataSource;

- (void)addToParentViewController:(UIViewController *)viewController;

- (void)registerViewController:(Class)viewController forIdentifier:(NSString *)identifier;

- (UIViewController *)dequeueReuseViewControllerWithIdentifier:(NSString *)reuseIdentifier;

@end


