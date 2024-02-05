//
//  ReactNativeEventEmitter.m
//  Mammoth
//
//  Created by Benoit Nolens on 05/02/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

//
//  ReactNativeEventEmitter.m
// See: http://facebook.github.io/react-native/releases/0.43/docs/native-modules-ios.html#exporting-swift
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(ReactNativeEventEmitter, RCTEventEmitter)

RCT_EXTERN_METHOD(supportedEvents)

@end
