//
//  LSApplicationWorkspace.h
//  XXTExplorer
//
//  Created by Zheng on 01/07/2017.
//  Copyright © 2017 Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LSApplicationWorkspace : NSObject

- (BOOL)openApplicationWithBundleID:(NSString *)bundleID;

@end
