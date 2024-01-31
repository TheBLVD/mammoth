//
//  RCCTitleView.h
//  Mammoth
//
//  Created by Benoit Nolens on 31/01/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

// This class is taken from Wix ReactNativeNavigation
// It serves as a wrapper around custom RCTRootViews 

#import <UIKit/UIKit.h>
#import <React/RCTRootView.h>
#import <React/RCTRootViewDelegate.h>

@interface RCCCustomTitleView : UIView <RCTRootViewDelegate>

- (instancetype)initWithFrame:(CGRect)frame subView:(RCTRootView*)subView alignment:(NSString*)alignment;
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator;

@end
