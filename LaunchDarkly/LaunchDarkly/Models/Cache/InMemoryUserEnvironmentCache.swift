import Foundation

final class InMemoryUserEnvironmentCache: KeyedValueCaching {
  static let shared = InMemoryUserEnvironmentCache()

  private var cache = [String: Any]()

  func set(_ value: Any?, forKey: String) {
    cache[forKey] = value
  }

  func dictionary(forKey: String) -> [String : Any]? {
    cache[forKey] as? [String: Any]
  }

  func removeObject(forKey: String) {
    cache.removeValue(forKey: forKey)
  }
}
