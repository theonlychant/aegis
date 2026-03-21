@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface LocalEncrypt : NSObject

- (nullable NSData*)encryptData:(NSData*)data
                             key:(NSData*)key
                           nonce:(NSData*)nonce
                           error:(NSError* _Nullable * _Nullable)error;

- (nullable NSData*)decryptData:(NSData*)ciphertext
                             tag:(NSData*)tag
                             key:(NSData*)key
                           nonce:(NSData*)nonce
                           error:(NSError* _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
