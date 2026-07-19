//
//  RoomAdvisor.swift
//  BlinkScalee
//
//  Looks at a photo of the shopper's room (Foundation Models image input,
//  iOS 27) and recommends catalog products that would suit it — a short
//  Siri-style spoken line plus real, validated product matches. No
//  dimensions or fit math here (that's the AR flow's job); this is purely
//  "what would look good in this room."
//
//  Same shape as DimensionAnalyzer/ProductIntentResolver: one long-lived
//  LanguageModelSession, an availability pre-flight, and a graceful fallback
//  so the demo still works when Apple Intelligence isn't ready.
//

import Foundation
import FoundationModels
import CoreGraphics

@Generable
struct RoomRecommendation: Codable {
    @Guide(description: "One short, warm, Siri-style sentence about the room and what would suit it — e.g. 'This bright corner would love a leafy plant.' Never mention measurements, dimensions, or fit percentages.")
    var summary: String

    @Guide(description: "Names of catalog products that would look or work well in this room, copied EXACTLY as given in the provided catalog list — never invented. Empty array if nothing in the catalog suits it.")
    var recommendedProductNames: [String]

    @Guide(description: "A conservative estimate of the available width in centimeters for the main open area visible in the photo. Use familiar visual references when possible. Return 0 if the photo does not show a usable area.", .range(0...1_000))
    var availableWidthCM: Double

    @Guide(description: "A conservative estimate of the available depth for the main open area visible in the photo, in centimeters. Return 0 if it cannot be estimated.", .range(0...1_000))
    var availableDepthCM: Double
}

@MainActor
final class RoomAdvisor {

    /// Cap on how many recommendations to surface, even if the model returns more.
    private static let maxResults = 6

    static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    /// One long-lived session — not strictly needed for a single-shot photo
    /// analysis, but kept for consistency with the rest of the AI services
    /// and in case a future refinement turn reuses it.
    private let session: LanguageModelSession

    /// Reused for the fallback path — its keyword matching already handles a
    /// blank/short prompt sensibly.
    private let intentResolver = ProductIntentResolver()

    init() {
        session = LanguageModelSession(
            instructions: Instructions {
                """
                You are a home-decor shopping assistant for BlinkScalee, a \
                quick-commerce app selling furniture, plants, appliances, and \
                home decor. You'll be shown a photo of a shopper's room and a \
                fixed product catalog as a list of "Name (Category)" entries, \
                plus optionally what the shopper says they want.

                The shopper's stated request is a hard constraint: only \
                recommend from the eligible catalog items given in the prompt. \
                Look at the room's style, colors, empty spaces, and existing \
                furniture, and recommend which catalog products would look or \
                work well in it. Also make a conservative estimate of the main \
                open area's width and depth from visual cues such as familiar \
                furniture, doors, or floor tiles; return zero for either value \
                if the photo provides no reliable scale. Return ONLY product names that appear in the \
                catalog list, copied character-for-character — never invent a \
                name that isn't in the list. Write one short, friendly, \
                upbeat sentence about the room and your recommendation, in a \
                natural spoken-assistant voice — never mention measurements, \
                dimensions, or whether something "fits." If nothing in the \
                catalog suits the room, return an empty list and say so kindly.
                """
            }
        )
    }

    /// Analyzes `image` (and optional free-text `prompt`) against `catalog`,
    /// returning a spoken summary plus validated, real product matches.
    func recommend(image: CGImage, prompt: String, catalog: [MockProduct]) async -> (summary: String, products: [MockProduct]) {
        guard Self.isAvailable else { return await fallback(prompt: prompt, catalog: catalog) }

        do {
            let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
            // First resolve what the shopper asked for (for example,
            // "furniture"), then let the visual model rank ONLY those
            // products by how well they suit the photographed room.
            let eligibleProducts = trimmedPrompt.isEmpty
                ? catalog
                : await intentResolver.resolveMatches(prompt: trimmedPrompt, catalog: catalog)

            let catalogListing = eligibleProducts
                .map { product in
                    let dims = product.referenceDimensionsCM
                    return "- \(product.name) (\(product.category), \(dims.width)W × \(dims.height)H × \(dims.depth)D cm, \(product.requiredSurface.rawValue))"
                }
                .joined(separator: "\n")

            let promptLine = trimmedPrompt.isEmpty ? "" : "\nThe shopper also said: \"\(trimmedPrompt)\""

            let response = try await session.respond(
                generating: RoomRecommendation.self,
                options: GenerationOptions(samplingMode: .greedy)
            ) {
                """
                Eligible catalog (recommend only from this list):
                \(catalogListing)
                \(promptLine)

                Here's a photo of the shopper's room:
                """
                Attachment(image)
            }

            let content = response.content
            let matchedNames = Set(content.recommendedProductNames.map { $0.lowercased() })
            let validated = eligibleProducts.filter { matchedNames.contains($0.name.lowercased()) }

            let fitting = filterForEstimatedSpace(
                validated,
                availableWidthCM: content.availableWidthCM,
                availableDepthCM: content.availableDepthCM
            )
            guard !fitting.isEmpty else {
                return await fallback(
                    prompt: prompt,
                    catalog: eligibleProducts,
                    summary: content.summary
                )
            }

            let summary = content.summary.trimmingCharacters(in: .whitespacesAndNewlines)
            return (
                summary.isEmpty ? Self.defaultSummary : summary,
                Array(fitting.prefix(Self.maxResults))
            )
        } catch {
            return await fallback(prompt: prompt, catalog: catalog)
        }
    }

    /// Model-free (or empty-result) path: fall back to the keyword/AI intent
    /// resolver, capped the same way, with a friendly canned summary.
    private func fallback(
        prompt: String,
        catalog: [MockProduct],
        summary: String? = nil
    ) async -> (summary: String, products: [MockProduct]) {
        let matches = await intentResolver.resolveMatches(prompt: prompt, catalog: catalog)
        let products = Array(matches.prefix(Self.maxResults))
        let candidate = summary?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let text = candidate.isEmpty ? Self.defaultSummary : candidate
        return (text, products)
    }

    private static let defaultSummary = "Here are a few pieces that could make your space feel even more inviting. ✨"

    private func filterForEstimatedSpace(
        _ products: [MockProduct],
        availableWidthCM: Double,
        availableDepthCM: Double
    ) -> [MockProduct] {
        // A normal phone photo has no physical-depth calibration. If the
        // image lacks familiar scale cues, keep the visual recommendations
        // rather than incorrectly rejecting every product.
        guard availableWidthCM >= 10, availableDepthCM >= 10 else { return products }
        return ProductSpaceMatcher.fittingMatches(
            availableWidthCM: availableWidthCM,
            availableDepthCM: availableDepthCM,
            candidates: products
        )
    }
}
