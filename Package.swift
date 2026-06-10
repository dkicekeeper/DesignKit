// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "DesignKit",
    platforms: [.iOS("26.0")],
    products: [
        // Single product bundling all three modules. Consumers `import DesignTokens`,
        // `import DesignSupport`, `import DesignComponents` as needed.
        .library(
            name: "DesignKit",
            targets: ["DesignTokens", "DesignSupport", "DesignComponents"]
        ),
    ],
    targets: [
        // Foundation: colors, spacing, typography, animation, modifiers. No dependencies.
        .target(
            name: "DesignTokens",
            resources: [.process("Resources/Fonts")]
        ),
        // Portable infrastructure: formatters, haptics, icon abstraction, IconView.
        .target(
            name: "DesignSupport",
            dependencies: ["DesignTokens"]
        ),
        // Pure presentation components built on Tokens + Support.
        .target(
            name: "DesignComponents",
            dependencies: ["DesignTokens", "DesignSupport"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
