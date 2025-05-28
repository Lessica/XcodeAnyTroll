#ifndef LSRecordPromise_h
#define LSRecordPromise_h

#import <Foundation/Foundation.h>

@class LSApplicationRecord;

@interface LSRecordPromise : NSObject

- (instancetype)initWithRecord:(LSApplicationRecord *)arg1 error:(NSError **)arg2;

@end

#endif /* LSRecordPromise_h */
