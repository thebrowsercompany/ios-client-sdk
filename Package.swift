// swift-tools-version:5.5

import PackageDescription

// Temporarily needed to keep the Windows SPM build under the symbol count.
let linkType: Product.Library.LibraryType = {
    #if os(Windows)
    .dynamic
    #else
    .static
    #endif
}()

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
            type: linkType,
            targets: ["LaunchDarkly"]),
    ],
    dependencies: [
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs.git", .exact("9.1.0")),
        .package(url: "https://github.com/Quick/Quick.git", .exact("7.3.0")),
        .package(url: "https://github.com/Quick/Nimble.git", .exact("13.0.0")),
        .package(url: "https://github.com/mattgallagher/CwlPreconditionTesting", .exact("2.1.2")),
        .package(name: "LDSwiftEventSource", url: "https://github.com/thebrowsercompany/swift-eventsource.git", .branchItem("main-bcny")),
    ],
    targets: packageTargets(),
    swiftLanguageVersions: [.v5])

func packageTargets() -> [Target] {
    var targets: [Target] = [
        .target(
            name: "LaunchDarkly",
            dependencies: launchDarklyDependencies(),
            path: "LaunchDarkly/LaunchDarkly",
            exclude: osSpecificExcludes(),
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ],
            linkerSettings: [
                .linkedLibrary("Cabinet", .when(platforms: [.windows]))
            ]),
        .testTarget(
            name: "LaunchDarklyTests",
            dependencies: osSpecificLDTestsDependencies(),
            path: "LaunchDarkly",
            exclude: ["LaunchDarklyTests/Info.plist", "LaunchDarklyTests/.swiftlint.yml"],
            sources: ["GeneratedCode", "LaunchDarklyTests"]),
    ]

    #if os(Windows)
    targets.append(.target(
        name: "OSLog",
        path: "LaunchDarkly/OSLog"))
    #endif

    return targets
}

func launchDarklyDependencies() -> [Target.Dependency] {
    var dependencies: [Target.Dependency] = [
        .product(name: "LDSwiftEventSource", package: "LDSwiftEventSource")
    ]

    #if os(Windows)
    dependencies.append(.target(name: "OSLog"))
    #endif

    return dependencies
}

func osSpecificLDTestsDependencies() -> [Target.Dependency] {
    #if os(Windows)
    [
        "LaunchDarkly",
        .target(name: "OSLog"),
        .product(name: "Quick", package: "Quick"),
        .product(name: "Nimble", package: "Nimble")
    ]
    #elseif os(Linux)
    [
        "LaunchDarkly",
        .product(name: "Quick", package: "Quick"),
        .product(name: "Nimble", package: "Nimble")
    ]
    #else
    [
        "LaunchDarkly",
        .product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs"),
        .product(name: "Quick", package: "Quick"),
        .product(name: "CwlPreconditionTesting", package: "CwlPreconditionTesting"),
        .product(name: "Nimble", package: "Nimble")
    ]
    #endif
}

func osSpecificExcludes() -> [String] {
    var exclusions = ["Support"]
    #if os(Linux) || os(Windows)
    exclusions.append("ObjectiveC")
    #endif

    return exclusions
}
