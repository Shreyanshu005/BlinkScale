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
        // Add an Image Set named "portronics_laptop_table" to Assets.xcassets
        // and it takes over from the SF Symbol placeholder automatically —
        // no other code changes needed.
        imageAssetNames: ["portronics_laptop_table"],
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
        // Same figures as the MockProduct catalog entry's referenceDimensionsCM
        // — kept in sync manually since the two models are deliberately
        // decoupled; this page shows them as ground truth, not an AI guess.
        dimensionsCM: (width: 60, height: 75, depth: 40),
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

    // MARK: - Rooted Jade Plant (plant_pot.usdz)
    // Size 3.9" × 9.8"  →  ~9.9 cm dia × ~24.9 cm tall. Out of stock in the
    // reference screenshot, so no MRP/discount shown and stock reads "Out of stock".
    static let rootedJadePlant = BlinkitProductPageContent(
        imageAssetNames: ["plant_pot"],
        imageSystemNames: Array(repeating: "leaf.fill", count: 3),
        imageTintHex: "3E7C4F",
        variantOptions: [
            VariantOption(label: "Plant Type", value: "Succulent"),
            VariantOption(label: "Placement", value: "Indoor")
        ],
        viewDetailsLabel: "View details",
        deliveryTimeLabel: "29 mins",
        rating: 4.5,
        reviewCount: 128,
        title: "Rooted Jade Plant with Self-Watering Pot",
        quantityLabel: "1 pc",
        stockLeftLabel: "Out of stock",
        priceRupees: 349,
        mrpRupees: nil,
        dimensionsCM: (width: 9.9, height: 24.9, depth: 9.9),
        bankOffer: nil,
        brand: BrandInfo(
            name: "Nurturing Green",
            subtitle: "Explore all products",
            iconSystemName: "leaf.fill"
        ),
        cartItemCount: 0,
        arModelResourceName: "plant_pot"
    )

    // MARK: - Ugaoo Lady Valentine (plant.usdz)
    // Breadth 10 cm, Length 20 cm (without packaging). ₹369, MRP ₹499 (26% off).
    static let ugaooLadyValentine = BlinkitProductPageContent(
        imageAssetNames: ["plant"],
        imageSystemNames: Array(repeating: "leaf.fill", count: 3),
        imageTintHex: "C46B8C",
        variantOptions: [
            VariantOption(label: "Type", value: "Live Plant"),
            VariantOption(label: "Shelf Life", value: "10 days")
        ],
        viewDetailsLabel: "View details",
        deliveryTimeLabel: "12 mins",
        rating: 4.5,
        reviewCount: 342,
        title: "Ugaoo Lady Valentine Aglaonema Plant",
        quantityLabel: "1 pc",
        stockLeftLabel: nil,
        priceRupees: 369,
        mrpRupees: 499,
        dimensionsCM: (width: 10, height: 20, depth: 10),
        bankOffer: nil,
        brand: BrandInfo(
            name: "Ugaoo",
            subtitle: "Explore all products",
            iconSystemName: "leaf.fill"
        ),
        cartItemCount: 0,
        arModelResourceName: "plant"
    )

    // MARK: - Nurturing Green ZZ Plant (plant2.usdz)
    // Size 4.5" × 10"  →  ~11.4 cm dia × ~25.4 cm tall. ₹400, MRP ₹549 (27% off).
    static let nurturingGreenZZ = BlinkitProductPageContent(
        imageAssetNames: ["plant2"],
        imageSystemNames: Array(repeating: "leaf.fill", count: 3),
        imageTintHex: "2F6B3A",
        variantOptions: [
            VariantOption(label: "Plant Type", value: "ZZ Plant"),
            VariantOption(label: "Placement", value: "Indoor")
        ],
        viewDetailsLabel: "View details",
        deliveryTimeLabel: "14 mins",
        rating: 4.5,
        reviewCount: 214,
        title: "Nurturing Green ZZ Plant with Self-Watering Pot",
        quantityLabel: "1 pc",
        stockLeftLabel: nil,
        priceRupees: 400,
        mrpRupees: 549,
        dimensionsCM: (width: 11.4, height: 25.4, depth: 11.4),
        bankOffer: nil,
        brand: BrandInfo(
            name: "Nurturing Green",
            subtitle: "Explore all products",
            iconSystemName: "leaf.fill"
        ),
        cartItemCount: 0,
        arModelResourceName: "plant2"
    )

    // MARK: - Solara Air Fryer (airfryer.usdz)
    // Breadth 30 cm, Height 30.5 cm, Length 24.5 cm (without packaging).
    // ₹3,699, MRP ₹9,999 (63% off). 4.5★ (208), 28 mins.
    static let solaraAirFryer = BlinkitProductPageContent(
        imageAssetNames: ["airfryer"],
        imageSystemNames: Array(repeating: "oven.fill", count: 3),
        imageTintHex: "1A1A1A",
        variantOptions: [
            VariantOption(label: "Capacity", value: "4.5 Ltr"),
            VariantOption(label: "Power", value: "1500 W")
        ],
        viewDetailsLabel: "View details",
        deliveryTimeLabel: "28 mins",
        rating: 4.5,
        reviewCount: 208,
        title: "Solara Air Fryer with See Through Window (4.5 ltr, 1500 W)",
        quantityLabel: "1 unit",
        stockLeftLabel: nil,
        priceRupees: 3_699,
        mrpRupees: 9_999,
        dimensionsCM: (width: 30, height: 30.5, depth: 24.5),
        bankOffer: nil,
        brand: BrandInfo(
            name: "Solara",
            subtitle: "Explore all products",
            iconSystemName: "oven.fill"
        ),
        cartItemCount: 0,
        arModelResourceName: "airfryer"
    )
}
