//
//  DispatchOnceManager.h
//  GCDDemo
//
//  Created by Content on 2017/6/1.
//  Copyright © 2017年 flymanshow. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DispatchOnceManager : NSObject
+ (DispatchOnceManager *)shareManager;
@end
