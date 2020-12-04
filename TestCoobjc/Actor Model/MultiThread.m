//
//  MultiThread.m
//  TestCoobjc
//
//  Created by sidi wang on 2019/11/10.
//  Copyright © 2019 sidi wang. All rights reserved.
//

#import "MultiThread.h"

@interface MultiThread ()

@property (nonatomic, assign) NSInteger targetCount;

@property (nonatomic, assign) NSTimeInterval startTime;

@property (nonatomic, strong) NSLock *lock;

@end

@implementation MultiThread

- (instancetype)init
{
    self = [super init];
    if (self) {
        _targetCount = 0;
    }
    return self;
}

- (void)start {
    self.startTime = CFAbsoluteTimeGetCurrent();
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 15;
    self.lock = [[NSLock alloc] init];
    NSInteger number = 1;
    while (number <= 100000) {
        NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            if ([self isPrimeNumber:number]) {
                [self.lock lock];
                self.targetCount = self.targetCount + 1;
                [self.lock unlock];
            }
        }];
        [queue addOperation:operation];
        number ++;
    }
    [queue waitUntilAllOperationsAreFinished];
    NSLog(@"素数的个数:______%ld   耗时____%lf", self.targetCount, CFAbsoluteTimeGetCurrent() - self.startTime);

}

- (BOOL)isPrimeNumber:(NSInteger)number {
//    NSLog(@"%ld", number);
    BOOL flag = YES;
    for (int i = 2;i < number;i++) {
        if (number % i == 0) {
            flag = NO;
            break;
        }
    }
    return flag;
}

@end
