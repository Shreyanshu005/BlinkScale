//
//  ProductIntent.swift
//  BlinkScalee
//
//  The AI contract for "what does the user's free-text request mean, against
//  our actual catalog?" Mirrors SpaceEstimate/ProductDimensions in spirit —
//  structured, @Generable output rather than parsed free text. Deliberately
//  returns catalog NAMES rather than a category enum, since names are the
//  concrete thing `ProductIntentResolver` can validate against real
//  MockProduct entries afterward (never trusting the model's output as final).
//

import Foundation
import FoundationModels

@Generable
struct ProductIntent: Codable, Equatable {
    @Guide(description: "Names of catalog products that match what the shopper is asking for, copied EXACTLY as given in the provided catalog list — never invented. Empty array if nothing in the catalog is relevant.")
    var matchedProductNames: [String]

    @Guide(description: "One short sentence on why these products were chosen (or why none were).")
    var reasoning: String
}
