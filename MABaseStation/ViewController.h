//
//  ViewController.h
//  MABaseStation
//
//  Created by loop on 2018/4/26.
//  Copyright © 2018年 loop. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
+ (UIImage *)imageWithColor:(UIColor *)color;

//将出发点坐标传到路径规划
+ (void)setDeparturePosition:(CLLocationCoordinate2D ) startCoordinate;
+ (CLLocationCoordinate2D ) departurePosition;
//将目的基站坐标传到路径规划
+ (void)setDestinationPosition:(CLLocationCoordinate2D ) endCoordinate;
+ (CLLocationCoordinate2D ) destinationPosition;

@end

