#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
import CommonCrypto
#endif
import Foundation

class Util {
    internal static let validKindCharacterSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-")
    internal static let validTagCharacterSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-")

    class func sha256base64(_ str: String) -> String {
        sha256(str).base64EncodedString()
    }

    class func sha256(_ str: String) -> Data {
        let data = Data(str.utf8)

        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &digest)
        }
        return Data(digest)
        #elseif os(Windows)
        return data.sha256Digest
        #else
        fatalError("\(#function) is unimplemented!")
        #endif
    }
}

extension String {
    func onlyContainsCharset(_ set: CharacterSet) -> Bool {
        if description.rangeOfCharacter(from: set.inverted) != nil {
            return false
        }

        return true
    }
}

#if os(Windows)
import WinSDK

extension Data {
    var sha256Digest: Data {
        func handleError(_ status: WinSDK.NTSTATUS) {
            // Failfast to mimic CryptoKit/Crypto semantics
            if status < 0 { fatalError("Failed to create SHA256 digest using BCrypt APIs (NTSTATUS: \(status))") }
        }

        let BCRYPT_SHA256_ALGORITHM = "SHA256"

        var algorithm: WinSDK.BCRYPT_ALG_HANDLE?
        BCRYPT_SHA256_ALGORITHM.withCString(encodedAs: UTF16.self) {
            handleError(WinSDK.BCryptOpenAlgorithmProvider(&algorithm, $0, nil, 0))
        }
        defer { handleError(WinSDK.BCryptCloseAlgorithmProvider(algorithm, 0)) }

        var hash: BCRYPT_HASH_HANDLE?
        handleError(WinSDK.BCryptCreateHash(algorithm, &hash, nil, 0, nil, 0, 0))
        defer { handleError(WinSDK.BCryptDestroyHash(hash)) }

        withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
            let input = UnsafeMutablePointer(mutating: buffer.baseAddress?.bindMemory(to: UInt8.self, capacity: buffer.count))
            handleError(WinSDK.BCryptHashData(hash, input, ULONG(buffer.count), 0))
        }

        var result = Data(count: 32) // Size of SHA256 hash
        result.withUnsafeMutableBytes { (buffer: UnsafeMutableRawBufferPointer) in
            let output = buffer.baseAddress?.bindMemory(to: UInt8.self, capacity: buffer.count)
            handleError(WinSDK.BCryptFinishHash(hash, output, ULONG(buffer.count), 0))
        }

        return result
    }
}

#endif
