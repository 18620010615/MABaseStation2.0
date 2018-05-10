//
//  GPSNaviViewController.m
//  AMapNaviKit
//
//  Created by liubo on 7/29/16.
//  Copyright © 2016 AutoNavi. All rights reserved.
//

#import "GPSNaviViewController.h"
#import "RoutePlanDriveViewController.h"
#import "MoreMenuView.h"

@interface GPSNaviViewController ()< AMapNaviDriveViewDelegate, MoreMenuViewDelegate>

@property (nonatomic, strong) MoreMenuView *moreMenu;

@end

@implementation GPSNaviViewController

#pragma mark - Life Cycle

- (instancetype)init
{
    if (self = [super init])
    {
        [self initDriveView];//初始化驾车导航视图
        
        [self initWalkView];//初始化步行导航视图
        
        [self initMoreMenu];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //flag值为0、1、2、3 风别对应加载驾车、公交、骑行、步行导航视图
    if(RoutePlanDriveViewController.flag == 0){
        
        [self.driveView setFrame:self.view.bounds];
        [self.view addSubview:self.driveView];
        
    }else if(RoutePlanDriveViewController.flag == 3){
        
        [self.walkView setFrame:self.view.bounds];
        [self.view addSubview:self.walkView];
        
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.toolbarHidden = YES;
}


- (void)viewWillLayoutSubviews
{
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0)
    {
        interfaceOrientation = self.interfaceOrientation;
    }
    
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation))
    {
        [self.driveView setIsLandscape:NO];
    }
    else if (UIInterfaceOrientationIsLandscape(interfaceOrientation))
    {
        [self.driveView setIsLandscape:YES];
    }
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

/**
 *
 *初始化驾车导航视图
 */
- (void)initDriveView
{
    if (self.driveView == nil)
    {
        self.driveView = [[AMapNaviDriveView alloc] init];
        self.driveView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self.driveView setDelegate:self];
    }
}

/**
 *
 *初始化步行导航视图
 */
- (void)initWalkView
{
    if (self.walkView == nil)
    {
        self.walkView = [[AMapNaviWalkView alloc] init];
        self.walkView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self.walkView setDelegate:self];
    }
}

/**
 *
 *初始化菜单视图
 */

- (void)initMoreMenu
{
    if (self.moreMenu == nil)
    {
        self.moreMenu = [[MoreMenuView alloc] init];
        self.moreMenu.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        
        [self.moreMenu setDelegate:self];
    }
}



#pragma mark - DriveView Delegate

- (void)driveViewCloseButtonClicked:(AMapNaviDriveView *)driveView
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(driveNaviViewCloseButtonClicked)])
    {
        [self.delegate driveNaviViewCloseButtonClicked];
    }
}

- (void)driveViewMoreButtonClicked:(AMapNaviDriveView *)driveView
{
    //配置MoreMenu状态
    [self.moreMenu setTrackingMode:self.driveView.trackingMode];
    [self.moreMenu setShowNightType:self.driveView.showStandardNightType];
    
    [self.moreMenu setFrame:self.view.bounds];
    [self.view addSubview:self.moreMenu];
}

- (void)driveViewTrunIndicatorViewTapped:(AMapNaviDriveView *)driveView
{
    if (self.driveView.showMode == AMapNaviDriveViewShowModeCarPositionLocked)
    {
        [self.driveView setShowMode:AMapNaviDriveViewShowModeNormal];
    }
    else if (self.driveView.showMode == AMapNaviDriveViewShowModeNormal)
    {
        [self.driveView setShowMode:AMapNaviDriveViewShowModeOverview];
    }
    else if (self.driveView.showMode == AMapNaviDriveViewShowModeOverview)
    {
        [self.driveView setShowMode:AMapNaviDriveViewShowModeCarPositionLocked];
    }
}

- (void)driveView:(AMapNaviDriveView *)driveView didChangeShowMode:(AMapNaviDriveViewShowMode)showMode
{
    NSLog(@"didChangeShowMode:%ld", (long)showMode);
}


#pragma mark - DriveView Delegate

- (void)walkViewCloseButtonClicked:(AMapNaviWalkView *)walkView
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(walkNaviViewCloseButtonClicked)])
    {
        [self.delegate walkNaviViewCloseButtonClicked];
    }
}

- (void)walkViewMoreButtonClicked:(AMapNaviWalkView *)walkView
{
    //配置MoreMenu状态
    [self.moreMenu setTrackingMode:self.walkView.trackingMode];
    [self.moreMenu setShowNightType:self.walkView.showStandardNightType];
    
    [self.moreMenu setFrame:self.view.bounds];
    [self.view addSubview:self.moreMenu];
}

- (void)walkViewTrunIndicatorViewTapped:(AMapNaviWalkView *)walkView
{
    if (self.walkView.showMode == AMapNaviWalkViewShowModeCarPositionLocked)
    {
        [self.walkView setShowMode:AMapNaviWalkViewShowModeNormal];
    }
    else if (self.walkView.showMode == AMapNaviWalkViewShowModeNormal)
    {
        [self.walkView setShowMode:AMapNaviWalkViewShowModeOverview];
    }
    else if (self.walkView.showMode == AMapNaviWalkViewShowModeOverview)
    {
        [self.walkView setShowMode:AMapNaviWalkViewShowModeCarPositionLocked];
    }
}

- (void)walkView:(AMapNaviWalkView *)driveView didChangeShowMode:(AMapNaviWalkViewShowMode)showMode
{
    NSLog(@"didChangeShowMode:%ld", (long)showMode);
}

#pragma mark - MoreMenu Delegate

- (void)moreMenuViewFinishButtonClicked
{
    [self.moreMenu removeFromSuperview];
}

- (void)moreMenuViewNightTypeChangeTo:(BOOL)isShowNightType
{
    [self.driveView setShowStandardNightType:isShowNightType];
}

- (void)moreMenuViewTrackingModeChangeTo:(AMapNaviViewTrackingMode)trackingMode
{
    [self.driveView setTrackingMode:trackingMode];
}

@end

