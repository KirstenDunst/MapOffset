//
//  ViewController.m
//  MapOffset
//
//  Created by CSX on 2017/1/7.
//  Copyright © 2017年 宗盛商业. All rights reserved.
//

#import "ViewController.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>


@interface ViewController ()<CLLocationManagerDelegate,MKMapViewDelegate>
{
    MKMapView *_mapView;//全局地图对象
    UITextView *showTextView;
}
//定位服务的入口点，设置成属性
@property(nonatomic,strong)CLLocationManager *locationManager;

@property(nonatomic,copy)NSString *latitude;//纬度
@property(nonatomic,copy)NSString *longitude;//经度
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //判断是否开启定位服务，GPS传感器是否可用
    if ([CLLocationManager locationServicesEnabled]) {//是否开启定位服务
        if ([CLLocationManager headingAvailable]) {//传感器是否可用
            self.locationManager=[[CLLocationManager alloc] init];
            self.locationManager.delegate=self;
            self.locationManager.desiredAccuracy=kCLLocationAccuracyBest;//最高精度
            self.locationManager.headingFilter=kCLHeadingFilterNone;//设置滤波器不工作（过滤器用于过滤更新信号，默认为1，这里我们使其不工作，即接受所有更新信号，达到最精准模式)
            
            //iOS8以后加入了问询用户是否开启定位权限，这里需要判断操作系统版本，如果要兼容iOS7及以下，需要自己判断版本
            if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
                [self.locationManager requestWhenInUseAuthorization];
            }
            else {
                NSLog(@"版本不匹配");
            }
        }
        else {
            NSLog(@"传感器不可用");
        }
    }
    else {
        UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"未开启定位服务"
                                                      message:@"请至设置-隐私-定位服务中开启定位服务"
                                                     delegate:self
                                            cancelButtonTitle:@"确定"
                                            otherButtonTitles:nil, nil];
        [alert setAlertViewStyle:UIAlertViewStyleDefault];
        [alert show];
    }
    
    //初始化地图，如果只想获得坐标不要地图，可以将frame设置在视图外，初始化后隐藏
    _mapView=[[MKMapView alloc] init];
    _mapView.frame=CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    _mapView.delegate=self;
    _mapView.mapType=MKMapTypeStandard;//地图标准模式
    _mapView.showsUserLocation=YES;//显示当前位置
    _mapView.userTrackingMode=MKUserTrackingModeFollow;//跟随
    [self.view addSubview:_mapView];
    //    _mapView.hidden=YES;
    
    
    showTextView = [[UITextView alloc]initWithFrame:CGRectMake(0, 40, self.view.frame.size.width, 120)];
    showTextView.backgroundColor = [UIColor clearColor];
    showTextView.textColor = [UIColor redColor];
    showTextView.font = [UIFont systemFontOfSize:16];
    [self.view addSubview:showTextView];
    
    

    
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    //开始定位
    [self.locationManager startUpdatingLocation];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    //停止定位
    [self.locationManager stopUpdatingLocation];
}

//默认点击地图当前位置的蓝点只会显示"当前位置"四个字，如果要显示当前地址需要设置蓝点的title，不想显示地图的可以不用实现这个代理方法
#pragma mark MKMapViewDelegate
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation{
    //当前的坐标，反编码
    CLGeocoder *geo = [[CLGeocoder alloc] init];
    [geo reverseGeocodeLocation:userLocation.location completionHandler:^(NSArray *placemarks, NSError *error) {
        //取出标记
        CLPlacemark *pm = [placemarks lastObject];
        //赋值
        userLocation.title = pm.name;
    }];
}

#pragma mark - CLLocationManagerDelegate
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    //获取WGS-84坐标的对象，两者选其一（世界规定坐标经纬度信息）
    CLLocation *location=[locations lastObject];
    CLLocationCoordinate2D coords1=location.coordinate;
    //获取GCJ-02坐标的对象，两者选其一(中国坐标偏移标准)
    CLLocationCoordinate2D coords=_mapView.userLocation.location.coordinate;
    //获得经纬度
    NSLog(@"纬度%f,经度%f",coords.latitude,coords.longitude);
    
    showTextView.text = [NSString stringWithFormat:@"现在的位置坐标\nGCJ-02\n纬度%f,经度%f\nWGS-84\n纬度:%f,纬度:%f",coords.latitude,coords.longitude,coords1.latitude,coords1.longitude];
    
    //经纬方向
    NSString *latitudeDirection=nil;
    NSString *longitudeDirection=nil;
    if (coords.latitude>=0) {
        latitudeDirection=@"N";
    }
    else if (coords.latitude<0) {
        latitudeDirection=@"S";
    }
    
    if (coords.longitude>=0) {
        longitudeDirection=@"E";
    }
    else if (coords.longitude<0) {
        longitudeDirection=@"W";
    }
    //经纬度拼接方向
    self.latitude=[NSString stringWithFormat:@"%f%@",coords.latitude,latitudeDirection];//纬度
    self.longitude=[NSString stringWithFormat:@"%f%@",coords.longitude,longitudeDirection];//经度
    
    //这个代理方法会每秒执行一次，如果你只想定位成功一次就结束定位，需要判断定位成功后在此处调用stopUpdatingLocation结束定位。
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    if (error.code==kCLErrorDenied) {
        //提示出错原因
    }
}














- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



//附：经纬度十进制（小数）转六十进制（度分秒）的方法
#pragma mark - 经纬度单位转换
- (NSString *)stringWithCoordinateString:(NSString *)coordinateString{
    //示例：118.815033
    /** 将经度或纬度整数部分提取出来 */
    int latNumber = [coordinateString intValue];//118
    
    /** 取出小数点后面两位(为转化成'分'做准备) */
    NSArray *array = [coordinateString componentsSeparatedByString:@"."];
    /** 小数点后面部分 */
    NSString *minuteCompnetString = [array lastObject];
    
    /** 拼接字字符串(将字符串转化为0.xxxx形式) */
    NSString *str1 = [NSString stringWithFormat:@"0.%@", minuteCompnetString];
    
    /** 将字符串转换成float类型以便计算 */
    float minuteNum = [str1 floatValue];   //0.815033
    
    /** 将小数点后数字转化为'分'(minuteNum * 60) */
    float minuteNum1 = minuteNum * 60;    //0.815033*60=48.90198
    
    /** 将转化后的float类型转化为字符串类型 */
    NSString *latStr = [NSString stringWithFormat:@"%f", minuteNum1];
    
    /** 取整数部分即为纬度或经度'分' */
    int latMinute = [latStr intValue]; //48
    
    //取秒
    /** 取出小数点后面两位(为转化成'秒'做准备) */
    NSArray *secondArr = [latStr componentsSeparatedByString:@"."];
    /** 小数点后面部分 */
    NSString *lastCompnetString = [secondArr lastObject];
    
    /** 拼接字字符串(将字符串转化为0.xxxx形式) */
    NSString *str2 = [NSString stringWithFormat:@"0.%@", lastCompnetString];
    
    /** 将字符串转换成float类型以便计算 */
    float secondNum = [str2 floatValue];   //0.90198
    
    /** 将小数点后数字转化为'分'(minuteNum * 60) */
    float secondNum1 = secondNum * 60;    //0.90198*60=54.1188
    
    /** 将转化后的float类型转化为字符串类型 */
    NSString *latStr2 = [NSString stringWithFormat:@"%f", secondNum1];
    
    /** 取整数部分即为纬度或经度'分' */
    int latSecond = [latStr2 intValue]; //54
    
    /** 将经度或纬度字符串合并为(xx°xx')形式 */
    NSString *string = [NSString stringWithFormat:@"%d°%d'%d''", latNumber, latMinute, latSecond];
    
    return string;
}
@end
