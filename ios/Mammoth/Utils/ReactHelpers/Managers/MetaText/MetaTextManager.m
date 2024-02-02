//
//  MetaTextManager.m
//  Mammoth
//
//  Created by Benoit Nolens on 02/02/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTViewManager.h>
#import <React/RCTUIManager.h>
#import <React/RCTLog.h>
#import "Mammoth-Swift.h"

@import MetaTextKit;

@interface MetaTextManager : RCTViewManager

@property (strong, nonatomic) Helpers *helper;

@end

@implementation MetaTextManager

@synthesize helper;

RCT_EXPORT_MODULE(NativeMetaText)

- (UIView *)view {
    helper = [Helpers new];
    return [helper createMetaLabel];
}

- (dispatch_queue_t)methodQueue {
    return dispatch_get_main_queue();
}

@end
