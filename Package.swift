// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "WeChatTweak-CLI",
    platforms: [
        .macOS(.v10_11)
    ],
    products: [
        .executable(
            name: "wechattweak-cli",
            targets: [
                "WeChatTweak-CLI"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire", from: "4.9.1"),
        .package(url: "https://github.com/mxcl/PromiseKit", from: "6.16.2"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.2")
    ],
    targets: [
        .executableTarget(
            name: "WeChatTweak-CLI",
            dependencies: [
                "Alamofire",
                "PromiseKit",
                "insert_dylib",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .systemLibrary(
            name: "insert_dylib",
            path: "Sources/insert_dylib"
        )
    ]
)
