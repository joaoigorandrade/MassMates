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
                    "SUPABASE_URL": "https://khovpljkitslmjmonuzu.supabase.co",
                    "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_K-dwtbcBgNqSAEJX4G8tVg_j_ozahqI",
                    "CFBundleURLTypes": [
                        [
                            "CFBundleURLName": "joaoigor.MassMates",
                            "CFBundleURLSchemes": ["massmates"],
                        ]
                    ],
                ]
            ),
            sources: ["MassMates/**/*.swift"],
            resources: ["MassMates/Assets.xcassets"],
            dependencies: [
                .package(product: "Navigation", type: .runtime),
                .package(product: "Networking", type: .runtime),
                .target(name: "MassMatesWidgets"),
            ]
        ),
        .target(
            name: "MassMatesWidgets",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "joaoigor.MassMates.Widgets",
            deploymentTargets: .iOS("26.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleDisplayName": "MassMates Widgets",
                    "NSExtension": [
                        "NSExtensionPointIdentifier": "com.apple.widgetkit-extension",
                    ],
                ]
            ),
            sources: [
                "MassMatesWidgets/**/*.swift",
                "MassMates/Features/PrayerTimer/Models/PrayerLiveActivityAttributes.swift",
            ],
            dependencies: []
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
