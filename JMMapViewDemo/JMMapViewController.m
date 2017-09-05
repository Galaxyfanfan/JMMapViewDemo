//
//  JMMapViewController.m
//  JMMapViewDemo
//
//  Created by galaxy on 2017/9/4.
//  Copyright © 2017年 galaxy. All rights reserved.
//

#import "JMMapViewController.h"
#import "JMMapModel.h"

#import <MAMapKit/MAMapKit.h>
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <AMapSearchKit/AMapSearchKit.h>
#import <AMapNaviKit/AMapNaviKit.h>
#import <AMapLocationKit/AMapLocationKit.h>


@interface JMMapViewController ()<MAMapViewDelegate,AMapSearchDelegate,AMapNaviDriveManagerDelegate,AMapLocationManagerDelegate>
@property (nonatomic , strong) MAMapView *mapView;
@property (nonatomic , strong) AMapNaviDriveManager *driveManager;//行车路线规划
@property (nonatomic , strong) AMapLocationManager *locationManager;//定位
@property (nonatomic , strong) CLLocation *myLocation;
@property (nonatomic , strong) NSMutableArray *dataArr;
@end

@implementation JMMapViewController

#pragma mark ---------------LifeCycle-------------------------/
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initView];
    [self loadData];
    [self addAnnotations];
}

- (void)initView{
    ///地图需要v4.5.0及以上版本才必须要打开此选项（v4.5.0以下版本，需要手动配置info.plist）
    [AMapServices sharedServices].enableHTTPS = YES;
    [self.view addSubview:self.mapView];
    
    MAUserLocationRepresentation *r = [[MAUserLocationRepresentation alloc] init];
    [self.mapView updateUserLocationRepresentation:r];
    
    //开始定位
    [self startSerialLocation];

}

#pragma mark ---------------NetWork-------------------------/
- (void)loadData{
    
    NSData *JSONData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"JMLocation" ofType:@"json"]];
    NSDictionary *dataDict = [NSJSONSerialization JSONObjectWithData:JSONData options:NSJSONReadingAllowFragments error:nil];
    
    NSArray *result = dataDict[@"bicyles"];
    for (NSDictionary *subDic in result) {
        JMMapModel *model = [JMMapModel mj_objectWithKeyValues:subDic];
        [self.dataArr addObject:model];
    }
//    NSLog(@"%@",self.dataArr);
}

#pragma mark - 添加大头针和动画
//添加大头针
- (void)addAnnotations{
    NSMutableArray *array_annotations = [[NSMutableArray alloc]init];
    
    for (JMMapModel *model in self.dataArr) {
        MAPointAnnotation *annotation =  [[MAPointAnnotation alloc]init];
        annotation.coordinate = CLLocationCoordinate2DMake(model.gLat, model.gLng);
        annotation.title = model.name;
        annotation.subtitle = [NSString stringWithFormat:@"%@|%@",model.availTotal,model.emptyTotal];
        [array_annotations addObject:annotation];
    }
    [self.mapView addAnnotations:array_annotations];
}

#pragma mark ---------------定位 ---------------------/
- (void)startSerialLocation{
    //开始定位
    [self.locationManager startUpdatingLocation];
}

- (void)stopSerialLocation{
    //停止定位
    [self.locationManager stopUpdatingLocation];
}

- (void)amapLocationManager:(AMapLocationManager *)manager didUpdateLocation:(CLLocation *)location{
    //定位结果
    NSLog(@"location:{lat:%f; lon:%f; accuracy:%f}", location.coordinate.latitude, location.coordinate.longitude, location.horizontalAccuracy);
    self.myLocation = location;
}

#pragma mark ---------------Event-------------------------/





#pragma mark --------------- Map Delegate ---------------------/
- (MAAnnotationView*)mapView:(MAMapView *)mapView viewForAnnotation:(id <MAAnnotation>)annotation {

    static NSString *pointReuseIndetifier = @"pointReuseIndetifier";
    MAAnnotationView *annotationView = (MAAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:pointReuseIndetifier];
    if (annotationView == nil){
        annotationView = [[MAAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:pointReuseIndetifier];
    }
    annotationView.annotation = annotation;
    annotationView.frame = CGRectMake(0, 0, 100, 100);
    annotationView.canShowCallout= YES;       //设置气泡可以弹出，默认为NO
    annotationView.image = [UIImage imageNamed:@"map_parking"];
    
    annotationView.draggable = YES;
    
    return annotationView;

    
    return nil;

}

- (void)mapView:(MAMapView *)mapView didSelectAnnotationView:(MAAnnotationView *)view{
    CLLocationCoordinate2D coordinate = view.annotation.coordinate;
    
    AMapNaviPoint *startPoint = [AMapNaviPoint locationWithLatitude:self.myLocation.coordinate.latitude longitude:self.myLocation.coordinate.longitude];
    AMapNaviPoint *endPoint = [AMapNaviPoint locationWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    [self.driveManager calculateDriveRouteWithStartPoints:@[startPoint]
                                                endPoints:@[endPoint]
                                                wayPoints:nil
                                          drivingStrategy:17];
}

- (void)driveManagerOnCalculateRouteSuccess:(AMapNaviDriveManager *)driveManager
{
    NSLog(@"onCalculateRouteSuccess");
    
    //显示路径或开启导航
    //将路径显示到地图上
    if (driveManager.naviRoute == nil){
        return;
    }
    
    [self.mapView removeOverlays:self.mapView.overlays];
    
    AMapNaviRoute *aRoute = driveManager.naviRoute;
    int count = (int)[[aRoute routeCoordinates] count];
    
    //添加路径Polyline
    CLLocationCoordinate2D *coords = (CLLocationCoordinate2D *)malloc(count * sizeof(CLLocationCoordinate2D));
    for (int i = 0; i < count; i++)
    {
        AMapNaviPoint *coordinate = [[aRoute routeCoordinates] objectAtIndex:i];
        coords[i].latitude = [coordinate latitude];
        coords[i].longitude = [coordinate longitude];
    }
    
    MAPolyline *polyline = [MAPolyline polylineWithCoordinates:coords count:count];
    
    [self.mapView addOverlay:polyline];
}

- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id<MAOverlay>)overlay{

    if ([overlay isKindOfClass:[MAPolyline class]]){
        MAPolylineRenderer *polylineRenderer = [[MAPolylineRenderer alloc] initWithPolyline:(MAPolyline *)overlay];
        
        polylineRenderer.lineWidth = 8.f;
        polylineRenderer.strokeColor = [UIColor redColor];
 
        return polylineRenderer;
    }
    return nil;
}

#pragma mark ---------------Lazy-------------------------/
- (MAMapView *)mapView{
    if (!_mapView) {
        ///初始化地图
        _mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        _mapView.delegate = self;
        //设置地图缩放比例，即显示区域
        [_mapView setZoomLevel:15.1 animated:YES];
        //设置定位精度
        _mapView.desiredAccuracy = kCLLocationAccuracyBest;
        //设置定位距离
        _mapView.distanceFilter = 5.0f;
        
        ///如果您需要进入地图就显示定位小蓝点，则需要下面两行代码
        _mapView.showsUserLocation = YES;
        _mapView.userTrackingMode = MAUserTrackingModeFollow;
    }
    return _mapView;
}

- (AMapNaviDriveManager *)driveManager{
    if (!_driveManager) {
        _driveManager = [[AMapNaviDriveManager alloc] init];
        [_driveManager setDelegate:self];
    }
    return _driveManager;
}

- (AMapLocationManager *)locationManager{
    if (!_locationManager) {
        _locationManager = [[AMapLocationManager alloc]init];
        [_locationManager setDelegate:self];
        [_locationManager setPausesLocationUpdatesAutomatically:NO];

    }
    return _locationManager;
}

- (NSMutableArray *)dataArr{
    if (!_dataArr) {
        _dataArr = [[NSMutableArray alloc]init];
    }
    return _dataArr;
}

@end
