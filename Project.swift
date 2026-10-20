import ProjectDescription

let project = Project(
    name: "MassMates",
    packages: [
        .remote(
            url: "https://github.com/joaoigorandrade/NavigationPackage",
            requirement: .branch("main")
        ),
        .remote(
            url: "https://github.com/joaoigorandrade/NetworkingPackage",
            requirement: .branch("main")
        ),
    ],
    settings: .settings(
        base: [
            "SWIFT_VERSION": "6.0",
            "SWIFT_STRICT_CONCURRENCY": "complete",
            "SWIFT_DEFAULT_ACTOR_ISOLATION": "MainActor",
            "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
            "SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY": "YES",
            "DEVELOPMENT_TEAM": "G57UV8U7UG",
        ]
    ),
    targets: [
        .target(
            name: "MassMates",
            destinations: .iOS,
            product: .app,
            bundleId: "joaoigor.MassMates",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: ["MassMates/**/*.swift"],
            resources: ["MassMates/Assets.xcassets"],
            dependencies: [
                .package(product: "Navigation", type: .runtime),
                .package(product: "Networking", type: .runtime),
            ]
        ),
        .target(
            name: "MassMatesTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "joaoigor.MassMatesTests",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .default,
            sources: ["MassMatesTests/**/*.swift"],
            dependencies: [
                .target(name: "MassMates"),
                .package(product: "NetworkingTestSupport", type: .runtime),
            ]
        ),
    ]
)
