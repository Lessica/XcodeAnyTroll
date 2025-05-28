//
//  LSApplicationProxy.h
//  XXTPickerCollection
//
//  Created by Zheng on 03/05/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#ifndef LSApplicationProxy_h
#define LSApplicationProxy_h

#import <UIKit/UIKit.h>

@interface LSApplicationProxy : NSObject

+ (LSApplicationProxy *)applicationProxyForIdentifier:(NSString *)bid;
- (NSData *)iconDataForVariant:(int)arg1;
- (NSString *)itemName;
- (NSString *)localizedName;
- (NSString *)shortVersionString;
- (NSString *)applicationType;
- (NSURL *)bundleURL;
//- (NSURL *)bundleContainerURL;
- (NSURL *)dataContainerURL;
- (NSDictionary <NSString *, NSURL *> *)groupContainerURLs;

@property (nonatomic, readonly, copy) NSString *applicationIdentifier;

@end

#endif /* LSApplicationProxy_h */
