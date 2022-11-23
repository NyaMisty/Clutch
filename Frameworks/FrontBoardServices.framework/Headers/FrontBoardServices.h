#pragma once

#ifdef __cplusplus
extern "C"{
#endif

#include "FBSSystemService.h"

typedef long FBSOpenApplicationErrorCode;
enum {
	FBSOpenApplicationErrorCodeNone=0,
};

#ifdef __OBJC__
NSString* FBSOpenApplicationErrorCodeToString(FBSOpenApplicationErrorCode code);

extern NSString* FBSActivateForEventOptionTypeBackgroundContentFetching;
extern NSString* FBSOpenApplicationOptionKeyActivateForEvent;
extern NSString* FBSDebugOptionKeyArguments;
extern NSString* FBSDebugOptionKeyEnvironment;
extern NSString* FBSDebugOptionKeyStandardOutPath;
extern NSString* FBSDebugOptionKeyStandardErrorPath;
extern NSString* FBSDebugOptionKeyWaitForDebugger;
extern NSString* FBSDebugOptionKeyDisableASLR;
extern NSString* FBSOpenApplicationOptionKeyDebuggingOptions;
extern NSString* FBSOpenApplicationOptionKeyUnlockDevice;
extern NSString* FBSDebugOptionKeyStandardOutPath;
extern NSString* FBSDebugOptionKeyStandardErrorPath;
extern NSString* FBSDebugOptionKeyWaitForDebugger;
extern NSString* FBSOpenApplicationOptionKeyDebuggingOptions;
extern NSString* FBSOpenApplicationOptionKeyLSSequenceNumber;
extern NSString* FBSOpenApplicationOptionKeyLSCacheGUID;
extern NSString* FBSDebugOptionKeyDebugOnNextLaunch;
extern NSString* FBSDebugOptionKeyCancelDebugOnNextLaunch;
extern NSString* FBSOpenApplicationOptionKeyActivateSuspended;

#endif

#ifdef __cplusplus
}
#endif
