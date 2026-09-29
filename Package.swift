// swift-tools-version:5.5

import PackageDescription

let launchDarklyDependencies: [Target.Dependency] = [
    .product(name: "LDSwiftEventSource", package: "LDSwiftEventSource")
]
var launchDarklyExcludes = ["Support"]
// Windows Swift does not support the SDK's Objective-C wrappers; the Swift API remains in the target.
#if os(Windows)
launchDarklyExcludes.append("ObjectiveC")
#endif

let launchDarklyTargets: [Target] = [
    .target(
        name: "LaunchDarkly",
        dependencies: launchDarklyDependencies,
        path: "LaunchDarkly/LaunchDarkly",
        exclude: launchDarklyExcludes,
        resources: [
            .process("PrivacyInfo.xcprivacy")
        ]),
    .testTarget(
        name: "LaunchDarklyTests",
        dependencies: [
            "LaunchDarkly",
            .product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs"),
            .product(name: "Quick", package: "Quick"),
            .product(name: "CwlPreconditionTesting", package: "CwlPreconditionTesting"),
            .product(name: "Nimble", package: "Nimble")
        ],
        path: "LaunchDarkly",
        exclude: ["LaunchDarklyTests/Info.plist", "LaunchDarklyTests/.swiftlint.yml"],
        sources: ["GeneratedCode", "LaunchDarklyTests"]),
]
let package = Package(
    name: "LaunchDarkly",
    platforms: [
        .iOS(.v13),
        .macOS(.v12),
        .watchOS(.v6),
        .tvOS(.v13)
    ],
    products: [
        .library(
            name: "LaunchDarkly",
            targets: ["LaunchDarkly"]),
    ],
    dependencies: [
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs.git", .exact("9.1.0")),
        .package(url: "https://github.com/Quick/Quick.git", .exact("4.0.0")),
        .package(url: "https://github.com/Quick/Nimble.git", .exact("9.2.1")),
        .package(url: "https://github.com/mattgallagher/CwlPreconditionTesting", .exact("2.1.2")),
        // BCNY's fork supports AnyURLSession for the stream, matching the Chromium transport used for HTTP.
        .package(name: "LDSwiftEventSource", url: "https://github.com/thebrowsercompany/swift-eventsource.git", .revision("f058fbe08c1ebb258b1f575b527fde13ee979181")),
    ],
    targets: launchDarklyTargets,
    swiftLanguageVersions: [.v5])
