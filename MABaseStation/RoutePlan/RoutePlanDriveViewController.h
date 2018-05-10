//
//  RoutePlanDriveViewController.h
//  MAMapKit_3D_Demo
//
//  Created by shaobin on 16/8/12.
//  Copyright © 2016年 Autonavi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RoutePlanDriveViewController : UIViewController

@property (nonatomic, strong) MAMapView *mapView;
@property (nonatomic, strong) AMapNaviWalkManager *walkManager;


+ (void)setflag:(int)num;
+ (int)flag;

@end
