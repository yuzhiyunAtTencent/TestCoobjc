//
//  Actor.m
//  TestCoobjc
//
//  Created by sidi wang on 2019/9/15.
//  Copyright © 2019 sidi wang. All rights reserved.
//

#import "Actor.h"
#import <coobjc/coobjc.h>

@interface Actor ()
@property (nonatomic, strong) COActor *assembler;
@property (nonatomic, strong) COActor *dispatcher;
@property (nonatomic, strong) NSMutableArray<COActor *> *processers;
@property (nonatomic, assign) NSTimeInterval startTime;
@property (nonatomic, strong) COActor *processer;
@property (nonatomic, strong) COActor *counter;
@property (nonatomic, assign) NSInteger numberCount;
@property (nonatomic, assign) NSInteger globalCount;
@property (nonatomic, assign) NSInteger actorCount;

@end

@implementation Actor

- (instancetype)init
{
    self = [super init];
    if (self) {
        _processers = [NSMutableArray arrayWithCapacity:0];
        _numberCount = 100000;
        _globalCount = 1;

        [self setupProcessers];
        __weak Actor *weakSelf = self;
        
        _assembler = co_actor_onqueue(dispatch_queue_create("assembler", NULL), ^(COActorChan * _Nonnull chan) {
            __strong typeof(self) strongSelf = weakSelf;
            int numCount = 0;
            for (COActorMessage *message in chan) {
                if ([message.stringType isEqualToString:@"add"]) {
                    numCount ++;
                } else if ([message.stringType isEqualToString:@"finish"]) {
                    NSTimeInterval costTime = CFAbsoluteTimeGetCurrent() - strongSelf.startTime;
                    NSLog(@"素数的个数是______%d 消耗的时间_________%f", numCount, costTime);
                }
            }
        });

        _dispatcher = co_actor_onqueue(dispatch_queue_create("dispatcher", NULL), ^(COActorChan * _Nonnull chan) {
            __strong typeof(self) strongSelf = weakSelf;
            for (COActorMessage *message in chan) {
                if ([message.stringType isEqualToString:@"start"]) {
                    strongSelf.startTime = CFAbsoluteTimeGetCurrent();
                    while (strongSelf.globalCount <= strongSelf.numberCount - 1) {
                        [strongSelf.processers enumerateObjectsUsingBlock:^(COActor *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            if (strongSelf.globalCount >= strongSelf.numberCount - 1) {
                                return;
                            }
                            [obj sendMessage:@(strongSelf.globalCount++)];
                        }];
                    }
                    
                }
            }
        });
        
        _counter = co_actor_onqueue(dispatch_queue_create("counter", NULL), ^(COActorChan * _Nonnull chan) {
            __strong typeof(self) strongSelf = weakSelf;
            int callCount = 0;
            for (COActorMessage *message in chan) {
                if ([message.stringType isEqualToString:@"add"]) {
                    callCount++;
                    if (callCount == strongSelf.numberCount - 2) {
                        [strongSelf.assembler sendMessage:@"finish"];
                    }
                }
            }
        });
    }
    return self;
}

- (void)setupProcessers {
    __weak Actor *weakSelf = self;
    for (int i = 0;i < 60;i++) {
        const char *label = [[NSString stringWithFormat:@"myQueue%d",i] UTF8String];
        COActor *processer = co_actor_onqueue(dispatch_queue_create(label, NULL), ^(COActorChan * _Nonnull chan) {
            for (COActorMessage *message in chan) {
                NSInteger currentNum = message.uintType;
//                NSLog(@"^Thread%@ actor%d currentNum %d", [NSThread currentThread], i, currentNum);
                if ([weakSelf isPrimeNumber:currentNum]) {
                    [[weakSelf assembler] sendMessage:@"add"];
                }
                [[weakSelf counter] sendMessage:@"add"];
            }
        });
//        COActor *processer = co_actor_onqueue(dispatch_get_global_queue(0, 0), ^(COActorChan * _Nonnull chan) {
//            for (COActorMessage *message in chan) {
//                NSInteger currentNum = message.uintType;
//                if ([weakSelf isPrimeNumber:currentNum]) {
//                    [[weakSelf assembler] sendMessage:@"add"];
//                }
//                [[weakSelf counter] sendMessage:@"add"];
//            }
//        });

        [self.processers addObject:processer];
    }
}

- (BOOL)isPrimeNumber:(NSInteger)number {
    BOOL flag = YES;
    for (int i = 2;i < number;i++) {
        if (number % i == 0) {
            flag = NO;
            break;
        }
    }
    return flag;
}

- (void)startTask {
    [self.dispatcher sendMessage:@"start"];
}

@end
