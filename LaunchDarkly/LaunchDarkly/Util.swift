import Foundation
#if os(Windows)
import WinSDK
#else
import CommonCrypto
#endif

class Util {
    internal static let validKindCharacterSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-")
    internal static let validTagCharacterSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-")

    class func sha256base64(_ str: String) -> String {
        sha256(str).base64EncodedString()
    }

    class func sha256(_ str: String) -> Data {
        let data = Data(str.utf8)
        #if os(Windows)
        return data.sha256Digest
        #else
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &digest)
        }
        return Data(digest)
        #endif
    }
}

#if os(Windows)
private extension Data {
    var sha256Digest: Data {
        func check(_ status: NTSTATUS) {
            precondition(status >= 0, "BCrypt SHA-256 failed")
        }

        var algorithm: BCRYPT_ALG_HANDLE?
        "SHA256".withCString(encodedAs: UTF16.self) {
            check(BCryptOpenAlgorithmProvider(&algorithm, $0, nil, 0))
        }
        defer { check(BCryptCloseAlgorithmProvider(algorithm, 0)) }

        var hash: BCRYPT_HASH_HANDLE?
        check(BCryptCreateHash(algorithm, &hash, nil, 0, nil, 0, 0))
        defer { check(BCryptDestroyHash(hash)) }

        withUnsafeBytes { input in
            let bytes = UnsafeMutablePointer(mutating: input.baseAddress?.assumingMemoryBound(to: UInt8.self))
            check(BCryptHashData(hash, bytes, ULONG(input.count), 0))
        }

        var digest = Data(count: 32)
        digest.withUnsafeMutableBytes { output in
            let bytes = output.baseAddress?.assumingMemoryBound(to: UInt8.self)
            check(BCryptFinishHash(hash, bytes, ULONG(output.count), 0))
        }
        return digest
    }
}
#endif

extension String {
    func onlyContainsCharset(_ set: CharacterSet) -> Bool {
        if description.rangeOfCharacter(from: set.inverted) != nil {
            return false
        }

        return true
    }
}
