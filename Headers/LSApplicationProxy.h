#ifndef LSApplicationProxy_h
#define LSApplicationProxy_h

#import <UIKit/UIKit.h>

@class LSApplicationRecord;

@interface LSApplicationProxy : NSObject

+ (LSApplicationProxy *)applicationProxyForIdentifier:(NSString *)bid;
- (NSData *)iconDataForVariant:(int)arg1;
- (NSString *)itemName;
- (NSString *)localizedName;
- (NSString *)shortVersionString;
- (NSString *)applicationType;
- (NSURL *)bundleURL;
- (NSURL *)dataContainerURL;
- (NSDictionary <NSString *, NSURL *> *)groupContainerURLs;

@property (nonatomic, readonly, copy) NSString *applicationIdentifier;
@property (nonatomic, readonly, strong) LSApplicationRecord *correspondingApplicationRecord;

@end

#endif /* LSApplicationProxy_h */
