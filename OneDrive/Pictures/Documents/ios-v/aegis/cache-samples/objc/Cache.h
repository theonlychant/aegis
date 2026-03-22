// Cache.h
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Cache : NSObject
- (instancetype)initWithCapacity:(NSUInteger)capacity;
- (void)put:(NSString*)key value:(NSString*)value;
- (nullable NSString*)get:(NSString*)key;
@end

NS_ASSUME_NONNULL_END
