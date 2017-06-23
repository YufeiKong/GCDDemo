//
//  DispatchOnceManager.m
//  GCDDemo
//
//  Created by Content on 2017/6/1.
//  Copyright © 2017年 flymanshow. All rights reserved.
//

#import "DispatchOnceManager.h"

@implementation DispatchOnceManager

static DispatchOnceManager *sharedManager = nil;

+ (DispatchOnceManager *)shareManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
    sharedManager = [[self alloc] init];
        
    });
    return sharedManager;
}
@end
