//
//  ViewController.m
//  GCDDemo
//
//  Created by Content on 2017/5/27.
//  Copyright © 2017年 flymanshow. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
{
    dispatch_source_t _timer;
    NSArray *_dataSource;
    NSArray *_sectionTitles;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSArray *queueSource = @[@"并发队列 + 同步执行", @"并发队列 + 异步执行", @"串行队列 + 同步执行", @"串行队列 + 异步执行", @"主队列 + 同步执行(死锁)", @"主队列 + 异步执行"];
    NSArray *baseSource = @[@"栅栏方法", @"延时执行方法", @"一次性执行", @"快速迭代方法", @"dispatch_set_target_queue"];
    NSArray *groupSource = @[@"队列组：异步任务的并行1", @"队列组：异步任务的并行2", @"队列组：异步任务的并行3"];
    NSArray *semaphoreSource = @[@"信号量"];
    NSArray *dispatchSource = @[@"dispatch源"];
    _dataSource = @[queueSource,baseSource, groupSource, semaphoreSource,dispatchSource];
    _sectionTitles = @[@"队列任务组合",@"基础使用方法", @"队列组group", @"semaphore信号量", @"dispatch源"];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.rowHeight = 50;
    tableView.sectionHeaderHeight = 60;
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    [self.view addSubview:tableView];
    
    
}
#pragma mark ---dispatch源  倒计时
-(void)dispatchSource{
    
    UILabel *timeLabel = [[UILabel alloc]initWithFrame:CGRectMake((375-150)/2, 100, 150, 30)];
    timeLabel.textAlignment = NSTextAlignmentCenter;
    timeLabel.layer.borderColor = [UIColor lightGrayColor].CGColor;
    timeLabel.layer.borderWidth = 1;
    [self.view addSubview:timeLabel];

    __block  NSInteger timeout = 10000; //倒计时时间
    if (timeout!=0) {
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,queue);
       
        
        dispatch_source_set_timer(_timer,dispatch_walltime(NULL, 0),1.0*NSEC_PER_SEC, 0);//dispatch_walltime是根据钟表计算时间 即使设备休眠了 他也不会休眠  每1秒执行  定期产生通知
        dispatch_source_set_event_handler(_timer, ^{
            
        if(timeout==0){ //倒计时结束，关闭
            
        dispatch_source_cancel(_timer);
        _timer = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            
        timeLabel.text = @"00:00:00";
            
        });
            
        }else{
            
        NSInteger minutes = (timeout % 3600) / 60;
        NSInteger seconds = timeout % 60;
        NSInteger hours = timeout /3600 ;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
        timeLabel.text = [NSString stringWithFormat:@"%02zd : %02zd : %02zd",(long)hours,(long)minutes,(long)seconds];
            
        });
        timeout--;
        }
            
        });
        dispatch_resume(_timer);//dispatch源创建后处于dispatch_suspend挂起状态，所以需要启动dispatch源。
                                //dispatch_ resume恢复队列
     }
}
-(void)dealloc{

    dispatch_source_cancel(_timer);
    _timer = NULL;
}
#pragma mark -----信号量
-(void)dispatchSemaphore{

    //创建一个信号量，初始值为0
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSLog(@"start");
    dispatch_semaphore_signal(sema); //信号通知   信号值加1
        
    });
    
    //信号等待
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);//信号值大于>=1往下执行 并且此时信号量-1  又变成0
    NSLog(@"A:%@", [NSThread currentThread]);
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    dispatch_semaphore_signal(sema); //发送信号通知  信号值加1
    NSArray *array = @[@"B", @"C", @"D", @"E"];
    
    for (int i = 0; i < [array count]; i++) {
        
    dispatch_async(queue, ^{
        
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);//信号值大于>=1往下执行 并且此时信号量-1
    [NSThread sleepForTimeInterval:1];
    NSLog(@"%@:%@", [array objectAtIndex:i], [NSThread currentThread]);
    dispatch_semaphore_signal(sema);
        
    });
    }
    NSLog(@"F:%@", [NSThread currentThread]);
    
}
#pragma mark --dispatch block
- (void)dispatchCreateBlockDemo {
    
    //基本方式
    dispatch_queue_t concurrentQueue = dispatch_queue_create("queue",DISPATCH_QUEUE_CONCURRENT);
    dispatch_block_t block = dispatch_block_create(0, ^{
        NSLog(@"run block");
    });
    dispatch_async(concurrentQueue, block);
    
    //QOS方式
    dispatch_block_t qosBlock = dispatch_block_create_with_qos_class(0, QOS_CLASS_USER_INITIATED, -1, ^{
        NSLog(@"run qos block");
    });
    dispatch_async(concurrentQueue, qosBlock);
    
}

#pragma mark --取消某个进程
-(void)dispatchCancel{

    dispatch_queue_t queue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL);
    dispatch_block_t block1 = dispatch_block_create(0, ^{
       
    NSLog(@"block1 begin");
        
    [NSThread sleepForTimeInterval:1];
   
    NSLog(@"block1 done");
        
    });
    dispatch_block_t block2 = dispatch_block_create(0, ^{
       
    NSLog(@"block2 ");
        
    });
    dispatch_async(queue, block1);
    dispatch_async(queue, block2);
    dispatch_block_cancel(block2);
    
}
#pragma mark --使用dispatch_set_target_queue将多个串行的队列指定到了同一目标，那么这多个串行队列在目标队列上就是同步执行的
-(void)setTargetQueue{

    //1.创建目标队列
    dispatch_queue_t targetQueue = dispatch_queue_create("queue", DISPATCH_QUEUE_SERIAL);
    //2.创建3个串行队列
    dispatch_queue_t queue1 = dispatch_queue_create("test.1", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t queue2 = dispatch_queue_create("test.2", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t queue3 = dispatch_queue_create("test.3", DISPATCH_QUEUE_SERIAL);
    //3.将3个串行队列分别添加到目标队列
    dispatch_set_target_queue(queue1, targetQueue);
    dispatch_set_target_queue(queue2, targetQueue);
    dispatch_set_target_queue(queue3, targetQueue);
    
    dispatch_async(queue1, ^{
        
        NSLog(@"1 in");
        [NSThread sleepForTimeInterval:2.f];
        NSLog(@"1 out");
        
    });
    
    dispatch_async(queue2, ^{
        
        NSLog(@"2 in");
        [NSThread sleepForTimeInterval:2.f];
        NSLog(@"2 out");
    });
    
    dispatch_async(queue3, ^{
       
        NSLog(@"3 in");
        [NSThread sleepForTimeInterval:2.f];
        NSLog(@"3 out");
        
    });
    //相当于在同一个队列里面并行  输出1 in  1 out  2 in  2 out  3 in  3 out
}
#pragma mark - 一次性代码
- (void)dispatchOnce {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 只执行1次的代码(这里面默认是线程安全的)
    });
    
}
#pragma mark --重复代码块
-(void)setDispatch_apply{
    
    NSArray *array = @[@"a", @"b", @"c", @"d", @"e", @"f", @"g", @"h", @"i", @"j"];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_apply([array count], queue, ^(size_t index) {
        
    NSLog(@"%zu: %@", index, [array objectAtIndex:index]);
        
    });
    NSLog(@"done");
    
}
#pragma mark --栅栏 等待dispatch_barrier前面的方法走完 再执行dispatch_barrier_async
-(void)setBarrier{
    
     UIImageView *img = [[UIImageView alloc]initWithFrame:CGRectMake(75/2, 200, 300, 200)];
     img.layer.borderColor = [UIColor lightGrayColor].CGColor;
     img.layer.borderWidth = 1;
     [self.view addSubview:img];
    
     dispatch_queue_t queue = dispatch_queue_create("KYF", DISPATCH_QUEUE_CONCURRENT);

    __block UIImage *image1 = nil;
    __block UIImage *image2 = nil;
    // 1.开启一个新的线程下载第一张图片
    dispatch_async(queue, ^{
        
    NSURL *url = [NSURL URLWithString:@"https://imgsa.baidu.com/forum/w%3D580%3B/sign=9107d2cb99ef76c6d0d2fb23ad2dfffa/32fa828ba61ea8d389c574ee9e0a304e241f5870.jpg"];
    NSData *data = [NSData dataWithContentsOfURL:url];
    UIImage *image = [UIImage imageWithData:data];
    image1 = image;
    NSLog(@"图片1下载完毕");
        
    });
    // 2.开启一个新的线程下载第二张图片
    dispatch_async(queue, ^{
        
    NSURL *url = [NSURL URLWithString:@"https://imgsa.baidu.com/forum/w%3D580%3B/sign=72280f5de050352ab16125006378f9f2/b8389b504fc2d562cdeed007ee1190ef77c66c71.jpg"];
    NSData *data = [NSData dataWithContentsOfURL:url];
    UIImage *image = [UIImage imageWithData:data];
    image2 = image;
    NSLog(@"图片2下载完毕");
    
    });
    // 3.开启一个新的线程, 合成图片
    // 栅栏
    dispatch_barrier_async(queue, ^{
    // 图片下载完毕
    NSLog(@"%@ %@", image1, image2);
    // 1.开启图片上下文
    UIGraphicsBeginImageContext(CGSizeMake(200, 200));
    // 2.将第一张图片画上去
    [image1 drawInRect:CGRectMake(0, 0, 100, 200)];
    // 3.将第二张图片画上去
    [image2 drawInRect:CGRectMake(100, 0, 100, 200)];
    // 4.从上下文中获取绘制好的图片
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    // 5.关闭上下文
    UIGraphicsEndImageContext();
    // 4.回到主线程更新UI
    dispatch_async(dispatch_get_main_queue(), ^{
    img.image = newImage;

    });
    NSLog(@"栅栏执行完毕了");
    });
//    dispatch_queue_t concurrentQueue = dispatch_queue_create("kyf", DISPATCH_QUEUE_CONCURRENT);
//    dispatch_async(concurrentQueue, ^{
//        NSLog(@"dispatch-1");
//    });
//    dispatch_async(concurrentQueue, ^{
//        NSLog(@"dispatch-2");
//    });
//    dispatch_barrier_async(concurrentQueue, ^{
//         NSLog(@"dispatch-barrier");
//    });
//    dispatch_async(concurrentQueue, ^{
//        NSLog(@"dispatch-3");
//    });
//    dispatch_async(concurrentQueue, ^{
//        NSLog(@"dispatch-4");
//    });

}
#pragma mark ---延迟
-(void)dispatchDelay{

    dispatch_group_t groupQueue = dispatch_group_create();
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC);
    dispatch_queue_t conCurrentGlobalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    NSLog(@"current task");
    dispatch_group_async(groupQueue, conCurrentGlobalQueue, ^{
    
    long isExecuteOver = dispatch_group_wait(groupQueue, delayTime);
    if (isExecuteOver) {
        NSLog(@"wait over");
    } else {
        NSLog(@"not over");
    }
    NSLog(@"并行任务1");
    });
    dispatch_group_async(groupQueue, conCurrentGlobalQueue, ^{
        NSLog(@"并行任务2");
    });
    
    //[self performSelector:@selector(dealy) withObject:nil afterDelay:2];
    // dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5*NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
    //  });
    //[NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(sfs) userInfo:nil repeats:NO];
    //[NSThread sleepForTimeInterval:2.0];
    
}
#pragma mark ---调度组
-(void)setGroupQueue{
    
    dispatch_queue_t conCurrentGlobalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    dispatch_group_t groupQueue = dispatch_group_create();
    NSLog(@"current task");
    
    dispatch_group_async(groupQueue, conCurrentGlobalQueue, ^{
        NSLog(@"并行任务1");
    });
    dispatch_group_async(groupQueue, conCurrentGlobalQueue, ^{
        
        NSLog(@"并行任务2");
    });
    //会一直等待，直到任务全部完成或者超时，此时开始执行他后面的代码。
    dispatch_group_notify(groupQueue, mainQueue, ^{
        
        NSLog(@"groupQueue中的任务 都执行完成,回到主线程更新UI");
    });
}
#pragma mark ---调度组dispatch_group_notify
-(void)setGroupQueue2{
    

    dispatch_queue_t concurrentQueue = dispatch_queue_create("kyf", DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_t group = dispatch_group_create();
    
    //加入调度组 dispatch_enter和dispatch_leave要成对出现，否则奔溃。
    dispatch_group_enter(group);
    dispatch_async(concurrentQueue, ^{
        sleep(3);
        NSLog(@"并行任务1");
        dispatch_group_leave(group);
    });
    
    dispatch_group_enter(group);
    dispatch_async(concurrentQueue, ^{
        sleep(3);
        NSLog(@"并行任务2");
        dispatch_group_leave(group);
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"groupQueue中的任务 都执行完成,回到主线程更新UI");
    });
}

#pragma mark ---调度组dispatch_group_wait
-(void)setGroupQueue3{
    
    dispatch_queue_t concurrentQueue = dispatch_queue_create("kyf", DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_enter(group);
    dispatch_async(concurrentQueue, ^{
        sleep(3);
        NSLog(@"并行任务1");
        dispatch_group_leave(group);
    });
    
    dispatch_group_enter(group);
    dispatch_async(concurrentQueue, ^{
       
        sleep(3);
        NSLog(@"并行任务2");
        dispatch_group_leave(group);
    });
    //以异步的方式工作。当调度组中没有任何任务时，它就会执行其block回调代码。
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    dispatch_async(dispatch_get_main_queue(), ^{
        
    NSLog(@"groupQueue中的任务 都执行完成,回到主线程更新UI");
        
    });
    NSLog(@"next task");
    //输出 并行任务1  并行任务2  nexttask  回到主线程
    
    
}
#pragma mark --异步执行 + 并行队列
- (void)asyncConcurrent{
    //创建一个并行队列
    dispatch_queue_t queue = dispatch_queue_create("标识符2", DISPATCH_QUEUE_CONCURRENT);
    NSLog(@"---start---");
    
    //使用异步函数封装三个任务
    dispatch_async(queue, ^{
        
    NSLog(@"任务1---%@", [NSThread currentThread]);
    [NSThread sleepForTimeInterval:2];
    NSLog(@"任务111---%@", [NSThread currentThread]);
        
    });
    dispatch_async(queue, ^{
        
    NSLog(@"任务2---%@", [NSThread currentThread]);
    [NSThread sleepForTimeInterval:2];
    NSLog(@"任务222---%@", [NSThread currentThread]);
        
    });
    dispatch_async(queue, ^{
        
    NSLog(@"任务3---%@", [NSThread currentThread]);
    [NSThread sleepForTimeInterval:2];
    NSLog(@"任务333---%@", [NSThread currentThread]);
        
    });
    NSLog(@"---end---");
    //函数在执行时，先打印了start和end，再回头执行这三个任务 任务1 2 3 任务111 222 333
}
#pragma mark --异步执行 + 串行队列
- (void)asyncSerial{
   
    //创建一个串行队列
    dispatch_queue_t queue = dispatch_queue_create("标识符", DISPATCH_QUEUE_SERIAL);
    NSLog(@"---start---");
    
    //使用异步函数封装三个任务
    dispatch_async(queue, ^{
        
    NSLog(@"任务1---%@", [NSThread currentThread]);
    [NSThread sleepForTimeInterval:2];
    NSLog(@"任务111---%@", [NSThread currentThread]);
        
    });
    dispatch_async(queue, ^{
        
    NSLog(@"任务2---%@", [NSThread currentThread]);
    [NSThread sleepForTimeInterval:2];
    NSLog(@"任务222---%@", [NSThread currentThread]);
        
    });
    dispatch_async(queue, ^{
        
    NSLog(@"任务3---%@", [NSThread currentThread]);
    [NSThread sleepForTimeInterval:2];
    NSLog(@"任务333---%@", [NSThread currentThread]);
        
    });
    
    NSLog(@"---end---");
    //函数在执行时，先打印了start和end，再回头执行这三个任务 任务1 111 任务2 222 任务3 333
    
}
#pragma mark --同步执行 + 并行队列
- (void)syncConcurrent{
    //创建一个并行队列
    dispatch_queue_t queue = dispatch_queue_create("标识符", DISPATCH_QUEUE_CONCURRENT);
    NSLog(@"---start---");
   //同步任务 不开启线程
    dispatch_sync(queue, ^{
        NSLog(@"任务1---%@", [NSThread currentThread]);
        [NSThread sleepForTimeInterval:2];
        NSLog(@"任务111---%@", [NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        NSLog(@"任务2---%@", [NSThread currentThread]);
        [NSThread sleepForTimeInterval:2];
        NSLog(@"任务222---%@", [NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        NSLog(@"任务3---%@", [NSThread currentThread]);
        [NSThread sleepForTimeInterval:2];
        NSLog(@"任务333---%@", [NSThread currentThread]);
    });
    NSLog(@"---end---");
    //在这里即便是并行队列，任务可以同时执行，但是由于只存在一个主线程，所以没法把任务分发到不同的线程去同步处理，其结果就是只能在主线程里按顺序挨个执行了
    //start 任务1 111 任务2  222 任务3  333  end
}
#pragma mark --同步执行 + 串行队列
- (void)syncSerial{
    
    //创建一个串行队列
    dispatch_queue_t queue = dispatch_queue_create("标识符", DISPATCH_QUEUE_SERIAL);
    NSLog(@"---start---");
    //同步任务 不开启线程
    dispatch_sync(queue, ^{
        NSLog(@"任务1---%@", [NSThread currentThread]);
        [NSThread sleepForTimeInterval:2];
        NSLog(@"任务111---%@", [NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        NSLog(@"任务2---%@", [NSThread currentThread]);
        [NSThread sleepForTimeInterval:2];
        NSLog(@"任务222---%@", [NSThread currentThread]);
    });
    dispatch_sync(queue, ^{
        NSLog(@"任务3---%@", [NSThread currentThread]);
        [NSThread sleepForTimeInterval:2];
        NSLog(@"任务333---%@", [NSThread currentThread]);
    });
    NSLog(@"---end---");
    //start 任务1 111 任务2  222 任务3  333  end
}
#pragma mark --异步执行 + 主队列
- (void)asyncMain{
   
    //获取主队列
    dispatch_queue_t queue = dispatch_get_main_queue();
    
    NSLog(@"---start---");

    dispatch_async(queue, ^{
        
    NSLog(@"任务1---%@", [NSThread currentThread]);
    [NSThread sleepForTimeInterval:2];
    NSLog(@"任务111---%@", [NSThread currentThread]);
        
    });
    dispatch_async(queue, ^{
        
    NSLog(@"任务2---%@", [NSThread currentThread]);
    [NSThread sleepForTimeInterval:2];
    NSLog(@"任务222---%@", [NSThread currentThread]);
        
    });
    dispatch_async(queue, ^{
        
    NSLog(@"任务3---%@", [NSThread currentThread]);
    [NSThread sleepForTimeInterval:2];
    NSLog(@"任务333---%@", [NSThread currentThread]);
        
    });
    NSLog(@"---end---");

    //主队列中的任务必须在主队列中执行，不能在子线程中执行。并且，主队列类似于一种串行队列，所以按顺序执行
    //函数在执行时，先打印了start和end，再回头执行 任务1 111 任务2  222 任务3  333

}
#pragma mark --同步执行 + 主队列
- (void)syncMain{
    
    //获取主队列
    dispatch_queue_t queue = dispatch_get_main_queue();
    NSLog(@"---start---");
    //使用同步函数封装三个任务
    dispatch_sync(queue, ^{
        
    NSLog(@"任务1---%@", [NSThread currentThread]);
    });
    
    NSLog(@"---end---");
    //A:整个方法主队列   B:任务一
    //主线程上的任务是顺序执行的，任务的顺序位为A B，但是B任务包含在A任务内，执行完A才能执行B,但是执行A的时候又必须执行B, 造成了冲突，死锁。
  
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        NSLog(@"1");
//        //回到主线程发现死循环后面就没法执行了
//        dispatch_sync(dispatch_get_main_queue(), ^{
//            NSLog(@"2");
//        });
//        NSLog(@"3");
//    });
//    NSLog(@"4");
//    //死循环
//    while (1) {
//        
//    }
    
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return _dataSource.count;
    
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [_dataSource[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.textLabel.font = [UIFont systemFontOfSize:15];
    cell.textLabel.text = [NSString stringWithFormat:@"%d. %@", (int)(indexPath.row+1), _dataSource[indexPath.section][indexPath.row]];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    return _sectionTitles[section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    [self syncConcurrent];//并行同步
                    break;
                case 1:
                    [self asyncConcurrent];//并行异步
                    break;
                case 2:
                    [self syncSerial];//串行同步
                    break;
                case 3:
                    [self asyncSerial];//串行异步
                    break;
                case 4:
                    [self syncMain];//主队列同步 死锁
                    break;
                case 5:
                    [self asyncMain];//主队列异步
                    break;
                    default:
                    break;
                }
            break;
        case 1:
                switch (indexPath.row) {
                case 0:
                    [self setBarrier];//栅栏
                    break;
                case 1:
                    [self dispatchDelay];//延时执行
                    break;
                case 2:
                    [self dispatchOnce];//一次性解决
                    break;
                case 3:
                    [self setDispatch_apply];//快速迭代
                    break;
                case 4:
                    [self setTargetQueue];//dispatch_set_target_queue
                    break;
                default:
                    break;
            }
            break;
        case 2:
            switch (indexPath.row) {
                case 0:
                    [self setGroupQueue];//异步任务的并行
                    break;
                case 1:
                    [self setGroupQueue2];//异步任务的并行
                    break;
                case 2:
                    [self setGroupQueue3];//异步任务的并行
                    break;
                default:
                    break;
            }
            break;
        case 3:
            switch (indexPath.row) {
                case 0:
                    [self dispatchSemaphore];//信号量
                    break;
                default:
                    break;
            }
            break;
        case 4:
            switch (indexPath.row) {
                case 0:
                    [self dispatchSource];//调度源
                    break;
                default:
                    break;
            }
            break;
            
        case 5:
            switch (indexPath.row) {
                case 0:
                    [self dispatchCreateBlockDemo];//dispatch block
                    break;
                case 1:
                    [self dispatchCancel];//取消某个进程
                    break;
                default:
                    break;
            }
            break;
        default:
            break;
    }
}

@end
