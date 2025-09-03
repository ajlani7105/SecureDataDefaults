//
//  Package.swift
//  SecureDataDefaults
//
//  Created by Abdulrhman Alhazmi on 03/09/2025.
//

import PackageDescription

let package = Package(
    name: "CustomAnimationLib",
    platforms: [.iOS(.v18)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CustomAnimationLib",
            targets: ["CustomAnimationLib"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CustomAnimationLib"),

    ]
)
