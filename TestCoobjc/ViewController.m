//
//  ViewController.m
//  TestCoobjc
//
//  Created by sidi wang on 2019/8/7.
//  Copyright © 2019 sidi wang. All rights reserved.
//

#import "ViewController.h"
#import "Actor.h"
#import "MultiThread.h"
#import "Counter.h"
#import <coobjc/coobjc.h>
#import <cocore/cocore.h>
#import <cocore/coroutine_context.h>


@interface ViewController ()
@property (nonatomic, assign) NSInteger testNum;
@property (nonatomic, strong) Actor *actor;
@property (nonatomic, strong) MultiThread *multiThread;
@property (nonatomic, strong) COChan *chan;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.testNum = 1;
//    [self test];
//    [self testCoobjcFunction];
//    [self testAwait];
//    [self testGenerator];
//    [self testNormalAsyncFunc];
//    [self testCORoutineAsyncFunc];
//    [self testCOChan];
//    [self testFibonacciLazySequence];
//    [self testMultiThreadAwait];
    
    //Actor
//    self.actor = [[Actor alloc] init];
//    [self.actor startTask];
//    NSLog(@"finish ______");
//    NSLog(@"Main Thread Done");
    
    //MultiThread
//    self.multiThread = [[MultiThread alloc] init];
//    [self.multiThread start];
    
    //Counter
//    [self testTraditionalCounter];
//    [self testCountActor];

    
    //callStack
//    [self testCallStack];
}

- (void)testCOChan {
    self.chan = [COChan chan];
    co_launch(^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"chan receive val:%@", [self.chan receive_nonblock]);
        });
        [self.chan send:@(1)];
        NSLog(@"send finish");
    });
}

- (void)testCallStack {
    co_launch(^{
        NSLog(@"1");
    });
    co_launch(^{
        NSLog(@"2");
    });
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"3");
    });
}

- (void)test {
    coroutine_ucontext_t context;
    coroutine_getcontext(&context);
    NSLog(@"hello world");
    sleep(1);
    coroutine_setcontext(&context);
    
}

- (void)test1 {
    coroutine_t *routine = coroutine_create(func1);
    coroutine_resume(routine);
    printf("main");
    coroutine_resume(routine);
    
}

void func1(void *arg) {
    printf("111");
    coroutine_yield((coroutine_t *)arg);
    printf("222");
}

- (void)testCoobjcPromise {
    COPromise *promise = [COPromise promise:^(COPromiseFulfill  _Nonnull fullfill, COPromiseReject  _Nonnull reject) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            fullfill(@"异步任务结束");
        });
    } onQueue:dispatch_get_global_queue(0, 0)];
    [promise then:^id _Nullable(id  _Nullable value) {
        NSLog(@"%@",value);
        return nil;
    }];
}

- (COPromise *)Promise {
    COPromise *promise = [COPromise promise:^(COPromiseFulfill  _Nonnull fullfill, COPromiseReject  _Nonnull reject) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            fullfill(@"异步任务结束");
        });
    } onQueue:dispatch_get_global_queue(0, 0)];
    return promise;
}

-(void)testAwait {
    co_launch(^{
        NSString * str = await([self Promise]);
        NSLog(@"%@", str);
    });
}

- (void)testMultiThreadAwait {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self testAwait];
    });
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self testAwait];
    });
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self testAwait];
    });
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self testAwait];
    });
}

- (void)testGenerator {
    COGenerator *generator = [[COGenerator alloc] initWithBlock:^{
        int index = 0;
        while(co_isActive()){
            yield_val(@(index));
            index++;
        }
    } onQueue:dispatch_get_global_queue(0, 0) stackSize:1024];
    co_launch(^{
        for(int i = 0; i < 10; i++){
            int val = [[generator next] intValue];
            NSLog(@"generator______value:%d",val);
        }
    });
}

- (void)testNormalAsyncFunc {
//    @weakify(self);
    [self asyncTask:^(NSInteger number) {
//        @strongify(self);
        [self asyncTask:^(NSInteger number) {
            NSInteger num = number + 1;
            [self asyncTask:^(NSInteger number) {
                NSLog(@"testNormalAsyncFunc_____%ld",(long)number);
            } withNumber:num];
        } withNumber:number];
    } withNumber:1];
}

- (void)asyncTask:(void(^)(NSInteger number))callBack withNumber:(NSInteger)number {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (callBack) {
            callBack(number);
        }
    });
}

- (void)testCORoutineAsyncFunc {
    co_launch(^{
        NSLog(@"co start");
        NSNumber *num = await([self promiseWithNumber:@(1)]);
        NSLog(@"co finish");
//        NSError *error = co_getError(); 如果有错误，可以这样获取
        num = await([self promiseWithNumber:@(num.integerValue + 1)]);
        num = await([self promiseWithNumber:@(num.integerValue + 1)]);
//        NSLog(@"testCORoutineAsyncFunc______%@",num);
    });
    NSLog(@"sidiwang");
}

- (COPromise *)promiseWithNumber:(NSNumber *)number {
    COPromise *promise = [COPromise promise:^(COPromiseFulfill  _Nonnull fullfill, COPromiseReject  _Nonnull reject) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            fullfill(number);
//            reject(error);  // 如果有错误，回调到上层
        });
    } onQueue:dispatch_get_global_queue(0, 0)];
    return promise;
}

- (void)testFibonacciLazySequence {
    COGenerator *fibonacci = [[COGenerator alloc] initWithBlock:^{
        yield_val(@(1));
        int cur = 1;
        int next = 1;
        while(co_isActive()){
            yield(@(next));
            int temp = cur + next;
            cur = next;
            next = temp;
        }
    } onQueue:dispatch_get_global_queue(0, 0) stackSize:1024];
    co_launch(^{
        for(int i = 0; i < 10; i++){
            int val = [[fibonacci next] intValue];
            NSLog(@"fibonacciLazySequence______value:%d",val);
        }
    });
}

- (void)testCountActor {
    COActor *countActor = co_actor_onqueue(dispatch_queue_create("test queue", NULL), ^(COActorChan *channel) {
        int count = 0;
        for(COActorMessage *message in channel){
            if([[message stringType] isEqualToString:@"inc"]){
                count++;
            }
            else if([[message stringType] isEqualToString:@"get"]){
                message.complete(@(count));
            }
        }
    });
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 15;
    for (int i = 0;i < 10000;i++) {
        NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            [countActor sendMessage:@"inc"];
        }];
        [queue addOperation:operation];
    }
    [queue waitUntilAllOperationsAreFinished];
    co_launch(^{
        int currentCount = [await([countActor sendMessage:@"get"]) intValue];
        NSLog(@"count: %d", currentCount);
    });
}

- (void)testTraditionalCounter {
    Counter *counter = [[Counter alloc] init];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 15;
    for (int i = 0;i < 10000;i++) {
        NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            [counter incCount];
        }];
        [queue addOperation:operation];
    }
    [queue waitUntilAllOperationsAreFinished];
    NSLog(@"count:%d", [counter getCount]);

//    for (int i = 0;i < 10000;i++) {
//        dispatch_async(dispatch_get_global_queue(0, 0), ^{
//            [counter incCount];
//            NSLog(@"count:%d", [counter getCount]);
//        });
//    }
}

@end
