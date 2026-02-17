// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DetiZhivotnieApp",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "DetiZhivotnieApp",
            targets: ["DetiZhivotnieApp"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.18.0"),
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.3.0"),
    ],
    targets: [
        .target(
            name: "DetiZhivotnieApp",
            dependencies: [
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFunctions", package: "firebase-ios-sdk"),
                .product(name: "Lottie", package: "lottie-ios"),
            ]
        ),
    ]
)
