//
//  AppDelegate.h
//  GCDDemo
//
//  Created by Content on 2017/5/27.
//  Copyright © 2017年 flymanshow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;
@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundUpdateTask; 

- (void)saveContext;


@end

