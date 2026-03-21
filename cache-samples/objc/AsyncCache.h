// AsyncCache.h
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^AsyncLoadBlock)(NSString *key, void (^completion)(NSString *value));

@interface AsyncCache : NSObject
- (instancetype)initWithLoader:(AsyncLoadBlock)loader;
- (void)get:(NSString*)key completion:(void(^)(NSString* _Nullable value))completion;
- (void)put:(NSString*)key value:(NSString*)value;
@end

NS_ASSUME_NONNULL_END
