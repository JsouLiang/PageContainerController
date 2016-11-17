//
//  XL_PageContainerController.m
//  XL_PageContainerController
//
//  Created by X-Liang on 2016/11/15.
//  Copyright © 2016年 X-Liang. All rights reserved.
//

#import "XLPageContainerController.h"
#import <objc/runtime.h>
#define VisibleCount 3
@interface XLPageContainerController ()<UIScrollViewDelegate>

/**ContainerView职责*/
@property (nonatomic, weak) UIScrollView *containerView;

/**控制器缓存Pool, 控制器从界面上移除会放到这个缓存池中*/
@property (nonatomic, strong) NSMutableDictionary *viewControllerCachePool;
/**注册的ViewController信息会放到该控制器中*/
@property (nonatomic, strong) NSMutableDictionary *registerViewControllerInfo;
/**子控制器个数*/
@property (nonatomic, assign) NSInteger countOfControllers;
/**当前第几个控制器*/
@property (nonatomic, assign) NSInteger currentControllerIndex;
/** 可见控制器的范围 */
@property (nonatomic, assign) NSRange visibleRange;

@property (nonatomic, strong) NSMutableDictionary *visibleControllerInfo;

@property (nonatomic, strong) NSMutableArray *visibleControllers;

@end

NS_INLINE CGRect visibleRectWithOffset(CGFloat offset, CGFloat width, CGFloat height, CGFloat maxLength) {
    CGFloat originalX = offset - width;
    originalX = originalX > 0 ? originalX : 0;
    CGFloat rectWidth = VisibleCount * width;
    rectWidth = originalX + rectWidth <= maxLength ? : originalX + (maxLength - offset);
    return CGRectMake(originalX, 0, rectWidth, height);
}

NS_INLINE NSRange visibleRangeWithOffset(CGFloat offset, CGFloat width, NSInteger maxIndex) {
    NSInteger startIndex = floor(offset / width) - 1;
    startIndex = startIndex >= 0 ? startIndex : 0;
    
    NSInteger len = VisibleCount;
    len = startIndex + len < maxIndex ? len : maxIndex - startIndex;
    return NSMakeRange(startIndex, len);
}

@implementation XLPageContainerController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureScrollView];
    [self initialProperties];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self configureContentView];
}

#pragma mark - Private Method
#pragma mark - UI Configure Method
- (void)configureScrollView {
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scrollView.showsVerticalScrollIndicator = scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.pagingEnabled = YES;
    scrollView.delegate = self;
    [self.view addSubview:scrollView];
    _containerView = scrollView;
}

- (void)configureContentView {
    if (CGSizeEqualToSize(_containerView.bounds.size, self.view.bounds.size)) {
        return;
    }
    _countOfControllers = [_dataSource numberOfControllerInPageContainerViewController];
#warning 顶部有标签栏的时候还没有处理
    _containerView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds));
    _containerView.contentSize = CGSizeMake(_countOfControllers * CGRectGetWidth(_containerView.bounds), 0);
    _containerView.contentOffset = CGPointMake(_currentControllerIndex * CGRectGetWidth(_containerView.bounds), 0);
    [self layoutContentView];
}

- (void)layoutContentView {
    CGFloat offsetX = _containerView.contentOffset.x;
    NSRange visibleControllerRange = visibleRangeWithOffset(offsetX, CGRectGetWidth(_containerView.bounds), _countOfControllers);
    [self addControllerInVisibleRange:visibleControllerRange];
}

- (void)addControllerInVisibleRange:(NSRange)visibleRange {
    CGFloat containerViewWidth = CGRectGetWidth(self.containerView.bounds);
    CGFloat containerViewHeight = CGRectGetHeight(self.containerView.bounds);
    for (NSInteger index = visibleRange.location; index < visibleRange.location + visibleRange.length; index++) {
        NSString *indexKey = [NSString stringWithFormat:@"%zd",index];
        if (_registerViewControllerInfo[indexKey] &&
            [_registerViewControllerInfo[indexKey] isKindOfClass:[UIViewController class]]) {
            continue;
        }
        UIViewController *viewController = [_dataSource pageContainerViewController:self atIndex:index];
        _registerViewControllerInfo[indexKey] = viewController;
        viewController.view.frame = CGRectMake(index * containerViewWidth, 0, containerViewWidth , containerViewHeight);
        [self addSubViewController:viewController];
    }
}

- (void)addSubViewController:(UIViewController *)childViewController {
    [self addChildViewController:childViewController];
    childViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth| UIViewAutoresizingFlexibleHeight;
    [self.containerView addSubview:childViewController.view];
    [childViewController didMoveToParentViewController:self];
}

#pragma mark - Logic Configure Method
- (void)initialProperties {
    _viewControllerCachePool = [NSMutableDictionary dictionary];
    _registerViewControllerInfo = [NSMutableDictionary dictionary];
    _currentControllerIndex = 0;
    _visibleControllers = [NSMutableArray arrayWithCapacity:_countOfControllers];
}


#pragma mark - Public Method

- (UIViewController *)dequeueReuseViewControllerWithIdentifier:(NSString *)reuseIdentifier {
    UIViewController *viewController;
    if (_viewControllerCachePool[reuseIdentifier] && [_viewControllerCachePool[reuseIdentifier] count] > 0) {
        viewController = [_viewControllerCachePool[reuseIdentifier] firstObject];
    } else {
        Class viewControllerClass = _registerViewControllerInfo[reuseIdentifier];
        viewController = [[viewControllerClass alloc] init];
    }
    return viewController;
}

- (void)registerViewController:(Class)viewController forIdentifier:(NSString *)identifier {
    _registerViewControllerInfo[identifier] = viewController;
}

- (void)addToParentViewController:(UIViewController *)viewController {
    [viewController addChildViewController:self];
    self.view.bounds = viewController.view.bounds;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [viewController.view addSubview:self.view];
    [self didMoveToParentViewController:viewController];
}

#pragma mark - Delegate
#pragma mark - ScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self layoutContentView];
    
    CGRect visibleRect = visibleRectWithOffset(scrollView.contentOffset.x,
                                               CGRectGetWidth(scrollView.bounds),
                                               CGRectGetHeight(scrollView.bounds),
                                               _countOfControllers * CGRectGetWidth(scrollView.bounds));
    
    NSMutableDictionary *tempDic = [_visibleControllerInfo mutableCopy];
    [tempDic enumerateKeysAndObjectsUsingBlock:^(NSString *indexKey, UIViewController *viewController, BOOL * _Nonnull stop) {
        if (!CGRectIntersectsRect(viewController.view.frame, visibleRect)) {
            [_visibleControllerInfo removeObjectForKey:indexKey];
            NSMutableArray *caches = _viewControllerCachePool[viewController.reuseIdentifier];
            if (!caches) {
                caches = [NSMutableArray array];
            }
            [caches addObject:viewController];
        }
    }];
}
@end

@implementation UIViewController (ReuseExtension)

- (void)setReuseIdentifier:(NSString *)reuseIdentifier {
    objc_setAssociatedObject(self, _cmd, reuseIdentifier, OBJC_ASSOCIATION_COPY);
}

- (NSString *)reuseIdentifier {
    return objc_getAssociatedObject(self, @selector(setReuseIdentifier:));
}

@end

