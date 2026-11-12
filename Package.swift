// swift-tools-version: 6.0
import PackageDescription
/// Shared design of the Butake macOS apps: themes (Butake, Drácula, custom) and the text size.
let package = Package(
    name: "ButakeDesign",
    platforms: [.macOS(.v14)],
    products: [.library(name: "ButakeDesign", targets: ["ButakeDesign"])],
    targets: [
        .target(name: "ButakeDesign"),
        .testTarget(name: "ButakeDesignTests", dependencies: ["ButakeDesign"]),
    ],
    swiftLanguageModes: [.v6]
)
