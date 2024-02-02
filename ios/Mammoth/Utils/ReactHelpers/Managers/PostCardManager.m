//
//  PostCardManager.m
//  Mammoth
//
//  Created by Benoit Nolens on 01/02/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

#import <React/RCTViewManager.h>
#import <React/RCTUIManager.h>
#import <React/RCTLog.h>
#import "Mammoth-Swift.h"

@interface PostCardManager : RCTViewManager
@end

@implementation PostCardManager

RCT_EXPORT_MODULE(NativePostCardView)

- (UIView *)view {
    return [PostCardView new];
}

- (dispatch_queue_t)methodQueue {
    return dispatch_get_main_queue();
}

RCT_EXPORT_METHOD(configure:(nonnull NSNumber*) reactTag text:(NSString *)text) {
    [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
        PostCardView * view = (PostCardView *)viewRegistry[reactTag];
        if (!view || ![view isKindOfClass:[PostCardView class]]) {
            RCTLogError(@"Cannot find PostCardView with tag #%@", reactTag);
            return;
        }
        [view configureWithText: text];
        [self.bridge.uiManager setIntrinsicContentSize: CGSizeMake(UIViewNoIntrinsicMetric, view.viewHeight) forView: view];
    }];
};

@end
