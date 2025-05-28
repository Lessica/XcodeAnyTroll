#ifndef MCMContainer_h
#define MCMContainer_h

#import <Foundation/Foundation.h>

@interface MCMContainer : NSObject

@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSURL *url;

+ (instancetype)containerWithIdentifier:(id)arg1 error:(id*)arg2;
- (NSURL *)url;

@end

@interface MCMAppContainer : MCMContainer
@end

@interface MCMAppDataContainer : MCMContainer
@end

#endif /* MCMContainer_h */
