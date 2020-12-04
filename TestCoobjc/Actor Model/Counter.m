//
//  Counter.m
//  TestCoobjc
//
//  Created by sidi wang on 2019/11/28.
//  Copyright © 2019 sidi wang. All rights reserved.
//

#import "Counter.h"

@interface Counter ()

@property (nonatomic, assign) int count;

@end

@implementation Counter

- (void)incCount {
    _count ++;
}

- (int)getCount {
    return _count;
}

@end
