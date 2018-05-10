#import "RoutePlanDriveViewController.h"

#import "SpeechSynthesizer.h"
#import "NaviPointAnnotation.h"
#import "SelectableTrafficOverlay.h"
#import "GPSNaviViewController.h"
#import "SelectableOverlay.h"
#import "PreferenceView.h"
#import "BottomInfoView.h"
#import "ViewController.h"

#define kRoutePlanInfoViewHeight    75.f
#define kBottomInfoViewHeight       170.f
#define MAS_SHORTHAND
// 定义这个常量，就可以让Masonry帮我们自动把基础数据类型的数据，自动装箱为对象类型。
#define MAS_SHORTHAND_GLOBALS

@interface RoutePlanDriveViewController ()<MAMapViewDelegate, AMapNaviDriveManagerDelegate,AMapNaviWalkManagerDelegate, GPSNaviViewControllerDelegate,BottomInfoViewDelegate>

//起点终点坐标
@property (nonatomic, strong) AMapNaviPoint *startPoint;
@property (nonatomic, strong) AMapNaviPoint *endPoint;

//地图顶部，底部视图
@property (nonatomic, strong) PreferenceView *preferenceView;
@property (nonatomic, strong) BottomInfoView *bottomInfoView;

@property (nonatomic, assign) BOOL needRoutePlan;
@property (nonatomic, assign) BOOL isMultipleRoutePlan;

//出行类型按钮 驾车、公交、骑行、步行
@property (nonatomic,strong) UIButton *driveBtn;
@property (nonatomic,strong) UIButton *busBtn;
@property (nonatomic,strong) UIButton *rideBtn;
@property (nonatomic,strong) UIButton *walkBtn;

@property (nonatomic,assign) int flag;
@end

@implementation RoutePlanDriveViewController

static int flag;
+ (void)setflag:(int)num{
    
    flag = num;
    NSLog(@"dddd %d ",flag);
}
 
+ (int )flag{
    return flag;
}


#pragma mark - Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self setTitle:@"路线规划"];
    
    [self initProperties];//属性初始化(设置起点、终点坐标)
    
    [self initMapView];//初始化地图
    
    [self initDriveManager];//初始化驾车管理类
    
    [self initWalkManager];//初始化步行管理类
    
    [self configSubViews];//初始化视图配置
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self reloadInputViews];
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.toolbarHidden = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self initAnnotations];
    
    //第一次进入后默认进行驾车路径规划
    if (self.needRoutePlan)
    {
        [self driveRoute:nil];
    }
}


- (void)dealloc
{
    [[AMapNaviDriveManager sharedInstance] stopNavi];
    [[AMapNaviDriveManager sharedInstance] setDelegate:nil];
    
    BOOL success = [AMapNaviDriveManager destroyInstance];
    NSLog(@"单例是否销毁成功 : %d",success);
}


#pragma mark - Initalization

/**
 *
 *属性初始化(设置路线的起点、终点坐标)
 */
- (void)initProperties
{
    self.startPoint = [AMapNaviPoint locationWithLatitude:ViewController.departurePosition.latitude longitude:ViewController.departurePosition.longitude];
    self.endPoint   = [AMapNaviPoint locationWithLatitude:ViewController.destinationPosition.latitude longitude:ViewController.destinationPosition.longitude];
    self.needRoutePlan = YES;
}

/**
 *
 *地图初始化(加载地图、设置地图代理)
 */
- (void)initMapView
{
    if (self.mapView == nil)
    {
        self.mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, kRoutePlanInfoViewHeight,
                                                                   self.view.bounds.size.width,
                                                                   self.view.bounds.size.height - kRoutePlanInfoViewHeight - kBottomInfoViewHeight)];
        [self.mapView setDelegate:self];
        [self.view addSubview:self.mapView];
    }
}

/**
 *
 *驾车导航初始化
 */
- (void)initDriveManager
{
     //请在 dealloc 函数中执行 [AMapNaviDriveManager destroyInstance] 来销毁单例
    [[AMapNaviDriveManager sharedInstance] setDelegate:self];
    [[AMapNaviDriveManager sharedInstance]  setAllowsBackgroundLocationUpdates:YES];
    [[AMapNaviDriveManager sharedInstance]  setPausesLocationUpdatesAutomatically:NO];
}

/**
 *
 *步行导航初始化
 */
- (void)initWalkManager
{
    if (self.walkManager == nil)
    {
        self.walkManager = [[AMapNaviWalkManager alloc] init];
        [self.walkManager setDelegate:self];
    }
}

/**
 *
 *标记初始化(起终点标记)
 */
- (void)initAnnotations
{
    NaviPointAnnotation *beginAnnotation = [[NaviPointAnnotation alloc] init];
    [beginAnnotation setCoordinate:CLLocationCoordinate2DMake(self.startPoint.latitude, self.startPoint.longitude)];
    beginAnnotation.title = @"起始点";
    beginAnnotation.navPointType = NaviPointAnnotationStart;
    [self.mapView addAnnotation:beginAnnotation];
    
    NaviPointAnnotation *endAnnotation = [[NaviPointAnnotation alloc] init];
    [endAnnotation setCoordinate:CLLocationCoordinate2DMake(self.endPoint.latitude, self.endPoint.longitude)];
    endAnnotation.title = @"终点";
    endAnnotation.navPointType = NaviPointAnnotationEnd;
    [self.mapView addAnnotation:endAnnotation];
}



#pragma mark - Button Action

/**
 *按钮方法
 *点击驾车按钮，规划驾车路线
 */
- (void)driveRoute:(UIButton *)sender{
    
    NSLog(@"点击了驾车按钮");
    _flag =0;
    
    [_driveBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_driveBtn setBackgroundColor:[UIColor colorWithRed:88.0/255.0 green:160.0/255.0 blue:240.0/255.0 alpha:1.0]];
    
    [_busBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_busBtn setBackgroundColor:[UIColor whiteColor]];
    
    [_rideBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_rideBtn setBackgroundColor:[UIColor whiteColor]];
    
    [_walkBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_walkBtn setBackgroundColor:[UIColor whiteColor]];
    
    //进行驾车多路径规划
    self.isMultipleRoutePlan = YES;
    
    [[AMapNaviDriveManager sharedInstance]  calculateDriveRouteWithStartPoints:@[self.startPoint]
                                                                     endPoints:@[self.endPoint]
                                                                     wayPoints:nil
                                                               drivingStrategy:[self.preferenceView strategyWithIsMultiple:self.isMultipleRoutePlan]];
    flag = _flag;
}

/**
 *按钮方法
 *点击公交按钮，规划公交路线
 */
- (void)busRoute:(UIButton *)sender{
    NSLog(@"点击了公交按钮");
    _flag = 1;
    
    [_busBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_busBtn setBackgroundColor:[UIColor colorWithRed:88.0/255.0 green:160.0/255.0 blue:240.0/255.0 alpha:1.0]];
    
    [_driveBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_driveBtn setBackgroundColor:[UIColor whiteColor]];
    
    [_rideBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_rideBtn setBackgroundColor:[UIColor whiteColor]];
    
    [_walkBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_walkBtn setBackgroundColor:[UIColor whiteColor]];
    
    //进行公交路径规划
   
    
    flag = _flag;
}

/**
 *按钮方法
 *点击骑行按钮，规划骑行路线
 */
- (void)rideRoute:(UIButton *)sender{
    NSLog(@"点击了骑行按钮");
    _flag = 2;
    
    [_rideBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_rideBtn setBackgroundColor:[UIColor colorWithRed:88.0/255.0 green:160.0/255.0 blue:240.0/255.0 alpha:1.0]];
    
    [_driveBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_driveBtn setBackgroundColor:[UIColor whiteColor]];
    
    [_busBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_busBtn setBackgroundColor:[UIColor whiteColor]];
    
    [_walkBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_walkBtn setBackgroundColor:[UIColor whiteColor]];
    //进行骑行路径规划

    
    flag = _flag;
}

/**
 *按钮方法
 *点击步行按钮，规划步行路线
 */
- (void)walkRoute:(UIButton *)sender
{
    NSLog(@"点击了步行按钮");
    _flag = 3;
    
    [_walkBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_walkBtn setBackgroundColor:[UIColor colorWithRed:88.0/255.0 green:160.0/255.0 blue:240.0/255.0 alpha:1.0]];
    
    [_driveBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_driveBtn setBackgroundColor:[UIColor whiteColor]];
    
    [_busBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_busBtn setBackgroundColor:[UIColor whiteColor]];
    
    [_rideBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_rideBtn setBackgroundColor:[UIColor whiteColor]];
    
    //进行步行路径规划
    [self.walkManager calculateWalkRouteWithStartPoints:@[self.startPoint]
                                              endPoints:@[self.endPoint]];

    flag = _flag;
}




#pragma mark - Handle Navi Routes

- (void)showNaviRoutes
{
    if(_flag == 0)
    {
        //驾车路线显示
        if ([[AMapNaviDriveManager sharedInstance].naviRoutes count] <= 0)
        {
            return;
        }
        
        [self.mapView removeOverlays:self.mapView.overlays];
        NSMutableArray *allInfoModels = [[NSMutableArray alloc] init];
        NSDictionary *allTags = [self createRotueTagString];
        
        //将路径显示到地图上
        for (NSNumber *aRouteID in [[AMapNaviDriveManager sharedInstance].naviRoutes allKeys])
        {
            AMapNaviRoute *aRoute = [[[AMapNaviDriveManager sharedInstance]  naviRoutes] objectForKey:aRouteID];
            
            //添加带实时路况的Polyline
            [self addRoutePolylineWithRouteID:[aRouteID integerValue]];
            
            //创建RouteInfoViewModel
            RouteInfoViewModel *aInfoModel = [[RouteInfoViewModel alloc] init];
            [aInfoModel setRouteID:[aRouteID intValue]];
            [aInfoModel setRouteTag:[allTags objectForKey:aRouteID]];
            [aInfoModel setRouteTime:aRoute.routeTime];
            [aInfoModel setRouteLength:aRoute.routeLength];
            [aInfoModel setTrafficLightCount:aRoute.routeTrafficLightCount];
            [allInfoModels addObject:aInfoModel];
        }
        
        [self.bottomInfoView setAllRouteInfo:allInfoModels];
        
        //默认选择第一条路线
        NSInteger selectedRouteID = [[allInfoModels firstObject] routeID];
        [self selectNaviRouteWithID:selectedRouteID];
        [self.bottomInfoView selecteNaviRouteWithRouteID:selectedRouteID];
        
    }else if(_flag == 3){
        if (self.walkManager.naviRoute == nil)
        {
            return;
        }
        
        NSLog(@"flag %d",_flag);
        [self.mapView removeOverlays:self.mapView.overlays];
        
        NSMutableArray *allInfoModels = [[NSMutableArray alloc] init];
        NSDictionary *allTags = [self createRotueTagString];
        
        //将路径显示到地图上
        NSNumber *aRouteID;

        AMapNaviRoute *aRoute = self.walkManager.naviRoute;
        int count = (int)[[aRoute routeCoordinates] count];//导航路线的所有形状点routeCoordinates
        //添加路径Polyline
        CLLocationCoordinate2D *coords = (CLLocationCoordinate2D *)malloc(count * sizeof(CLLocationCoordinate2D));
        for (int i = 0; i < count; i++)
        {
            AMapNaviPoint *coordinate = [[aRoute routeCoordinates] objectAtIndex:i];//坐标点用来绘制折线（路线）的
            coords[i].latitude = [coordinate latitude];
            coords[i].longitude = [coordinate longitude];
        }
        
        //构造折线对象
        MAPolyline *polyline = [MAPolyline polylineWithCoordinates:coords count:count];
        NSLog(@"-----------%f------%f-----",coords[2].longitude,coords[2].latitude);
//        SelectableOverlay *selectablePolyline = [[SelectableOverlay alloc] initWithOverlay:polyline];
        
        //在地图上添加折线对象
        [self.mapView addOverlay:polyline];
        free(coords);
        [self.mapView showAnnotations:self.mapView.annotations animated:NO];
            
        //创建RouteInfoViewModel
        RouteInfoViewModel *aInfoModel = [[RouteInfoViewModel alloc] init];
        [aInfoModel setRouteID:[aRouteID intValue]];
        [aInfoModel setRouteTag:[allTags objectForKey:aRouteID]];
        [aInfoModel setRouteTime:aRoute.routeTime];
        [aInfoModel setRouteLength:aRoute.routeLength];
        [aInfoModel setTrafficLightCount:aRoute.routeTrafficLightCount];
        [allInfoModels addObject:aInfoModel];

        [self.bottomInfoView setAllRouteInfo:allInfoModels];
    }
}

/**
 *
 *导航路径选择
 */
- (void)selectNaviRouteWithID:(NSInteger)routeID
{
    //在开始导航前进行路径选择
    if ([[AMapNaviDriveManager sharedInstance]  selectNaviRouteWithRouteID:routeID])
    {
        [self selecteOverlayWithRouteID:routeID];
    }
    else
    {
        NSLog(@"路径选择失败!");
    }
    
}

/**
 *
 *添加覆盖物
 */
- (void)selecteOverlayWithRouteID:(NSInteger)routeID
{
    [self.mapView.overlays enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id<MAOverlay> overlay, NSUInteger idx, BOOL *stop)
     {
         if ([overlay isKindOfClass:[SelectableTrafficOverlay class]])
         {
             SelectableTrafficOverlay *selectableOverlay = overlay;
             
             /* 获取overlay对应的renderer. */
             MAPolylineRenderer *polylineRenderer = (MAPolylineRenderer *)[self.mapView rendererForOverlay:selectableOverlay];
             
             if ([polylineRenderer isKindOfClass:[MAMultiColoredPolylineRenderer class]])
             {
                 MAMultiColoredPolylineRenderer *overlayRenderer = (MAMultiColoredPolylineRenderer *)polylineRenderer;
                 
                 if (selectableOverlay.routeID == routeID)
                 {
                     /* 设置选中状态. */
                     selectableOverlay.selected = YES;
                     
                     /* 修改renderer选中颜色. */
                     NSMutableArray *strokeColors = [[NSMutableArray alloc] init];
                     for (UIColor *aColor in selectableOverlay.polylineStrokeColors)
                     {
                         [strokeColors addObject:[aColor colorWithAlphaComponent:1]];
                     }
                     selectableOverlay.polylineStrokeColors = strokeColors;
                     overlayRenderer.strokeColors = selectableOverlay.polylineStrokeColors;
                     
                     /* 修改overlay覆盖的顺序. */
                     [self.mapView exchangeOverlayAtIndex:idx withOverlayAtIndex:self.mapView.overlays.count - 1];
                     [self.mapView showOverlays:@[overlay] animated:YES];
                 }
                 else
                 {
                     /* 设置选中状态. */
                     selectableOverlay.selected = NO;
                     
                     /* 修改renderer选中颜色. */
                     NSMutableArray *strokeColors = [[NSMutableArray alloc] init];
                     for (UIColor *aColor in selectableOverlay.polylineStrokeColors)
                     {
                         [strokeColors addObject:[aColor colorWithAlphaComponent:0.25]];
                     }
                     selectableOverlay.polylineStrokeColors = strokeColors;
                     overlayRenderer.strokeColors = selectableOverlay.polylineStrokeColors;
                 }
             }
             else if ([polylineRenderer isKindOfClass:[MAMultiTexturePolylineRenderer class]])
             {
                 MAMultiTexturePolylineRenderer *overlayRenderer = (MAMultiTexturePolylineRenderer *)polylineRenderer;
                 
                 if (selectableOverlay.routeID == routeID)
                 {
                     /* 设置选中状态. */
                     selectableOverlay.selected = YES;
                     
                     /* 修改renderer选中颜色. */
                     overlayRenderer.strokeTextureImages = selectableOverlay.polylineTextureImages;
                     
                     /* 修改overlay覆盖的顺序. */
                     [self.mapView exchangeOverlayAtIndex:idx withOverlayAtIndex:self.mapView.overlays.count - 1];
                     [self.mapView showOverlays:@[overlay] animated:YES];
                 }
                 else
                 {
                     /* 设置选中状态. */
                     selectableOverlay.selected = NO;
                     
                     /* 修改renderer选中颜色. */
                     overlayRenderer.strokeTextureImages = @[[UIImage imageNamed:@"custtexture_light"]];
                 }
             }
             
             //             [polylineRenderer glRender];
         }
     }];
}

#pragma mark - Handle Navi Route Info

/**
 *
 *创建路线标签
 */
- (NSDictionary *)createRotueTagString
{
    NSArray <NSNumber *> *allRouteIDs = [[AMapNaviDriveManager sharedInstance].naviRoutes allKeys];
    AMapNaviDrivingStrategy strategy = [self.preferenceView strategyWithIsMultiple:YES];
    
    NSInteger minTime = NSIntegerMax;
    NSInteger minLength = NSIntegerMax;
    NSInteger minTrafficLightCount = NSIntegerMax;
    NSInteger minCost = NSIntegerMax;
    
    for (AMapNaviRoute *aRoute in [[AMapNaviDriveManager sharedInstance].naviRoutes allValues])
    {
        if (aRoute.routeTime < minTime) minTime = aRoute.routeTime;
        
        if (aRoute.routeLength < minLength) minLength = aRoute.routeLength;
        
        if (aRoute.routeTrafficLightCount < minTrafficLightCount) minTrafficLightCount = aRoute.routeTrafficLightCount;
        
        if (aRoute.routeTollCost < minCost) minCost = aRoute.routeTollCost;
    }
    
    NSMutableDictionary *resultDic = [[NSMutableDictionary alloc] init];
    for (int i = 0; i < allRouteIDs.count; i++)
    {
        NSNumber *aRouteID = [allRouteIDs objectAtIndex:i];
        AMapNaviRoute *aRoute = [[[AMapNaviDriveManager sharedInstance] naviRoutes] objectForKey:aRouteID];
        
        NSString *resultTag = [NSMutableString stringWithFormat:@"方案%d", i+1];
        if (aRoute.routeTrafficLightCount <= minTrafficLightCount)
        {
            resultTag = @"红绿灯少";
        }
        if (aRoute.routeTollCost <= minCost)
        {
            resultTag = @"收费较少";
        }
        if ((int)(aRoute.routeLength / 100) <= (int)(minLength / 100))
        {
            resultTag = @"距离最短";
        }
        if (aRoute.routeTime <= minTime)
        {
            resultTag = @"时间最短";
        }
        
        if (0 == i && AMapNaviDrivingStrategyMultipleAvoidCongestion == strategy)
        {
            resultTag = @"躲避拥堵";
        }
        if (0 == i && AMapNaviDrivingStrategyMultipleAvoidHighway == strategy)
        {
            resultTag = @"不走高速";
        }
        if (0 == i && AMapNaviDrivingStrategyMultipleAvoidCost == strategy)
        {
            resultTag = @"避免收费";
        }
        if (0 == i && [resultTag hasPrefix:@"方案"])
        {
            resultTag = @"推荐";
        }
        
        [resultDic setObject:resultTag forKey:aRouteID];
    }
    
    return resultDic;
}

/**
 *
 *计算两个坐标点间的距离
 */
- (double)calcDistanceBetweenPoint:(AMapNaviPoint *)pointA andPoint:(AMapNaviPoint *)pointB
{
    MAMapPoint mapPointA = MAMapPointForCoordinate(CLLocationCoordinate2DMake(pointA.latitude, pointA.longitude));
    MAMapPoint mapPointB = MAMapPointForCoordinate(CLLocationCoordinate2DMake(pointB.latitude, pointB.longitude));
    
    return MAMetersBetweenMapPoints(mapPointA, mapPointB);
}

/**
 *
 *计算两个坐标点在平面坐标系的位置
 */
- (AMapNaviPoint *)calcPointWithStartPoint:(AMapNaviPoint *)start endPoint:(AMapNaviPoint *)end rate:(double)rate
{
    if (rate > 1.0 || rate < 0)
    {
        return nil;
    }
    
    MAMapPoint from = MAMapPointForCoordinate(CLLocationCoordinate2DMake(start.latitude, start.longitude));
    MAMapPoint to = MAMapPointForCoordinate(CLLocationCoordinate2DMake(end.latitude, end.longitude));
    
    double latitudeDelta = (to.y - from.y) * rate;
    double longitudeDelta = (to.x - from.x) * rate;
    
    CLLocationCoordinate2D coordinate = MACoordinateForMapPoint(MAMapPointMake(from.x + longitudeDelta, from.y + latitudeDelta));
    
    return [AMapNaviPoint locationWithLatitude:coordinate.latitude longitude:coordinate.longitude];
}

/**
 *
 *根据路线的拥挤状态，添加不同颜色的图片
 */
- (UIImage *)defaultTextureImageForStatus:(AMapNaviRouteStatus)status
{
    NSString *imageName = nil;
    if (status == AMapNaviRouteStatusSmooth)            imageName = @"icusttexture_green";
    else if (status == AMapNaviRouteStatusSlow)         imageName = @"custtexture_slow";
    else if (status == AMapNaviRouteStatusJam)          imageName = @"custtexture_bad";
    else if (status == AMapNaviRouteStatusSeriousJam)   imageName = @"custtexture_serious";
    else imageName = @"custtexture_no";
    
    return [UIImage imageNamed:imageName];
}

/**
 *
 *根据路线的拥挤状态，添加不同颜色
 */
- (UIColor *)defaultColorForStatus:(AMapNaviRouteStatus)status
{
    switch (status) {
        case AMapNaviRouteStatusSmooth:     //1-通畅-green
            return [UIColor colorWithRed:65/255.0 green:223/255.0 blue:16/255.0 alpha:1];
        case AMapNaviRouteStatusSlow:       //2-缓行-yellow
            return [UIColor yellowColor];
        case AMapNaviRouteStatusJam:        //3-阻塞-red
            return [UIColor redColor];
        case AMapNaviRouteStatusSeriousJam: //4-严重阻塞-brown
            return [UIColor colorWithRed:160/255.0 green:8/255.0 blue:8/255.0 alpha:1];
        default:                            //0-未知状态-blue
            return [UIColor colorWithRed:26/255.0 green:166/255.0 blue:239/255.0 alpha:1];
    }
}

/**
 *
 *向路线中填充颜色或图片
 */
- (void)addRoutePolylineWithRouteID:(NSInteger)routeID
{
    //用不同颜色表示不同的路况
    //    [self addRoutePolylineUseStrokeColorsWithRouteID:routeID];
    
    //用不同纹理表示不同的路况
    [self addRoutePolylineUseTextureImageWithRouteID:routeID];
}

/**
 *
 *向路线中填充图片
 */
- (void)addRoutePolylineUseTextureImageWithRouteID:(NSInteger)routeID
{
    //必须选中路线后，才可以通过driveManager获取实时交通路况
    if (![[AMapNaviDriveManager sharedInstance]  selectNaviRouteWithRouteID:routeID])
    {
        return;
    }
    
    NSArray <AMapNaviPoint *> *oriCoordinateArray = [[AMapNaviDriveManager sharedInstance] .naviRoute.routeCoordinates copy];
    NSArray <AMapNaviTrafficStatus *> *trafficStatus = [[AMapNaviDriveManager sharedInstance]  getTrafficStatusesWithStartPosition:0 distance:(int)[AMapNaviDriveManager sharedInstance] .naviRoute.routeLength];
    
    NSMutableArray <AMapNaviPoint *> *resultCoords = [[NSMutableArray alloc] init];
    NSMutableArray <NSNumber *> *coordIndexes = [[NSMutableArray alloc] init];
    NSMutableArray <UIImage *> *textureImages = [[NSMutableArray alloc] init];
    [resultCoords addObject:[oriCoordinateArray objectAtIndex:0]];
    
    //依次计算每个路况的长度对应的polyline点的index
    unsigned int i = 1;
    NSInteger sumLength = 0;
    NSInteger statusesIndex = 0;
    NSInteger curTrafficLength = [[trafficStatus firstObject] length];
    
    for ( ; i < [oriCoordinateArray count]; i++)
    {
        double segDis = [self calcDistanceBetweenPoint:[oriCoordinateArray objectAtIndex:i-1]
                                              andPoint:[oriCoordinateArray objectAtIndex:i]];
        
        //两点间插入路况改变的点
        if (sumLength + segDis >= curTrafficLength)
        {
            if (sumLength + segDis == curTrafficLength)
            {
                [resultCoords addObject:[oriCoordinateArray objectAtIndex:i]];
                [coordIndexes addObject:[NSNumber numberWithInteger:((int)[resultCoords count]-1)]];
            }
            else
            {
                double rate = (segDis==0 ? 0 : ((curTrafficLength - sumLength) / segDis));
                AMapNaviPoint *extrnPoint = [self calcPointWithStartPoint:[oriCoordinateArray objectAtIndex:i-1]
                                                                 endPoint:[oriCoordinateArray objectAtIndex:i]
                                                                     rate:MAX(MIN(rate, 1.0), 0)];
                if (extrnPoint)
                {
                    [resultCoords addObject:extrnPoint];
                    [coordIndexes addObject:[NSNumber numberWithInteger:((int)[resultCoords count]-1)]];
                    [resultCoords addObject:[oriCoordinateArray objectAtIndex:i]];
                }
                else
                {
                    [resultCoords addObject:[oriCoordinateArray objectAtIndex:i]];
                    [coordIndexes addObject:[NSNumber numberWithInteger:((int)[resultCoords count]-1)]];
                }
            }
            
            //添加对应的strokeColors
           [textureImages addObject:[self defaultTextureImageForStatus:[[trafficStatus objectAtIndex:statusesIndex] status]]];
            
            sumLength = sumLength + segDis - curTrafficLength;
            
            if (++statusesIndex >= [trafficStatus count])
            {
                break;
            }
            curTrafficLength = [[trafficStatus objectAtIndex:statusesIndex] length];
        }
        else
        {
            [resultCoords addObject:[oriCoordinateArray objectAtIndex:i]];
            
            sumLength += segDis;
        }
    }
    
    //将最后一个点对齐到路径终点
    if (i < [oriCoordinateArray count])
    {
        while (i < [oriCoordinateArray count])
        {
            [resultCoords addObject:[oriCoordinateArray objectAtIndex:i]];
            i++;
        }
        
        [coordIndexes removeLastObject];
        [coordIndexes addObject:[NSNumber numberWithInteger:((int)[resultCoords count]-1)]];
    }
    else
    {
        while (((int)[coordIndexes count])-1 >= (int)[trafficStatus count])
        {
            [coordIndexes removeLastObject];
            [textureImages removeLastObject];
        }
        
        [coordIndexes addObject:[NSNumber numberWithInteger:((int)[resultCoords count]-1)]];
        //需要修改textureImages的最后一个与trafficStatus最后一个一致
        [textureImages addObject:[self defaultTextureImageForStatus:[[trafficStatus lastObject] status]]];
    }
    
    //添加Polyline
    NSInteger coordCount = [resultCoords count];
    CLLocationCoordinate2D *coordinates = (CLLocationCoordinate2D *)malloc(coordCount * sizeof(CLLocationCoordinate2D));
    for (int k = 0; k < coordCount; k++)
    {
        AMapNaviPoint *aCoordinate = [resultCoords objectAtIndex:k];
        coordinates[k] = CLLocationCoordinate2DMake(aCoordinate.latitude, aCoordinate.longitude);
    }
    
    //创建SelectableTrafficOverlay
    SelectableTrafficOverlay *polyline = [SelectableTrafficOverlay polylineWithCoordinates:coordinates count:coordCount drawStyleIndexes:coordIndexes];
    polyline.routeID = routeID;
    polyline.selected = NO;
    polyline.polylineWidth = 30;
    polyline.polylineTextureImages = textureImages;
    
    if (coordinates != NULL)
    {
        free(coordinates);
    }
    
    [self.mapView addOverlay:polyline level:MAOverlayLevelAboveLabels];
}


/**
 *
 *向路线中填充颜色
 */
- (void)addRoutePolylineUseStrokeColorsWithRouteID:(NSInteger)routeID
{
    //必须选中路线后，才可以通过driveManager获取实时交通路况
    if (![[AMapNaviDriveManager sharedInstance]  selectNaviRouteWithRouteID:routeID])
    {
        return;
    }
    
    NSArray <AMapNaviPoint *> *oriCoordinateArray = [[AMapNaviDriveManager sharedInstance] .naviRoute.routeCoordinates copy];
    NSArray <AMapNaviTrafficStatus *> *trafficStatus = [[AMapNaviDriveManager sharedInstance]  getTrafficStatusesWithStartPosition:0 distance:(int)[AMapNaviDriveManager sharedInstance] .naviRoute.routeLength];
    
    NSMutableArray <AMapNaviPoint *> *resultCoords = [[NSMutableArray alloc] init];
    NSMutableArray <NSNumber *> *coordIndexes = [[NSMutableArray alloc] init];
    NSMutableArray <UIColor *> *strokeColors = [[NSMutableArray alloc] init];
    [resultCoords addObject:[oriCoordinateArray objectAtIndex:0]];
    
    //依次计算每个路况的长度对应的polyline点的index
    unsigned int i = 1;
    NSInteger sumLength = 0;
    NSInteger statusesIndex = 0;
    NSInteger curTrafficLength = [[trafficStatus firstObject] length];
    
    for ( ; i < [oriCoordinateArray count]; i++)
    {
        double segDis = [self calcDistanceBetweenPoint:[oriCoordinateArray objectAtIndex:i-1]
                                              andPoint:[oriCoordinateArray objectAtIndex:i]];
        
        //两点间插入路况改变的点
        if (sumLength + segDis >= curTrafficLength)
        {
            if (sumLength + segDis == curTrafficLength)
            {
                [resultCoords addObject:[oriCoordinateArray objectAtIndex:i]];
                [coordIndexes addObject:[NSNumber numberWithInteger:((int)[resultCoords count]-1)]];
            }
            else
            {
                double rate = (segDis==0 ? 0 : ((curTrafficLength - sumLength) / segDis));
                AMapNaviPoint *extrnPoint = [self calcPointWithStartPoint:[oriCoordinateArray objectAtIndex:i-1]
                                                                 endPoint:[oriCoordinateArray objectAtIndex:i]
                                                                     rate:MAX(MIN(rate, 1.0), 0)];
                if (extrnPoint)
                {
                    [resultCoords addObject:extrnPoint];
                    [coordIndexes addObject:[NSNumber numberWithInteger:((int)[resultCoords count]-1)]];
                    [resultCoords addObject:[oriCoordinateArray objectAtIndex:i]];
                }
                else
                {
                    [resultCoords addObject:[oriCoordinateArray objectAtIndex:i]];
                    [coordIndexes addObject:[NSNumber numberWithInteger:((int)[resultCoords count]-1)]];
                }
            }
            
            //添加对应的strokeColors
            [strokeColors addObject:[self defaultColorForStatus:[[trafficStatus objectAtIndex:statusesIndex] status]]];
            
            sumLength = sumLength + segDis - curTrafficLength;
            
            if (++statusesIndex >= [trafficStatus count])
            {
                break;
            }
            curTrafficLength = [[trafficStatus objectAtIndex:statusesIndex] length];
        }
        else
        {
            [resultCoords addObject:[oriCoordinateArray objectAtIndex:i]];
            
            sumLength += segDis;
        }
    }
    
    //将最后一个点对齐到路径终点
    if (i < [oriCoordinateArray count])
    {
        while (i < [oriCoordinateArray count])
        {
            [resultCoords addObject:[oriCoordinateArray objectAtIndex:i]];
            i++;
        }
        
        [coordIndexes removeLastObject];
        [coordIndexes addObject:[NSNumber numberWithInteger:((int)[resultCoords count]-1)]];
    }
    else
    {
        while (((int)[coordIndexes count])-1 >= (int)[trafficStatus count])
        {
            [coordIndexes removeLastObject];
            [strokeColors removeLastObject];
        }
        
        [coordIndexes addObject:[NSNumber numberWithInteger:((int)[resultCoords count]-1)]];
        //需要修改textureImages的最后一个与trafficStatus最后一个一致
        [strokeColors addObject:[self defaultColorForStatus:[[trafficStatus lastObject] status]]];
    }
    
    //添加Polyline
    NSInteger coordCount = [resultCoords count];
    CLLocationCoordinate2D *coordinates = (CLLocationCoordinate2D *)malloc(coordCount * sizeof(CLLocationCoordinate2D));
    for (int k = 0; k < coordCount; k++)
    {
        AMapNaviPoint *aCoordinate = [resultCoords objectAtIndex:k];
        coordinates[k] = CLLocationCoordinate2DMake(aCoordinate.latitude, aCoordinate.longitude);
    }
    
    //创建SelectableTrafficOverlay
    SelectableTrafficOverlay *polyline = [SelectableTrafficOverlay polylineWithCoordinates:coordinates count:coordCount drawStyleIndexes:coordIndexes];
    polyline.routeID = routeID;
    polyline.selected = NO;
    polyline.polylineWidth = 10;
    polyline.polylineStrokeColors = strokeColors;
    
    if (coordinates != NULL)
    {
        free(coordinates);
    }
    
    [self.mapView addOverlay:polyline level:MAOverlayLevelAboveLabels];
}


#pragma mark - SubViews

/**
 *
 *在顶部视图额外添加四个按钮子控件 (驾车、公交、骑行、步行)
 */
- (void)configSubViews
{
    double singleWidth = (CGRectGetWidth(self.view.bounds) - 50) / 4.0;
    self.preferenceView = [[PreferenceView alloc] initWithFrame:CGRectMake(0, 5, CGRectGetWidth(self.view.bounds), 30)];
    [self.view addSubview:self.preferenceView];
    
//    UIButton *routeBtn = [self createToolButton];
//    [routeBtn setFrame:CGRectMake((CGRectGetWidth(self.view.bounds)-80)/2.0, 40, 80, 30)];
//    [routeBtn setTitle:@"路径规划" forState:UIControlStateNormal];
//    [routeBtn addTarget:self action:@selector(routePlanAction:) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:routeBtn];

    
    //驾车按钮
    _driveBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, 40, singleWidth, 25)];//定位按钮
    [_driveBtn setTitle:@"驾车" forState:UIControlStateNormal];
    [_driveBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_driveBtn setBackgroundColor:[UIColor whiteColor]];
    [_driveBtn setBackgroundColor:[UIColor colorWithRed:0.99 green:0.99 blue:0.99 alpha:1.0]];
    _driveBtn.layer.cornerRadius = 12.0;//2.0是圆角的弧度，根据需求自己更改
    [_driveBtn addTarget:self action:@selector(driveRoute:) forControlEvents:UIControlEventTouchUpInside];//点击，标记移到地图中心点
    [self.view addSubview:_driveBtn];
    
    //公交按钮
    _busBtn = [[UIButton alloc] initWithFrame:CGRectMake(20 + singleWidth, 40, singleWidth, 25)];//定位按钮
    [_busBtn setTitle:@"公交" forState:UIControlStateNormal];
    [_busBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_busBtn setBackgroundColor:[UIColor whiteColor]];
    [_busBtn setBackgroundColor:[UIColor colorWithRed:0.99 green:0.99 blue:0.99 alpha:1.0]];
    _busBtn.layer.cornerRadius = 12.0;//2.0是圆角的弧度，根据需求自己更改
    [_busBtn addTarget:self action:@selector(busRoute:) forControlEvents:UIControlEventTouchUpInside];//点击，标记移到地图中心点
    [self.view addSubview:_busBtn];
    
    //骑行按钮
    _rideBtn = [[UIButton alloc] initWithFrame:CGRectMake(30 + singleWidth *2, 40, singleWidth, 25)];//定位按钮
    [_rideBtn setTitle:@"骑行" forState:UIControlStateNormal];
    [_rideBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_rideBtn setBackgroundColor:[UIColor whiteColor]];
    [_rideBtn setBackgroundColor:[UIColor colorWithRed:0.99 green:0.99 blue:0.99 alpha:1.0]];
    _rideBtn.layer.cornerRadius = 12.0;//2.0是圆角的弧度，根据需求自己更改
    [_rideBtn addTarget:self action:@selector(rideRoute:) forControlEvents:UIControlEventTouchUpInside];//点击，标记移到地图中心点
    [self.view addSubview:_rideBtn];
    
    //步行按钮
     _walkBtn = [[UIButton alloc] initWithFrame:CGRectMake(40 + singleWidth *3, 40, singleWidth, 25)];//定位按钮
    [_walkBtn setTitle:@"步行" forState:UIControlStateNormal];
    [_walkBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_walkBtn setBackgroundColor:[UIColor whiteColor]];
    [_walkBtn setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1.0]];
    _walkBtn.layer.cornerRadius = 12.0;//2.0是圆角的弧度，根据需求自己更改
    [_walkBtn addTarget:self action:@selector(walkRoute:) forControlEvents:UIControlEventTouchUpInside];//点击，标记移到地图中心点
    [self.view addSubview:_walkBtn];
    
    
    self.bottomInfoView = [[BottomInfoView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds) - 64 - kBottomInfoViewHeight, CGRectGetWidth(self.view.bounds), kBottomInfoViewHeight)];
    self.bottomInfoView.delegate = self;
    [self.view addSubview:self.bottomInfoView];
    
    RouteInfoViewModel *aNilModel = [[RouteInfoViewModel alloc] init];
    aNilModel.routeTag = @"请在上方进行算路";
    [self.bottomInfoView setAllRouteInfo:@[aNilModel]];
}


- (UIButton *)createToolButton
{
    UIButton *toolBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    
    toolBtn.layer.borderColor  = [UIColor lightGrayColor].CGColor;
    toolBtn.layer.borderWidth  = 0.5;
    toolBtn.layer.cornerRadius = 5;
    
    [toolBtn setBounds:CGRectMake(0, 0, 80, 30)];
    [toolBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    toolBtn.titleLabel.font = [UIFont systemFontOfSize:13.0];
    
    return toolBtn;
}

#pragma mark - BottomInfoView Delegate

- (void)bottomInfoViewSelectedRouteWithRouteID:(NSInteger)routeID
{
    //选择对应的路线
    [self selectNaviRouteWithID:routeID];
}

/**
 *开始导航
 *
 */
- (void)bottomInfoViewStartNaviWithRouteID:(NSInteger)routeID
{
    GPSNaviViewController *gpsVC = [[GPSNaviViewController alloc] init];
    [gpsVC setDelegate:self];
    
    if(_flag == 0){
    
    //将driveView添加为导航数据的Representative，使其可以接收到导航诱导数据
    [[AMapNaviDriveManager sharedInstance]  addDataRepresentative:gpsVC.driveView];
    [self.navigationController pushViewController:gpsVC animated:YES];
    [[AMapNaviDriveManager sharedInstance]  startGPSNavi];
        
    }else if(_flag == 3){

    //将walkView添加为导航数据的Representative，使其可以接收到导航诱导数据
    [self.walkManager  addDataRepresentative:gpsVC.walkView];
    [self.navigationController pushViewController:gpsVC animated:YES];
    [self.walkManager  startGPSNavi];

    }
   
}

#pragma mark - AMapNaviDriveManager Delegate

- (void)driveManager:(AMapNaviDriveManager *)driveManager error:(NSError *)error
{
    NSLog(@"error:{%ld - %@}", (long)error.code, error.localizedDescription);
}

- (void)driveManagerOnCalculateRouteSuccess:(AMapNaviDriveManager *)driveManager
{
    NSLog(@"onCalculateRouteSuccess");
    
//    self.needRoutePlan = NO;
    [self showNaviRoutes];
}

- (void)driveManager:(AMapNaviDriveManager *)driveManager onCalculateRouteFailure:(NSError *)error
{
    NSLog(@"onCalculateRouteFailure:{%ld - %@}", (long)error.code, error.localizedDescription);
}

- (void)driveManager:(AMapNaviDriveManager *)driveManager didStartNavi:(AMapNaviMode)naviMode
{
    NSLog(@"didStartNavi");
}

- (void)driveManagerNeedRecalculateRouteForYaw:(AMapNaviDriveManager *)driveManager
{
    NSLog(@"needRecalculateRouteForYaw");
}

- (void)driveManagerNeedRecalculateRouteForTrafficJam:(AMapNaviDriveManager *)driveManager
{
    NSLog(@"needRecalculateRouteForTrafficJam");
}

- (void)driveManager:(AMapNaviDriveManager *)driveManager onArrivedWayPoint:(int)wayPointIndex
{
    NSLog(@"onArrivedWayPoint:%d", wayPointIndex);
}

- (BOOL)driveManagerIsNaviSoundPlaying:(AMapNaviDriveManager *)driveManager
{
    return [[SpeechSynthesizer sharedSpeechSynthesizer] isSpeaking];
}

- (void)driveManager:(AMapNaviDriveManager *)driveManager playNaviSoundString:(NSString *)soundString soundStringType:(AMapNaviSoundType)soundStringType
{
    NSLog(@"playNaviSoundString:{%ld:%@}", (long)soundStringType, soundString);
    
    [[SpeechSynthesizer sharedSpeechSynthesizer] speakString:soundString];
}

- (void)driveManagerDidEndEmulatorNavi:(AMapNaviDriveManager *)driveManager
{
    NSLog(@"didEndEmulatorNavi");
}

- (void)driveManagerOnArrivedDestination:(AMapNaviDriveManager *)driveManager
{
    NSLog(@"onArrivedDestination");
}


#pragma mark - AMapNaviWalkManager Delegate

- (void)walkManager:(AMapNaviWalkManager *)walkManager error:(NSError *)error
{
    NSLog(@"error:{%ld - %@}", (long)error.code, error.localizedDescription);
}

- (void)walkManagerOnCalculateRouteSuccess:(AMapNaviWalkManager *)walkManager
{
    NSLog(@"onCalculateRouteSuccess");
    
    //算路成功后显示路径
    [self showNaviRoutes];
}

- (void)walkManager:(AMapNaviWalkManager *)walkManager onCalculateRouteFailure:(NSError *)error
{
    NSLog(@"onCalculateRouteFailure:{%ld - %@}", (long)error.code, error.localizedDescription);
}

- (void)walkManager:(AMapNaviWalkManager *)walkManager didStartNavi:(AMapNaviMode)naviMode
{
    NSLog(@"didStartNavi");
}

- (void)walkManagerNeedRecalculateRouteForYaw:(AMapNaviWalkManager *)walkManager
{
    NSLog(@"needRecalculateRouteForYaw");
}

- (void)walkManager:(AMapNaviWalkManager *)walkManager playNaviSoundString:(NSString *)soundString soundStringType:(AMapNaviSoundType)soundStringType
{
    NSLog(@"playNaviSoundString:{%ld:%@}", (long)soundStringType, soundString);
    [[SpeechSynthesizer sharedSpeechSynthesizer] speakString:soundString];
}

- (void)walkManagerDidEndEmulatorNavi:(AMapNaviWalkManager *)walkManager
{
    NSLog(@"didEndEmulatorNavi");
}

- (void)walkManagerOnArrivedDestination:(AMapNaviWalkManager *)walkManager
{
    NSLog(@"onArrivedDestination");
}

#pragma mark - DriveNaviView Delegate

/**
 *
 *退出驾车导航
 */
- (void)driveNaviViewCloseButtonClicked
{
    [[AMapNaviDriveManager sharedInstance]  stopNavi];
    
    //停止语音
    [[SpeechSynthesizer sharedSpeechSynthesizer] stopSpeak];
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - walkNaviView Delegate

/**
 *
 *退出步行导航
 */
- (void)walkNaviViewCloseButtonClicked
{
   
    [self.walkManager stopNavi];
    
    //停止语音
    [[SpeechSynthesizer sharedSpeechSynthesizer] stopSpeak];
    
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - MAMapView Delegate

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    if ([annotation isKindOfClass:[NaviPointAnnotation class]])
    {
        static NSString *annotationIdentifier = @"NaviPointAnnotationIdentifier";
        
        MAPinAnnotationView *pointAnnotationView = (MAPinAnnotationView*)[self.mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
        if (pointAnnotationView == nil)
        {
            pointAnnotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation
                                                                  reuseIdentifier:annotationIdentifier];
        }
        
        pointAnnotationView.animatesDrop   = NO;
        pointAnnotationView.canShowCallout = YES;
        pointAnnotationView.draggable      = NO;
        
        NaviPointAnnotation *navAnnotation = (NaviPointAnnotation *)annotation;
        
        if (navAnnotation.navPointType == NaviPointAnnotationStart)
        {
            [pointAnnotationView setPinColor:MAPinAnnotationColorGreen];
        }
        else if (navAnnotation.navPointType == NaviPointAnnotationEnd)
        {
            [pointAnnotationView setPinColor:MAPinAnnotationColorRed];
        }
        
        return pointAnnotationView;
    }
    return nil;
}

- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id<MAOverlay>)overlay
{
    if ([overlay isKindOfClass:[SelectableTrafficOverlay class]])
    {
        SelectableTrafficOverlay *routeOverlay = (SelectableTrafficOverlay *)overlay;
        
        if (routeOverlay.polylineStrokeColors && routeOverlay.polylineStrokeColors.count > 0)
        {
            MAMultiColoredPolylineRenderer *polylineRenderer = [[MAMultiColoredPolylineRenderer alloc] initWithMultiPolyline:routeOverlay];
            
            polylineRenderer.lineWidth = routeOverlay.polylineWidth;
            polylineRenderer.lineJoinType = kMALineJoinRound;
            polylineRenderer.strokeColors = routeOverlay.polylineStrokeColors;
            polylineRenderer.gradient = NO;
            polylineRenderer.fillColor = [UIColor redColor];
            
            return polylineRenderer;
        }
        else if (routeOverlay.polylineTextureImages && routeOverlay.polylineTextureImages.count > 0)
        {
            MAMultiTexturePolylineRenderer *polylineRenderer = [[MAMultiTexturePolylineRenderer alloc] initWithMultiPolyline:routeOverlay];
            
            polylineRenderer.lineWidth = routeOverlay.polylineWidth;
            polylineRenderer.lineJoinType = kMALineJoinRound;
            polylineRenderer.strokeTextureImages = routeOverlay.polylineTextureImages;
            
            return polylineRenderer;
        }
    }else if([overlay isKindOfClass:[MAPolyline class]]){
        MAPolylineRenderer *polylineRenderer = [[MAPolylineRenderer alloc] initWithPolyline:overlay];
        
        polylineRenderer.lineWidth    = 8.f;
        polylineRenderer.strokeColor  = [UIColor colorWithRed:0.05 green:0.39 blue:0.9  alpha:0.8];
        polylineRenderer.lineJoinType = kMALineJoinRound;
        polylineRenderer.lineCapType  = kMALineCapRound;
        
        return polylineRenderer;
    }
    
    return nil;
}



@end
