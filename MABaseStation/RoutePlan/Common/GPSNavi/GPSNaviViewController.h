//
//  GPSNaviViewController.h
//  AMapNaviKit
//
//  Created by liubo on 7/29/16.
//  Copyright © 2016 AutoNavi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AMapNaviKit/AMapNaviKit.h>

@protocol GPSNaviViewControllerDelegate;

@interface GPSNaviViewController : UIViewController

@property (nonatomic, weak) id <GPSNaviViewControllerDelegate> delegate;
@property (nonatomic, strong) AMapNaviDriveView *driveView;
@property (nonatomic, strong) AMapNaviWalkView *walkView;

@end
@protocol GPSNaviViewControllerDelegate <NSObject>

//退出驾车步行导航按钮方法
- (void)driveNaviViewCloseButtonClicked;
- (void)walkNaviViewCloseButtonClicked;

@end
