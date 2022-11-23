#pragma once
#ifdef __cplusplus
extern "C"{
#endif

#include "AssertionServicesSPI.h"
#include "BKSSystemService.h"

typedef long BKSOpenApplicationErrorCode;
enum{
	BKSOpenApplicationErrorCodeNone = 0,
};

#ifdef __OBJC__
NSString* BKSOpenApplicationErrorCodeToString(BKSOpenApplicationErrorCode code);

extern NSString* BKSActivateForEventOptionTypeBackgroundContentFetching;
extern NSString* BKSDebugOptionKeyArguments;
extern NSString* BKSDebugOptionKeyEnvironment;
extern NSString* BKSDebugOptionKeyStandardOutPath;
extern NSString* BKSDebugOptionKeyStandardErrorPath;
extern NSString* BKSDebugOptionKeyWaitForDebugger;
extern NSString* BKSDebugOptionKeyDisableASLR;
extern NSString* BKSOpenApplicationOptionKeyDebuggingOptions;
extern NSString* BKSOpenApplicationOptionKeyUnlockDevice;
extern NSString* BKSOpenApplicationOptionKeyActivateForEvent;
extern NSString* BKSDebugOptionKeyDebugOnNextLaunch;
extern NSString* BKSDebugOptionKeyCancelDebugOnNextLaunch;
extern NSString* BKSOpenApplicationOptionKeyActivateSuspended;

#endif

//BKSSystemService;

typedef struct __BKSWatchdogAssertion* BKSWatchdogAssertionRef;

CFTypeID BKSWatchdogAssertionGetTypeID(void);
void BKSWatchdogAssertionCancel(BKSWatchdogAssertionRef assertion);
BKSWatchdogAssertionRef BKSWatchdogAssertionCreateForPID(CFAllocatorRef allocator, pid_t pid);
int BKSWatchdogAssertionRenew(BKSWatchdogAssertionRef assertion);
CFTimeInterval BKSWatchdogAssertionGetRenewalInterval(BKSWatchdogAssertionRef assertion);

#ifdef __cplusplus
}
#endif
