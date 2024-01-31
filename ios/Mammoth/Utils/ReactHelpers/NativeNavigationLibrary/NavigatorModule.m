//
//  NavigatorModule.m
//  Mammoth
//
//  Created by Benoit Nolens on 31/01/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

#import "Mammoth-Swift.h"
#import <React/RCTBridge.h>
#import <React/RCTUIManager.h>
#import <React/UIView+React.h>
#import <React/RCTRootView.h>
#import <React/RCTBridgeModule.h>

@import Foundation;

@interface Navigator : NSObject<RCTBridgeModule>
@property (nonnull, nonatomic, strong) NavigationRegistry *navigationRegistry;
@property (nonnull, nonatomic, copy) NSMutableArray<RCTResponseSenderBlock> *contentAppearedCallbacks;
@end


@implementation Navigator

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

// Since the majority of work is UIKit work, main thread is required.
- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

- (instancetype)init
{
    if (self = [super init]) {
        _navigationRegistry = [[NavigationRegistry alloc] init];
        _contentAppearedCallbacks = [NSMutableArray array];
        [self startObservers];
    }
    return self;
}

//See the invocation `updatedView` below for documentation.
- (void)startObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(rootViewEnteredHierarchy:)
                                                 name:RCTContentDidAppearNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRNReload:)
                                                 name:RCTBridgeWillReloadNotification
                                               object:nil];
}


- (void)stopObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RCTContentDidAppearNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RCTBridgeWillReloadNotification object:nil];
}

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

- (void)dealloc
{
    [self stopObservers];
}

- (void)handleRNReload:(NSNotification *)note
{
    [_navigationRegistry _resetNavigation];
    _navigationRegistry = [[NavigationRegistry alloc] init];
    _contentAppearedCallbacks = [NSMutableArray array];
}

/**
 * Observing RCTContentDidAppearNotification is the only way to know when the content rendered in
 * the JS component has been added to the view hierarcy. `componentDidMount()` fires before the content has
 * been added to the hierarcy so it is not a reliable way to know when the UIView is in the hierarchy.
 * This is neccessary in order to properly obtain a references to the current Screen's ViewController, and thus it's NavigationController.
 * The view/viewcontroller is identified as belonging to this Navigator by the reactTag of the *RCTRootView*.
 * In our navigation stack, there is *only one* RCTRootView per UIViewController (ReactViewController).
 */
- (void)rootViewEnteredHierarchy:(NSNotification *)note
{
    RCTRootView *rootView = note.object;
    if ([rootView isKindOfClass:[RCTRootView class]]) {
        //Fire callbacks registered by JS. This let's JS know that we can now access
        //the UIViewController and apply props to it.
        for (RCTResponseSenderBlock callback in self.contentAppearedCallbacks) {
            callback(@[[NSNull null]]);
        }
        [self.contentAppearedCallbacks removeAllObjects];
    }
}

- (UIView *)getRootViewForReactTag:(NSNumber *)reactTag {
    UIView *originatingView = [self.bridge.uiManager viewForReactTag:reactTag];
    UIView *rootView = originatingView;
    while (rootView.superview && ![rootView isKindOfClass:RCTRootView.class]) {
        rootView = rootView.superview;
    }
    return rootView;
}

- (NavigationManager *)getManagerForReactTag:(NSNumber *)reactTag {
    UIView *rootView = [self getRootViewForReactTag:reactTag];
    return [self.navigationRegistry navigationManagerForTag:[rootView.reactTag integerValue]];
}

/* Navigator.js add's a callback/subscriber to be notified when the RCTRootView _actually_ enter's
 * the view hierarchy, and thus has a ViewController that we can apply props to (like title), and
 * use it's .navigationController to push/pop.
*/
RCT_EXPORT_METHOD(onRootViewEnteredHierarchy:(RCTResponseSenderBlock) callback)
{
    [self.contentAppearedCallbacks addObject:callback];
}

/**
 * Attempt to find the RCTRootView. It is the top most view inside the viewcontroller.
 * It contains all other ReactNative subviews.
 * There is only 1 RCTRootView per 'ReactViewController',
 * and it cannot be modified from within React/JS, so we want to ensure we
 * only use this view's reactTag to identify our managers. Once we get this tag, register i
 * to the navigationRegistry which creates or updates a NavigationManager with the supplied tag.
 * eg. `reactTag` passed into this method is 15, and corresponds to a subview within the
 * viewcontroller (typically this is the first view rendered within the `render` function.
 * We want to traverse up the view hierarchy until we find the RCTRootView, and use THAT
 * root view's tag in order to identify the navigation manager. The initial view with tag 15
 * is subject to change at any point within the render method, and this is not a
 * reliable way to identify the managers
 */
RCT_EXPORT_METHOD(registerRootView:(nonnull NSNumber *)reactTag route:(NSDictionary *)route)
{
    NavigatorRoute *navRoute = [[NavigatorRoute alloc] initWithDictionary: route];
    // Ensure we find the root RCTRootView and use it's tag, not the tag passed into this method.
    UIView *rootView = [self getRootViewForReactTag:reactTag];
    UIViewController *viewController = rootView.reactViewController;
    if (viewController) {
        [self.navigationRegistry updateWithTag:[rootView.reactTag integerValue] route:navRoute viewController:viewController];
    }
}

RCT_EXPORT_METHOD(unregisterRootView:(nonnull NSNumber *)reactTag)
{
    NSNumber *rootTag = [self getRootViewForReactTag:reactTag].reactTag;
    [self.navigationRegistry removeWithTag:[rootTag integerValue]];
}

RCT_EXPORT_METHOD(push:(nonnull NSDictionary *)route fromReactTag:(nonnull NSNumber *)fromReactTag)
{
    // Setup new viewcontroller to push
    ReactViewController *vc = [self createViewControllerForNavigatorFromRoute: route];
    
    UIView *rootView = [self getRootViewForReactTag:fromReactTag];
    NavigationManager *manager = [self.navigationRegistry navigationManagerForTag:[rootView.reactTag integerValue]];
    UINavigationController *navController = manager.viewController.navigationController;
    if (navController) {
        [navController pushViewController:vc animated:YES];
    }
}

RCT_EXPORT_METHOD(pop:(nonnull NSNumber *)animated fromReactTag:(nonnull NSNumber *)fromReactTag)
{
    UIView *rootView = [self getRootViewForReactTag:fromReactTag];
    NavigationManager *manager = [self.navigationRegistry navigationManagerForTag:[rootView.reactTag integerValue]];
    UINavigationController *navController = manager.viewController.navigationController;
    if (navController) {
        [navController popViewControllerAnimated:[animated boolValue]];
    }
}

RCT_EXPORT_METHOD(present:(nonnull NSDictionary *)route fromReactTag:(nonnull NSNumber *)fromReactTag)
{
    // Setup new viewcontroller to present
    ReactViewController *newVC = [self createViewControllerForNavigatorFromRoute: route];
    NavigationManager *presentedManager = [self.navigationRegistry navigationManagerForTag:newVC.reactTag.integerValue];

    // Presenting ViewController
    NSInteger rootViewTag = [[[self getRootViewForReactTag:fromReactTag] reactTag] integerValue];
    NavigationManager *manager = [self.navigationRegistry navigationManagerForTag:rootViewTag];
    
    UIViewController *presentingVC = manager.viewController;
    if (presentingVC) {
        UINavigationController *presentedNavController = [[UINavigationController alloc] initWithRootViewController:newVC];
        if ([[presentedManager route] objc_useTransparentBackground] == YES) {
            presentedNavController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        }
        [presentingVC presentViewController:presentedNavController animated:YES completion:nil];
    }
}

RCT_EXPORT_METHOD(getBottomEdgeInsetFromReactTag:(nonnull NSNumber *)fromReactTag callback:(RCTResponseSenderBlock)callback)
{
    NSInteger rootViewTag = [[[self getRootViewForReactTag:fromReactTag] reactTag] integerValue];
    NavigationManager *manager = [self.navigationRegistry navigationManagerForTag:rootViewTag];
    ReactViewController *viewController = manager.viewController;
    
    if (viewController) {
        if (@available(iOS 11.0, *)) {
            callback(@[@{@"bottomInset": @(viewController.view.safeAreaInsets.bottom)}]);
        } else {
            callback(@[@{@"bottomInset": @(0)}]);
        }
    }
}

RCT_EXPORT_METHOD(dismissFromReactTag:(nonnull NSNumber *)fromReactTag)
{
    NSInteger rootViewTag = [[[self getRootViewForReactTag:fromReactTag] reactTag] integerValue];
    NavigationManager *manager = [self.navigationRegistry navigationManagerForTag:rootViewTag];
    UIViewController *presentingVC = manager.viewController;
    if (presentingVC) {
        [presentingVC dismissViewControllerAnimated:true completion:nil];
    }
}

- (ReactViewController *)createViewControllerForNavigatorFromRoute:(NSDictionary *)route
{
    NavigatorRoute *navRoute = [[NavigatorRoute alloc] initWithDictionary: route];    
    ReactViewController *vc = [[ReactViewController alloc] initWithModuleName:navRoute.routeId initialProperties:route];
    [self.navigationRegistry updateWithTag:[vc.reactTag integerValue] route:navRoute viewController:vc];
    return vc;
}

@end


