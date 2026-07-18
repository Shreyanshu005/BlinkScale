//
//  BlinkitProductPageContent+Samples.swift
//  BlinkScalee
//
//  Reference content matching the Portronics product page screenshot
//  exactly. Add more `static let` entries here as new product pages are
//  requested — BlinkitProductPageView itself never needs to change.
//

import Foundation

extension BlinkitProductPageContent {
    static let portronicsLaptopTable = BlinkitProductPageContent(
        imageSystemNames: Array(repeating: "studentdesk", count: 9),
        imageTintHex: "B33A2E",
        variantOptions: [
            VariantOption(label: "Colour", value: "Crimson Red"),
            VariantOption(label: "Type", value: "Laptop Table")
        ],
        viewDetailsLabel: "View details",
        deliveryTimeLabel: "29 mins",
        rating: 4.5,
        reviewCount: 599,
        title: "Portronics My Buddy D Adjustable Laptop Table (Crimson Red)",
        quantityLabel: "1 pc",
        stockLeftLabel: "3 left",
        priceRupees: 1_605,
        mrpRupees: 2_999,
        bankOffer: BankOffer(
            bankInitial: "A",
            bankTintHex: "9B2058",
            offerPriceRupees: 1_445,
            couponCode: "AXISNEO"
        ),
        brand: BrandInfo(
            name: "Portronics",
            subtitle: "Explore all products",
            iconSystemName: "p.square.fill"
        ),
        cartItemCount: 3,
        // Drop the converted "portronics_laptop_table.usdz" into the Xcode
        // project (any target-membership folder is fine) and this button
        // starts working immediately — no other code changes needed.
        arModelResourceName: "portronics_laptop_table"
    )
}
