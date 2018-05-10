//
//  ViewController.m
//  MABaseStation
//
//  Created by loop on 2018/4/26.
//  Copyright © 2018年 loop. All rights reserved.
//

#define MAS_SHORTHAND
// 定义这个常量，就可以让Masonry帮我们自动把基础数据类型的数据，自动装箱为对象类型。
#define MAS_SHORTHAND_GLOBALS

#import "ViewController.h"
#import "MMSideslipDrawer.h"
#import "ReGeocodeAnnotation.h"
#import "GeocodeAnnotation.h"
#import "RoutePlanDriveViewController.h"
#import "CommonUtility.h"
#import "PYSearch.h"

@interface ViewController ()<MMSideslipDrawerDelegate,MAMapViewDelegate,PYSearchViewControllerDelegate,AMapSearchDelegate>
{
    //侧滑菜单
    MMSideslipDrawer *slipDrawer;
    //地图
    MAMapView *_mapView;
    //定位标记
    MAAnnotationView *_userLocationAnnotationView;
    //目的地按钮标题
    NSString *destinationBtnTitle;
    //用于显示当前定位地址的Label
    UILabel *BeginPosition;
    //目的地按钮
    UIButton *destinationBtn;
    AMapSearchAPI *_search;
    //反地理编码的标记
    ReGeocodeAnnotation *_annotation;
    //当前定位位置坐标
    CLLocationCoordinate2D coordinateTemp;
//    CLLocationCoordinate2D coordinate;
}

@end

@implementation ViewController

static CLLocationCoordinate2D departurePosition;
static CLLocationCoordinate2D destinationPosition;
//在类之间传递起点、终点坐标
+ (void)setDeparturPosition:(CLLocationCoordinate2D )startCoordinate
{
    departurePosition = startCoordinate ;
    NSLog(@"dddd %f %f",departurePosition.latitude,departurePosition.longitude);
}
+ (CLLocationCoordinate2D )departurePosition
{
    return departurePosition;
}

+ (void)setDestinationPosition:(CLLocationCoordinate2D)endCoordinate
{
    destinationPosition = endCoordinate ;
}
+ (CLLocationCoordinate2D )destinationPosition
{
    return destinationPosition;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    ///地图需要v4.5.0及以上版本才必须要打开此选项（v4.5.0以下版本，需要手动配置info.plist）
    [AMapServices sharedServices].enableHTTPS = YES;
    
    ///初始化地图
    _mapView = [[MAMapView alloc] initWithFrame:self.view.bounds];
    
    _mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _mapView.delegate = self;
    ///如果您需要进入地图就显示定位小蓝点，则需要下面两行代码
    _mapView.showsUserLocation = YES;
    _mapView.userTrackingMode = MAUserTrackingModeFollow;
    _mapView.userLocation.title = @"您的位置在这里";
    
    ///把地图添加至view
    [_mapView setZoomLevel:18];
    [self.view addSubview:_mapView];
    
    _search = [[AMapSearchAPI alloc] init];
    _search.delegate = self;
    
    
    
    //侧滑栏控件属性设置
    self.navigationItem.title = @"DEMO";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu_left"] style:UIBarButtonItemStylePlain target:self action:@selector(leftDrawerButtonPress:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu_right"] style:UIBarButtonItemStylePlain target:self action:@selector(rightDrawerButtonPress:)];
    
    //起始点输入
    UIView *startPoint = [[UIView alloc]initWithFrame:CGRectMake(50, 20, 250, 30)];
    startPoint.backgroundColor = [UIColor groupTableViewBackgroundColor];
    startPoint.layer.shadowOpacity = 0.5f;
    startPoint.layer.shadowOffset = CGSizeMake(5.0f, -2.0f);
    startPoint.layer.shadowRadius = 35.0f;
    [self.view addSubview:startPoint];
    //约束
    [startPoint mas_makeConstraints:^(MASConstraintMaker *make){
        
        make.left.equalTo(self.view).with.offset(20);
        make.top.equalTo(self.view).with.offset(50);
        make.right.equalTo(self.view).with.offset(-20);
        make.height.equalTo(self.view).multipliedBy(0.1);
    }];
    
    //终点输入
    destinationBtn = [[UIButton alloc]initWithFrame:CGRectMake(50, 50, 250, 30)];
    [destinationBtn setTitle:@"请选择目的基站" forState:UIControlStateNormal];
    [destinationBtn setBackgroundColor:[UIColor whiteColor]];
    [destinationBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [destinationBtn setBackgroundImage:[self imageWithColor:[UIColor groupTableViewBackgroundColor]] forState:UIControlStateHighlighted];
    [destinationBtn addTarget:self action:@selector(searchDestiBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:destinationBtn];
    //约束
    [destinationBtn mas_makeConstraints:^(MASConstraintMaker *make){
        
        make.left.equalTo(self.view).with.offset(20);
        make.top.equalTo(startPoint.mas_bottom).with.offset(0);
        make.right.equalTo(self.view).with.offset(-20);
        make.height.equalTo(self.view).multipliedBy(0.1);
    }];
    
    //当前定位位置label显示
    BeginPosition = [[UILabel alloc]initWithFrame:CGRectMake(50, 24,200, 20)];
    BeginPosition.font = [UIFont systemFontOfSize:12];
    BeginPosition.backgroundColor = [UIColor whiteColor];
    BeginPosition.textAlignment = NSTextAlignmentCenter;
    BeginPosition.textColor = [UIColor blackColor];
    BeginPosition.numberOfLines = 2 ;
    [startPoint addSubview:BeginPosition];
    //约束
    [BeginPosition mas_makeConstraints:^(MASConstraintMaker *make){
        
        make.left.equalTo(startPoint).with.offset(1);
        make.top.equalTo(startPoint).with.offset(1);
        make.right.equalTo(startPoint).with.offset(-1);
        make.bottom.equalTo(startPoint).with.offset(-1);
    }];
    
    //定位按钮
    UIButton *locationBtn = [[UIButton alloc] initWithFrame:CGRectMake(15, 500, 40, 40)];//定位按钮
    [locationBtn setImage:[UIImage imageNamed:@"定位"] forState:UIControlStateNormal];
    [locationBtn setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1.0]];
    locationBtn.layer.cornerRadius = 4.0;//2.0是圆角的弧度，根据需求自己更改
    locationBtn.layer.shadowOpacity = 0.5f;
    locationBtn.layer.shadowOffset = CGSizeMake(3.0f, -3.0f);
    locationBtn.layer.shadowRadius = 5.0f;
    [locationBtn addTarget:self action:@selector(centerBtn:) forControlEvents:UIControlEventTouchUpInside];//点击，标记移到地图中心点
    [self.view addSubview:locationBtn];
    //约束
    [locationBtn mas_makeConstraints:^(MASConstraintMaker *make){
        make.left.equalTo(self.view).with.offset(20);
        make.bottom.equalTo(self.view).with.offset(-50);
        make.width.mas_equalTo(35);
        make.height.mas_equalTo(35);
    }];
    
    //调用按钮
    UIButton *callBaiduMapBtn = [[UIButton alloc] initWithFrame:CGRectMake(245, 500, 40, 40)];//定位按钮
    [callBaiduMapBtn setImage:[UIImage imageNamed:@"调用"] forState:UIControlStateNormal];
    [callBaiduMapBtn setBackgroundColor:[UIColor colorWithRed:0.99 green:0.99 blue:0.99 alpha:1.0]];
    callBaiduMapBtn.layer.cornerRadius = 4.0;//2.0是圆角的弧度，根据需求自己更改
    callBaiduMapBtn.layer.shadowOpacity = 0.5f;
    callBaiduMapBtn.layer.shadowOffset = CGSizeMake(2.0f, -2.0f);
    callBaiduMapBtn.layer.shadowRadius = 5.0f;
    [callBaiduMapBtn addTarget:self action:@selector(CallBaiduMap:) forControlEvents:UIControlEventTouchUpInside];//点击，标记移到地图中心点
    [self.view addSubview:callBaiduMapBtn];
    //约束
    [callBaiduMapBtn mas_makeConstraints:^(MASConstraintMaker *make){
        make.left.equalTo(self.view).with.offset(245);
        make.bottom.equalTo(self.view).with.offset(-50);
        make.width.mas_equalTo(36);
        make.height.mas_equalTo(36);
    }];
    
}

/**
 *反地理编码
 *将得到的当前位置坐标转换为地址
 */
- (void)searchReGeocodeWithCoordinate
{
    CLLocationCoordinate2D coordinate = coordinateTemp; //当前定位位置的坐标
    departurePosition = coordinateTemp;
    AMapReGeocodeSearchRequest *regeo = [[AMapReGeocodeSearchRequest alloc] init];
    
    regeo.location                    = [AMapGeoPoint locationWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    
  
    regeo.requireExtension            = YES;
    
    [_search AMapReGoecodeSearch:regeo];
}

//长按可以得到坐标
//#pragma mark - MAMapViewDelegate
//
//- (void)mapView:(MAMapView *)mapView didLongPressedAtCoordinate:(CLLocationCoordinate2D)coordinate
//{
//    //    _isSearchFromDragging = NO;
//    [self searchReGeocodeWithCoordinate];
//}

#pragma mark - AMapSearchDelegate
- (void)AMapSearchRequest:(id)request didFailWithError:(NSError *)error
{
    NSLog(@"Error: %@ - %@", error, [ErrorInfoUtility errorDescriptionWithCode:error.code]);
}

/**
 *
 *逆地理编码回调.
 */
- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response
{
    if (response.regeocode != nil)
    {
        CLLocationCoordinate2D coordinate1 = CLLocationCoordinate2DMake(request.location.latitude, request.location.longitude);

        ReGeocodeAnnotation *reGeocodeAnnotation = [[ReGeocodeAnnotation alloc] initWithCoordinate:coordinate1
                                                                                         reGeocode:response.regeocode];
     
        NSString *addr = reGeocodeAnnotation.reGeocode.addressComponent.district;
       
        NSString *addr0 = reGeocodeAnnotation.reGeocode.addressComponent.streetNumber.street;
        
        NSString *addr1 = reGeocodeAnnotation.reGeocode.addressComponent.streetNumber.number;
        
        addr = [addr stringByAppendingString:addr0];
        addr = [addr stringByAppendingString:addr1];
//        NSLog(@"当前位置 %@",addr);
        BeginPosition.text = addr;
        
 //在某个坐标点添加标注 可以和上面的长按地图得到该点坐标一起使用
//        [self.mapView addAnnotation:reGeocodeAnnotation];
//        [self.mapView selectAnnotation:reGeocodeAnnotation animated:YES];
//    }
//    else /* from drag search, update address */
//    {
//        [self.annotation setAMapReGeocode:response.regeocode];
//        [self.mapView selectAnnotation:self.annotation animated:YES];
//    }
        
    }
    
}


/*
 *
 *地理编码回调
 */
- (void)onGeocodeSearchDone:(AMapGeocodeSearchRequest *)request response:(AMapGeocodeSearchResponse *)response
{
    if (response.geocodes.count == 0)
    {
        return;
    }
    
    NSMutableArray *annotations = [NSMutableArray array];
    
    [response.geocodes enumerateObjectsUsingBlock:^(AMapGeocode *obj, NSUInteger idx, BOOL *stop) {
        GeocodeAnnotation *geocodeAnnotation = [[GeocodeAnnotation alloc] initWithGeocode:obj];
        
        [annotations addObject:geocodeAnnotation];
    }];
    NSLog(@"annotations :%lu",annotations.count);
    if (annotations.count == 1)
    {
//      [_mapView setCenterCoordinate:[annotations[0] coordinate] animated:YES];//可以在GeocodeAnnotation.m里设置坐标
        [_mapView setCenterCoordinate:[annotations[0] coordinateX] animated:YES];//将标记点的坐标设为地图正中央[annotations[0] coordinate]得到标记点的坐标
        destinationPosition = [annotations[0] coordinateX];
    }
    else
    {
        [_mapView setVisibleMapRect:[CommonUtility minMapRectForAnnotations:annotations]
                               animated:YES];
    }
    
    [_mapView addAnnotations:annotations];//将GeocodeAnnotation类型的对象添加到可变数组annotations后 annotations为GeocodeAnnotation类型？or 可变数组类型？
   

}

/**
 *按钮方法
 *点击左下角按钮，使标记点移动到地图正中心
 */
- (void)centerBtn:(UIButton *)sender{
    
    NSLog(@"点击了左下角定位按钮");
    [_mapView setZoomLevel:18];
    [_mapView setCenterCoordinate:coordinateTemp];
//    [self searchReGeocodeWithCoordinate];
}


/**
 *按钮方法
 *点击右下角按钮，调用百度地图
 */
- (void)CallBaiduMap:(UIButton *)sender{
  
    NSLog(@"点击了右下角导航按钮");
    [self.navigationController pushViewController:[[RoutePlanDriveViewController alloc] initWithNibName:nil bundle:nil] animated:YES];
}

/**
 *按钮方法
 *点击顶部第二行“请选择目的基站”按钮，进入搜索界面
 */
- (void)searchDestiBtn:(UIButton *)sender
{
    //创建搜索控制器
    PYSearchViewController *searchViewController = [PYSearchViewController searchViewControllerWithHotSearches:nil searchBarPlaceholder:@"搜索目的基站" didSearchBlock:^(PYSearchViewController *searchViewController, UISearchBar *searchBar, NSString *searchText) {
        destinationBtnTitle = searchBar.text;//将搜索栏的输入值赋给按钮title
        [searchViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];//点击搜索后回到地图页
        [destinationBtn setTitle:searchBar.text forState:UIControlStateNormal];
        [destinationBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }];
    searchViewController.delegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:searchViewController];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //将搜索的输入值解析为坐标
    AMapGeocodeSearchRequest *geo = [[AMapGeocodeSearchRequest alloc] init];
    geo.address = destinationBtnTitle;
    NSLog(@"输入的目的地 %@",geo.address);
    [_search AMapGeocodeSearch:geo];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


#pragma mark - mapview delegate

- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id <MAOverlay>)overlay
{
    /* 自定义定位精度对应的MACircleView. */
    if (overlay == mapView.userLocationAccuracyCircle)
    {
        MACircleRenderer *accuracyCircleRenderer = [[MACircleRenderer alloc] initWithCircle:overlay];
        
        accuracyCircleRenderer.lineWidth    = 2.f;
        accuracyCircleRenderer.strokeColor  = [UIColor lightGrayColor];
        accuracyCircleRenderer.fillColor    = [UIColor colorWithRed:1 green:0 blue:0 alpha:.3];
        
        return accuracyCircleRenderer;
    }
    
    return nil;
}

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    /* 自定义userLocation对应的annotationView. */
    if ([annotation isKindOfClass:[MAUserLocation class]])
    {
        static NSString *userLocationStyleReuseIndetifier = @"userLocationStyleReuseIndetifier";
        MAAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:userLocationStyleReuseIndetifier];
        if (annotationView == nil)
        {
            annotationView = [[MAAnnotationView alloc] initWithAnnotation:annotation
                                                          reuseIdentifier:userLocationStyleReuseIndetifier];
        }
        
        annotationView.image = [UIImage imageNamed:@"userPosition"];
        
        _userLocationAnnotationView = annotationView;
        
        return annotationView;
    }
    
    return nil;
}

- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation
{
    coordinateTemp = userLocation.location.coordinate;

    [self searchReGeocodeWithCoordinate];
    if (!updatingLocation && _userLocationAnnotationView != nil)
    {
        [UIView animateWithDuration:0.1 animations:^{
            double degree = userLocation.heading.trueHeading - _mapView.rotationDegree;
            _userLocationAnnotationView.transform = CGAffineTransformMakeRotation(degree * M_PI / 180.f );
            
        }];
    }

}




#pragma mark - 懒加载
- (MMSideslipDrawer *)slipDrawer
{
    if (!slipDrawer)
    {
        MMSideslipItem *item = [[MMSideslipItem alloc] init];
        item.thumbnailPath = [[NSBundle mainBundle] pathForResource:@"menu_head@2x" ofType:@"png"];
        item.userName = @"LEA";
        item.userLevel = @"普通会员";
        item.levelImageName = @"menu_vip";
        item.textArray = @[@"行程",@"钱包",@"客服",@"设置"];
        item.imageNameArray = @[@"menu_0",@"menu_1",@"menu_2",@"menu_3"];
        
        slipDrawer = [[MMSideslipDrawer alloc] initWithDelegate:self slipItem:item];
    }
    return slipDrawer;
}

#pragma mark - 侧滑点击
- (void)leftDrawerButtonPress:(id)sender
{
    [self.slipDrawer openLeftDrawerSide];
}

- (void)rightDrawerButtonPress:(id)sender
{
    NSLog(@"右边点击");
}

#pragma mark - MMSideslipDrawerDelegate
- (void)slipDrawer:(MMSideslipDrawer *)slipDrawer didSelectAtIndex:(NSInteger)index
{
    [slipDrawer colseLeftDrawerSide];
    NSLog(@"点击的index:%ld",(long)index);
}

- (void)didViewUserInformation:(MMSideslipDrawer *)slipDrawer
{
    [slipDrawer colseLeftDrawerSide];
    NSLog(@"点击头像");
}

- (void)didViewUserLevelInformation:(MMSideslipDrawer *)slipDrawer
{
    [slipDrawer colseLeftDrawerSide];
    NSLog(@"点击会员");
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//  颜色转换为背景图片
- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark - PYSearchViewControllerDelegate
- (void)searchViewController:(PYSearchViewController *)searchViewController searchTextDidChange:(UISearchBar *)seachBar searchText:(NSString *)searchText
{
    if (searchText.length) {
        // Simulate a send request to get a search suggestions
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSMutableArray *searchSuggestionsM = [NSMutableArray array];
            for (int i = 0; i < arc4random_uniform(5) + 10; i++) {
                NSString *searchSuggestion = [NSString stringWithFormat:@"Search suggestion %d", i];
                [searchSuggestionsM addObject:searchSuggestion];
            }
            // Refresh and display the search suggustions
            searchViewController.searchSuggestions = searchSuggestionsM;
        });
    }
}
@end
