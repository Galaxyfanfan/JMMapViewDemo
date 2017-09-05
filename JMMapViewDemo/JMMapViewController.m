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




@interface JMMapViewController ()<MAMapViewDelegate,AMapSearchDelegate>
@property (nonatomic , strong) MAMapView *mapView;
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

#pragma mark ---------------Event-------------------------/



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

- (NSMutableArray *)dataArr{
    if (!_dataArr) {
        _dataArr = [[NSMutableArray alloc]init];
    }
    return _dataArr;
}

@end
