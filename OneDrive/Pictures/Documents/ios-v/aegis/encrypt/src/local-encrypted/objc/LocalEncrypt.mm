#import "LocalEncrypt.h"
#include "../c_bridge/bridge.h"

@implementation LocalEncrypt

- (nullable NSData*)encryptData:(NSData*)data key:(NSData*)key nonce:(NSData*)nonce error:(NSError **)error {
    size_t out_len = 0, tag_len = 0;
    // first, query sizes
    int rc = aegis_encrypt((const uint8_t*)data.bytes, data.length, nullptr, &out_len, nullptr, &tag_len,
                           (const uint8_t*)key.bytes, key.length,
                           (const uint8_t*)nonce.bytes, nonce.length);
    if(rc != 0) {
        if(error) *error = [NSError errorWithDomain:@"AegisEncrypt" code:rc userInfo:@{NSLocalizedDescriptionKey: @"encrypt size query failed"}];
        return nil;
    }
    NSMutableData *out = [NSMutableData dataWithLength:out_len];
    NSMutableData *tag = [NSMutableData dataWithLength:tag_len];
    rc = aegis_encrypt((const uint8_t*)data.bytes, data.length, out.mutableBytes, &out_len, tag.mutableBytes, &tag_len,
                       (const uint8_t*)key.bytes, key.length,
                       (const uint8_t*)nonce.bytes, nonce.length);
    if(rc != 0) {
        if(error) *error = [NSError errorWithDomain:@"AegisEncrypt" code:rc userInfo:@{NSLocalizedDescriptionKey: @"encrypt failed"}];
        return nil;
    }
    // Return ciphertext || tag concatenated; caller may separate
    NSMutableData *result = [NSMutableData dataWithData:out];
    [result appendData:tag];
    return result;
}

- (nullable NSData*)decryptData:(NSData*)ciphertext tag:(NSData*)tag key:(NSData*)key nonce:(NSData*)nonce error:(NSError **)error {
    size_t out_len = 0;
    int rc = aegis_decrypt((const uint8_t*)ciphertext.bytes, ciphertext.length,
                            (const uint8_t*)tag.bytes, tag.length,
                            nullptr, &out_len,
                            (const uint8_t*)key.bytes, key.length,
                            (const uint8_t*)nonce.bytes, nonce.length);
    if(rc != 0) {
        if(error) *error = [NSError errorWithDomain:@"AegisEncrypt" code:rc userInfo:@{NSLocalizedDescriptionKey: @"decrypt size query failed"}];
        return nil;
    }
    NSMutableData *out = [NSMutableData dataWithLength:out_len];
    rc = aegis_decrypt((const uint8_t*)ciphertext.bytes, ciphertext.length,
                       (const uint8_t*)tag.bytes, tag.length,
                       out.mutableBytes, &out_len,
                       (const uint8_t*)key.bytes, key.length,
                       (const uint8_t*)nonce.bytes, nonce.length);
    if(rc != 0) {
        if(error) *error = [NSError errorWithDomain:@"AegisEncrypt" code:rc userInfo:@{NSLocalizedDescriptionKey: @"decrypt failed"}];
        return nil;
    }
    return [NSData dataWithData:out];
}

@end
