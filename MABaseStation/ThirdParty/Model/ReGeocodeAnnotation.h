//
//  ReGeocodeAnnotation.h
//  SearchV3Demo
//  反地理编码 坐标转地址
//  Created by songjian on 13-8-26.
//  Copyright (c) 2013年 songjian. All rights reserved.
//

#import <MAMapKit/MAMapKit.h>
#import <AMapSearchKit/AMapCommonObj.h>

@interface ReGeocodeAnnotation : NSObject <MAAnnotation>

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate reGeocode:(AMapReGeocode *)reGeocode;

@property (nonatomic, readonly, strong) AMapReGeocode *reGeocode;

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;


- (void)setAMapReGeocode:(AMapReGeocode *)reGerocode;

@end
