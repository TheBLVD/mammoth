//
//  NavigationEventEmitter.m
//  Mammoth
//
//  Created by Benoit Nolens on 31/01/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

#import "NavigationEventEmitter.h"
#import "Mammoth-Swift.h"

#define NAVIGATION_EVENT @"NAVIGATION_EVENT"

@implementation NavigationEventEmitter

static NavigationEventEmitter *_globalNavigationEmitter = nil;

RCT_EXPORT_MODULE();

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

// Since the majority of work is UIKit work, main thread is required.
- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

+ (NavigationEventEmitter *)globalNavigationEmitter
{
    return _globalNavigationEmitter;
}

- (instancetype)init
{
    if (self = [super init]) {
        _globalNavigationEmitter = self;
        [self setBridge:[[ReactBridge shared] bridge]];
    }
    return self;
}

- (void)publishEvent:(NSDictionary *)event
{
    [self sendEventWithName:NAVIGATION_EVENT body:event];
}

- (void)publishScreenChangeEvent:(ScreenChangeEvent)event rootTag:(nonnull NSNumber *)rootTag
{
    [self publishEvent:@{
                         @"type": @"ScreenChangedEvent",
                         @"_reactTag": rootTag,
                         @"id": [self stringValue:event],
                         }];
}

- (NSArray<NSString *> *)supportedEvents {
    return @[NAVIGATION_EVENT];
}

- (NSString*)stringValue:(ScreenChangeEvent)event {
    switch(event) {
        case ScreenChangeEventViewWillAppear:
            return @"willAppear";
        case ScreenChangeEventViewDidAppear:
            return @"didAppear";
        case ScreenChangeEventViewWillDisappear:
            return @"willDisappear";
        case ScreenChangeEventViewDidDisappear:
            return @"didDisappear";
    }
}

@end
