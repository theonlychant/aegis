// Cache.m
#import "Cache.h"

@interface Cache () {
    NSUInteger capacity;
    NSMutableArray<NSString*> *order;
    NSMutableDictionary<NSString*,NSString*> *store;
}
@end

@implementation Cache
- (instancetype)initWithCapacity:(NSUInteger)c {
    if (self = [super init]) {
        capacity = c;
        order = [NSMutableArray array];
        store = [NSMutableDictionary dictionary];
    }
    return self;
}
- (void)put:(NSString*)key value:(NSString*)value {
    if (!store[key]) {
        [order insertObject:key atIndex:0];
    } else {
        [order removeObject:key];
        [order insertObject:key atIndex:0];
    }
    store[key] = value;
    if (order.count > capacity) {
        NSString *old = [order lastObject];
        [order removeLastObject];
        [store removeObjectForKey:old];
    }
}
- (NSString*)get:(NSString*)key {
    NSString *v = store[key];
    if (v) {
        [order removeObject:key];
        [order insertObject:key atIndex:0];
    }
    return v;
}

// simple demo when run as a standalone obj-c program
int main(int argc, const char * argv[]){
    @autoreleasepool {
        Cache *c = [[Cache alloc] initWithCapacity:3];
        [c put:@"a" value:@"1"]; [c put:@"b" value:@"2"]; [c put:@"c" value:@"3"];
        NSLog(@"get b=%@", [c get:@"b"]);
        [c put:@"d" value:@"4"]; // evicts a
        NSLog(@"get a=%@", [c get:@"a"]);
    }
    return 0;
}

@end
