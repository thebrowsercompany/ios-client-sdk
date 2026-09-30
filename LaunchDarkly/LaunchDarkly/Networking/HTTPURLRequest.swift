import Foundation
// Windows exports URLRequest from FoundationNetworking, not Foundation.
#if os(Windows)
import FoundationNetworking
#endif

extension URLRequest {
    struct HTTPMethods {
        static let get = "GET"
        static let post = "POST"
        static let report = "REPORT"
    }
}
