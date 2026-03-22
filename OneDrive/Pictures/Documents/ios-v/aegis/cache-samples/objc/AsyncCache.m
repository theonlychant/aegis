// AsyncCache.m
#import "AsyncCache.h"

@interface AsyncCache () {
    NSMutableDictionary<NSString*,NSString*> *store;
    AsyncLoadBlock loader;
    dispatch_queue_t q;
}
@end

@implementation AsyncCache
- (instancetype)initWithLoader:(AsyncLoadBlock)ldr {
    if (self = [super init]){
        store = [NSMutableDictionary dictionary];
        loader = [ldr copy];
        q = dispatch_queue_create("com.example.asynccache", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}
- (void)get:(NSString*)key completion:(void(^)(NSString* _Nullable value))completion {
    NSString *v = store[key];
    if (v) { completion(v); return; }
    // load asynchronously
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0), ^{
        loader(key, ^(NSString *value){
            if (value) store[key]=value;
            dispatch_async(dispatch_get_main_queue(), ^{ completion(value); });
        });
    });
}
- (void)put:(NSString*)key value:(NSString*)value { store[key]=value; }

// demo main
int main(int argc, const char * argv[]){
    @autoreleasepool {
        AsyncLoadBlock l = ^(NSString *k, void (^cb)(NSString *)){
            // simulate work
            [NSThread sleepForTimeInterval:0.2];
            cb([NSString stringWithFormat:@"loaded-%@", k]);
        };
        AsyncCache *ac = [[AsyncCache alloc] initWithLoader:l];
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        [ac get:@"x" completion:^(NSString * _Nullable value) { NSLog(@"got %@", value); dispatch_semaphore_signal(sem); }];
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    }
    return 0;
}

@end
