//
//  UIColor+Hex.h
//  Mammoth
//
//  Created by Benoit Nolens on 31/01/2024
//  Copyright © 2024 The BLVD. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  Taken from: https://github.com/thisandagain/color/tree/master/EDColor
 *  Unbundled to fit into our framework
 */
@interface UIColor (Hex)

+ (UIColor *)colorWithHex:(UInt32)hex andAlpha:(CGFloat)alpha;

+ (UIColor *)colorWithHex:(UInt32)hex;

+ (UIColor *)colorWithHexString:(id)input;

- (UInt32)hexValue;

@end
