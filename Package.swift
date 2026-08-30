// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FocusPanel",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "FocusPanel", targets: ["FocusPanel"]),
        .library(name: "FocusPanelCore", targets: ["FocusPanelCore"])
    ],
    targets: [
        // Pure, UI-free logic. Fully unit-testable from the command line.
        .target(
            name: "FocusPanelCore"
        ),
        // The SwiftUI/AppKit macOS app. Bootstrapped via NSApplication so it
        // builds and runs from SwiftPM (`swift build` / `swift run`) without an
        // Xcode project.
        .executableTarget(
            name: "FocusPanel",
            dependencies: ["FocusPanelCore"],
            resources: [.copy("Resources/PressStart2P-Regular.ttf")]
        ),
        .testTarget(
            name: "FocusPanelCoreTests",
            dependencies: ["FocusPanelCore"]
        )
    ],
    swiftLanguageVersions: [.v5]
)
