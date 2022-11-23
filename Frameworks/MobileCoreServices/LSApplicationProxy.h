/* Generated by RuntimeBrowser
   Image: /System/Library/Frameworks/MobileCoreServices.framework/MobileCoreServices
 https://github.com/nst/iOS-Runtime-Headers/tree/master/Frameworks/MobileCoreServices.framework
 
 
 */

#import "LSBundleProxy.h"

@class LSApplicationProxy, NSArray, NSDictionary, NSNumber, NSProgress, NSString, NSUUID;

@interface LSApplicationProxy : LSBundleProxy <NSSecureCoding> {
    NSArray *_UIBackgroundModes;
    NSArray *_VPNPlugins;
    NSArray *_appTags;
    NSString *_applicationDSID;
    NSArray *_audioComponents;
    NSArray *_deviceFamily;
    NSArray *_directionsModes;
    NSNumber *_dynamicDiskUsage;
    NSArray *_externalAccessoryProtocols;
    unsigned int _flags;
    NSDictionary *_groupContainers;
    NSArray *_groupIdentifiers;
    unsigned int _installType;
    BOOL _isContainerized;
    NSNumber *_itemID;
    NSString *_itemName;
    NSString *_minimumSystemVersion;
    long _modTime;
    unsigned int _originalInstallType;
    NSArray *_plugInKitPlugins;
    NSArray *_pluginUUIDs;
    NSArray *_privateDocumentIconNames;
    LSApplicationProxy *_privateDocumentTypeOwner;
    NSArray *_requiredDeviceCapabilities;
    NSString *_sdkVersion;
    NSString *_shortVersionString;
    NSNumber *_staticDiskUsage;
    NSString *_storeCohortMetadata;
    NSNumber *_storeFront;
    NSString *_teamID;
    NSString *_vendorName;
}

@property(readonly) NSArray * UIBackgroundModes;
@property(readonly) NSArray * VPNPlugins;
@property(readonly) NSArray * appTags;
@property(readonly) NSString * applicationDSID;
@property(readonly) NSString * applicationIdentifier;
@property(readonly) NSString * applicationType;
@property(readonly) NSArray * audioComponents;
@property(readonly) NSString * bundleVersion;
@property(readonly) NSArray * deviceFamily;
@property(readonly) NSUUID * deviceIdentifierForVendor;
@property(readonly) NSArray * directionsModes;
@property(readonly) NSNumber * dynamicDiskUsage;
@property(readonly) NSArray * externalAccessoryProtocols;
@property(readonly) BOOL fileSharingEnabled;
@property(readonly) NSDictionary * groupContainers;
@property(readonly) NSArray * groupIdentifiers;
@property(readonly) BOOL hasSettingsBundle;
@property(readonly) BOOL iconIsPrerendered;
@property(readonly) NSProgress * installProgress;
@property(readonly) unsigned int installType;
@property(readonly) BOOL isAppUpdate;
@property(readonly) BOOL isBetaApp;
@property(readonly) BOOL isContainerized;
@property(readonly) BOOL isInstalled;
@property(readonly) BOOL isNewsstandApp;
@property(readonly) BOOL isPlaceholder;
@property(readonly) BOOL isPurchasedReDownload;
@property(readonly) BOOL isRestricted;
@property(readonly) NSNumber * itemID;
@property(readonly) NSString * itemName;
@property(readonly) NSString * minimumSystemVersion;
@property(readonly) unsigned int originalInstallType;
@property(readonly) NSArray * plugInKitPlugins;
@property(readonly) BOOL profileValidated;
@property(readonly) NSArray * requiredDeviceCapabilities;
@property(readonly) NSString * sdkVersion;
@property(readonly) NSString * shortVersionString;
@property(readonly) NSNumber * staticDiskUsage;
@property(readonly) NSString * storeCohortMetadata;
@property(readonly) NSNumber * storeFront;
@property(readonly) BOOL supportsAudiobooks;
@property(readonly) BOOL supportsExternallyPlayableContent;
@property(readonly) NSString * teamID;
@property(readonly) NSString * vendorName;

+ (id)applicationProxyForBundleURL:(id)arg1;
+ (id)applicationProxyForIdentifier:(id)arg1 placeholder:(BOOL)arg2;
+ (id)applicationProxyForIdentifier:(id)arg1;
+ (id)applicationProxyForItemID:(id)arg1;
+ (id)applicationProxyWithBundleUnitID:(unsigned long)arg1;
+ (BOOL)supportsSecureCoding;

- (id)UIBackgroundModes;
- (id)VPNPlugins;
- (id)_initWithBundleUnit:(unsigned long)arg1 applicationIdentifier:(id)arg2;
- (id)appStoreReceiptURL;
- (id)appTags;
- (id)applicationDSID;
- (id)applicationIdentifier;
- (id)applicationType;
- (id)audioComponents;
- (long)bundleModTime;
- (void)dealloc;
- (id)description;
- (id)deviceFamily;
- (id)deviceIdentifierForVendor;
- (id)directionsModes;
- (id)dynamicDiskUsage;
- (void)encodeWithCoder:(id)arg1;
- (id)externalAccessoryProtocols;
- (BOOL)fileSharingEnabled;
- (id)groupContainers;
- (id)groupIdentifiers;
- (BOOL)hasSettingsBundle;
- (unsigned int)hash;
- (id)iconDataForVariant:(int)arg1;
- (BOOL)iconIsPrerendered;
- (id)iconStyleDomain;
- (id)initWithCoder:(id)arg1;
- (id)installProgress;
- (id)installProgressSync;
- (unsigned int)installType;
- (BOOL)isAppUpdate;
- (BOOL)isBetaApp;
- (BOOL)isContainerized;
- (BOOL)isEqual:(id)arg1;
- (BOOL)isInstalled;
- (BOOL)isNewsstandApp;
- (BOOL)isPlaceholder;
- (BOOL)isPurchasedReDownload;
- (BOOL)isRestricted;
- (id)itemID;
- (id)itemName;
- (id)localizedName;
- (id)localizedShortName;
- (id)machOUUIDs;
- (id)minimumSystemVersion;
- (unsigned int)originalInstallType;
- (id)plugInKitPlugins;
- (BOOL)privateDocumentIconAllowOverride;
- (id)privateDocumentIconNames;
- (id)privateDocumentTypeOwner;
- (BOOL)profileValidated;
- (id)requiredDeviceCapabilities;
- (id)resourcesDirectoryURL;
- (id)sdkVersion;
- (void)setPrivateDocumentIconAllowOverride:(BOOL)arg1;
- (void)setPrivateDocumentIconNames:(id)arg1;
- (void)setPrivateDocumentTypeOwner:(id)arg1;
- (id)shortVersionString;
- (id)staticDiskUsage;
- (id)storeCohortMetadata;
- (id)storeFront;
- (BOOL)supportsAudiobooks;
- (BOOL)supportsExternallyPlayableContent;
- (id)teamID;
- (id)userActivityStringForAdvertisementData:(id)arg1;
- (id)vendorName;

@end
