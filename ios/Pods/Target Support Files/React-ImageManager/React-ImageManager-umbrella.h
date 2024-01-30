#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "react/renderer/imagemanager/RCTImageManager.h"
#import "react/renderer/imagemanager/RCTImageManagerProtocol.h"
#import "react/renderer/imagemanager/RCTImagePrimitivesConversions.h"
#import "react/renderer/imagemanager/RCTSyncImageManager.h"

FOUNDATION_EXPORT double React_ImageManagerVersionNumber;
FOUNDATION_EXPORT const unsigned char React_ImageManagerVersionString[];

