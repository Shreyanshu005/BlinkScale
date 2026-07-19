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
        arModelResourceName: "airfryer"
    )

    // MARK: - FunBlast Chair Cover (chair.usdz)
    // Size 19" × 26" × 18". ₹699, MRP ₹1,499 (53% off). Pack of 2.
    static let funBlastChairCover = BlinkitProductPageContent(
        imageAssetNames: ["chair"],
        imageSystemNames: Array(repeating: "sofa.fill", count: 3),
        imageTintHex: "6F4E37",
        variantOptions: [
            VariantOption(label: "Colour", value: "Coffee"),
            VariantOption(label: "Material", value: "Velvet")
        ],
        viewDetailsLabel: "View details",
        deliveryTimeLabel: "19 mins",
        rating: 4.5,
        reviewCount: 176,
        title: "FunBlast Premium Velvet Dining Chair Cover (Coffee) - Pack of 2",
        quantityLabel: "2 pcs",
        stockLeftLabel: nil,
        priceRupees: 699,
        mrpRupees: 1_499,
        dimensionsCM: (width: 48.3, height: 66.0, depth: 45.7),
        bankOffer: nil,
        brand: BrandInfo(
            name: "FunBlast",
            subtitle: "Explore all products",
            iconSystemName: "sofa.fill"
        ),
        arModelResourceName: "chair"
    )

    // MARK: - Decathlon Quechua Folding Camping Chair (chair2.usdz)
    // Folded size 82 × 17.5 × 17.5 cm. ₹1,799, MRP ₹1,999 (10% off).
    static let decathlonQuechuaChair = BlinkitProductPageContent(
        imageAssetNames: ["chair2"],
        imageSystemNames: Array(repeating: "sofa.fill", count: 3),
        imageTintHex: "2A6FB5",
        variantOptions: [
            VariantOption(label: "Colour", value: "Blue"),
            VariantOption(label: "Speciality", value: "Foldable")
        ],
        viewDetailsLabel: "View details",
        deliveryTimeLabel: "22 mins",
        rating: 4.5,
        reviewCount: 231,
        title: "Decathlon Quechua Folding Camping Chair (Blue)",
        quantityLabel: "1 pc",
        stockLeftLabel: nil,
        priceRupees: 1_799,
        mrpRupees: 1_999,
        dimensionsCM: (width: 82, height: 17.5, depth: 17.5),
        bankOffer: nil,
        brand: BrandInfo(
            name: "Decathlon",
            subtitle: "Explore all products",
            iconSystemName: "sofa.fill"
        ),
        arModelResourceName: "chair2"
    )

    // MARK: - Real Wood Wall Clock (clock.usdz)
    // Colour Mahogany. ₹1,299, MRP ₹2,599 (50% off). Sold by Bianca Home LLP.
    static let realWoodWallClock = BlinkitProductPageContent(
        imageAssetNames: ["clock"],
        imageSystemNames: Array(repeating: "clock.fill", count: 3),
        imageTintHex: "6F2C1E",
        variantOptions: [
            VariantOption(label: "Colour", value: "Mahogany"),
            VariantOption(label: "Material", value: "Wood")
        ],
        viewDetailsLabel: "View details",
        deliveryTimeLabel: "16 mins",
        rating: 4.5,
        reviewCount: 143,
        title: "Real Wood Wall Clock (Mahogany)",
        quantityLabel: "1 pc",
        stockLeftLabel: nil,
        priceRupees: 1_299,
        mrpRupees: 2_599,
        dimensionsCM: (width: 30, height: 30, depth: 5),
        bankOffer: nil,
        brand: BrandInfo(
            name: "Bianca Home",
            subtitle: "Explore all products",
            iconSystemName: "clock.fill"
        ),
        arModelResourceName: "clock",
        requiredSurface: .wall
    )

    // MARK: - Home Sizzler Blackout Door Curtain (curtain.usdz)
    // Size 48" × 84". ₹499, MRP ₹999 (50% off).
    static let homeSizzlerCurtain = BlinkitProductPageContent(
        imageAssetNames: ["curtain"],
        imageSystemNames: Array(repeating: "rectangle.fill", count: 3),
        imageTintHex: "5C3A21",
        variantOptions: [
            VariantOption(label: "Colour", value: "Brown"),
            VariantOption(label: "Curtain Type", value: "Blackout")
        ],
        viewDetailsLabel: "View details",
        deliveryTimeLabel: "11 mins",
        rating: 4.5,
        reviewCount: 267,
        title: "Home Sizzler Blackout Door Curtain (Brown, 48x84 inch)",
        quantityLabel: "1 pc",
        stockLeftLabel: nil,
        priceRupees: 499,
        mrpRupees: 999,
        dimensionsCM: (width: 121.9, height: 213.4, depth: 2),
        bankOffer: nil,
        brand: BrandInfo(
            name: "Home Sizzler",
            subtitle: "Explore all products",
            iconSystemName: "rectangle.fill"
        ),
        arModelResourceName: "curtain",
        requiredSurface: .wall
    )

    // MARK: - Ganesha Deepak Brass Wall Hanging (hanger.usdz)
    // Size 4.5" × 3" × 9". ₹824, MRP ₹1,999 (58% off).
    static let ganeshaDeepakHanger = BlinkitProductPageContent(
        imageAssetNames: ["hanger"],
        imageSystemNames: Array(repeating: "bell.fill", count: 3),
        imageTintHex: "D4AF37",
        variantOptions: [
            VariantOption(label: "Colour", value: "Golden"),
            VariantOption(label: "Material", value: "Brass")
        ],
        viewDetailsLabel: "View details",
        deliveryTimeLabel: "9 mins",
        rating: 4.5,
        reviewCount: 198,
        title: "Ganesha Deepak Brass Wall Hanging with Bell (Golden)",
        quantityLabel: "1 pc",
        stockLeftLabel: nil,
        priceRupees: 824,
        mrpRupees: 1_999,
        dimensionsCM: (width: 11.4, height: 22.9, depth: 7.6),
        bankOffer: nil,
        brand: BrandInfo(
            name: "Bianca Home",
            subtitle: "Explore all products",
            iconSystemName: "bell.fill"
        ),
        arModelResourceName: "hanger",
        requiredSurface: .wall
    )

    // MARK: - Mahal Karigari Ceramic Wall Plate (walldecor2.usdz)
    // Breadth/Length 20 cm (without packaging). ₹815, MRP ₹1,295 (37% off).
    static let mahalKarigariWallPlate = BlinkitProductPageContent(
        imageAssetNames: ["walldecor2"],
        imageSystemNames: Array(repeating: "circle.fill", count: 3),
        imageTintHex: "D96C3F",
        variantOptions: [
            VariantOption(label: "Colour", value: "Multicolour"),
            VariantOption(label: "Material", value: "Ceramic")
        ],
        viewDetailsLabel: "View details",
        deliveryTimeLabel: "13 mins",
        rating: 4.5,
        reviewCount: 154,
        title: "Mahal Karigari Ceramic Wall Plate (Multicolour)",
        quantityLabel: "1 pc",
        stockLeftLabel: nil,
        priceRupees: 815,
        mrpRupees: 1_295,
        dimensionsCM: (width: 20, height: 20, depth: 2),
        bankOffer: nil,
        brand: BrandInfo(
            name: "Chumbak",
            subtitle: "Explore all products",
            iconSystemName: "circle.fill"
        ),
        arModelResourceName: "walldecor2",
        requiredSurface: .wall
    )

    // MARK: - Owl Pyrite Stone by Astrotalk (walldecor3.usdz)
    // Dimensions 7 × 7 × 8 cm. ₹999, MRP ₹1,700 (41% off). Tabletop showpiece
    // (despite the "walldecor" asset name) — sits on a shelf/table, so it
    // uses `.floor` like the rest of the catalog's non-wall items.
    static let owlPyriteStone = BlinkitProductPageContent(
        imageAssetNames: ["walldecor3"],
        imageSystemNames: Array(repeating: "diamond.fill", count: 3),
        imageTintHex: "6E6E6E",
        variantOptions: [
            VariantOption(label: "Colour", value: "Metallic Gray"),
            VariantOption(label: "Material", value: "Pyrite, Resin")
        ],
        viewDetailsLabel: "View details",
        deliveryTimeLabel: "17 mins",
        rating: 4.5,
        reviewCount: 112,
        title: "Owl Pyrite Stone by Astrotalk",
        quantityLabel: "1 pc",
        stockLeftLabel: nil,
        priceRupees: 999,
        mrpRupees: 1_700,
        dimensionsCM: (width: 7, height: 8, depth: 7),
        bankOffer: nil,
        brand: BrandInfo(
            name: "Astrotalk",
            subtitle: "Explore all products",
            iconSystemName: "diamond.fill"
        ),
        arModelResourceName: "walldecor3"
    )
}
