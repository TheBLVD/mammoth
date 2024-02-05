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
@property (strong, nonatomic) MetaTextProvider *provider;
@end

@implementation MetaTextManager
@synthesize provider;

RCT_EXPORT_MODULE(NativeMetaText)

- (instancetype) init {
    self = [super init];
    provider = [MetaTextProvider new];
    return self;
}

- (UIView *)view {
    return [provider createMetaLabel];
}

- (dispatch_queue_t)methodQueue {
    return dispatch_get_main_queue();
}

RCT_CUSTOM_VIEW_PROPERTY(emojis, NSArray, MetaTextProvider) {
    [provider setEmojis: json];
}

RCT_EXPORT_METHOD(onTextChange:(nonnull NSNumber*) reactTag) {
    [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
        UITextView * view = (UITextView *)viewRegistry[reactTag];
        if (!view || ![view isKindOfClass:[UITextView class]]) {
            RCTLogError(@"Cannot find UITextView with tag #%@", reactTag);
            return;
        }
        
        CGFloat width = CGRectGetWidth(view.frame);
        CGSize fittingSize = UILayoutFittingCompressedSize;
        fittingSize.width = width;
        
        CGFloat height = [view systemLayoutSizeFittingSize: fittingSize].height;
        [self.bridge.uiManager setIntrinsicContentSize: CGSizeMake(UIViewNoIntrinsicMetric, height) forView: view];
    }];
};

@end
