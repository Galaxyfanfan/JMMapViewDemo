//
//  JMMapModel.h
//  JMMapViewDemo
//
//  Created by galaxy on 2017/9/4.
//  Copyright © 2017年 galaxy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface JMMapModel : NSObject

@property (nonatomic , assign) double bLng;
@property (nonatomic , assign) double bLat;
@property (nonatomic , assign) double gLat;
@property (nonatomic , assign) double gLng;

@property (nonatomic , copy) NSString *name;
@property (nonatomic , copy) NSString *availTotal;
@property (nonatomic , copy) NSString *emptyTotal;
@property (nonatomic , assign) NSInteger distance;



@end
