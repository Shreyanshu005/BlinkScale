//
//  RoomAdvisor.swift
//  BlinkScalee
//
//  Room-photo recommendations use two independent, fresh Foundation Models
//  sessions: first classify the visible placement target, then recommend from
//  the small catalog subset that target permits. Keeping sessions per photo
//  prevents prior images/catalog prompts from influencing later captures.
//

import CoreGraphics
import Foundation
import FoundationModels
import OSLog

@Generable
enum RoomScene: String, Codable, Equatable {
    case tableSurface
    case openFloor
    case wall
    case other
}

@Generable
private struct RoomSceneAnalysis: Codable {
    @Guide(description: "Choose the one primary target in the photo: tableSurface for a visible table, desk, countertop, or shelf surface; openFloor for an empty usable floor area; wall for a photo mainly aimed at a vertical wall; or other.")
    var scene: RoomScene
}

@Generable
struct RoomRecommendation: Codable {
    @Guide(description: "One short, warm Siri-style sentence about this specific photographed area and the suggested products. Never mention measurements, dimensions, fit, or unavailable products.")
    var summary: String

    @Guide(description: "Unique catalog product names that suit this photographed area, copied EXACTLY from the supplied candidate catalog. Never invent a name and never choose a product outside the supplied candidate catalog.")
    var recommendedProductNames: [String]
}

/// Persists only the last three room-result sets. Product names are stable
/// catalog identifiers, unlike MockProduct UUIDs which change each launch.
private enum RoomRecommendationHistory {
    private static let key = "roomRecommendationHistory"
    private static let maximumScans = 3

    static func recentNames() -> Set<String> {
        Set((UserDefaults.standard.array(forKey: key) as? [[String]] ?? []).flatMap { $0 })
    }

    static func record(_ products: [MockProduct]) {
        var history = UserDefaults.standard.array(forKey: key) as? [[String]] ?? []
        history.append(products.map(\.name))
        UserDefaults.standard.set(Array(history.suffix(maximumScans)), forKey: key)
    }
}

@MainActor
final class RoomAdvisor {
    private static let maxResults = 6
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "BlinkScalee", category: "RoomAdvisor")

    static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    private let intentResolver = ProductIntentResolver()

    func recommend(image: CGImage, prompt: String, catalog: [MockProduct]) async -> (summary: String, products: [MockProduct]) {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasExplicitPrompt = !trimmedPrompt.isEmpty
        let intentMatches = hasExplicitPrompt
            ? await intentResolver.resolveMatches(prompt: trimmedPrompt, catalog: catalog)
            : catalog
        let requestedProducts = intentMatches.isEmpty ? catalog : intentMatches

        guard Self.isAvailable else {
            Self.logger.debug("Room advisor unavailable; using non-table catalog fallback")
            return fallback(from: fallbackCandidates(from: requestedProducts), recordHistory: true)
        }

        do {
            let scene = try await classify(image: image)
            let sceneCandidates = candidates(
                for: scene,
                explicitPrompt: hasExplicitPrompt,
                requestedProducts: requestedProducts
            )
            let eligibleProducts = hasExplicitPrompt
                ? sceneCandidates
                : freshCandidates(from: sceneCandidates)

            let products = try await recommendProducts(
                image: image,
                prompt: trimmedPrompt,
                candidates: eligibleProducts
            )
            RoomRecommendationHistory.record(products.products)
            Self.logger.debug("Room scene: \(String(describing: scene), privacy: .public); candidates: \(eligibleProducts.count); returned: \(products.products.count)")
            return products
        } catch {
            Self.logger.debug("Room advisor response failed: \(String(describing: error), privacy: .public)")
            // A failed visual request never falls through to the laptop table
            // or the whole unfiltered catalog.
            return fallback(from: fallbackCandidates(from: requestedProducts), recordHistory: true)
        }
    }

    private func classify(image: CGImage) async throws -> RoomScene {
        let session = LanguageModelSession(
            instructions: Instructions {
                "Classify only the primary placement target visible in the supplied room photo. Do not recommend products."
            }
        )
        let response = try await session.respond(
            generating: RoomSceneAnalysis.self,
            options: GenerationOptions(samplingMode: .greedy)
        ) {
            "Classify the photographed area."
            Attachment(image).label("room-photo")
        }
        return response.content.scene
    }

    private func recommendProducts(
        image: CGImage,
        prompt: String,
        candidates: [MockProduct]
    ) async throws -> (summary: String, products: [MockProduct]) {
        let session = LanguageModelSession(
            instructions: Instructions {
                """
                You are BlinkScalee's home-decor shopping assistant. Look at the
                supplied room photo and choose products only from the candidate
                catalog. Create a fresh, photo-specific summary each time. Do
                not repeat a generic response, invent products, or discuss
                dimensions, measurements, or fit.
                """
            }
        )
        let promptLine = prompt.isEmpty ? "" : "\nThe shopper explicitly asked for: \"\(prompt)\""
        let response = try await session.respond(
            generating: RoomRecommendation.self,
            options: GenerationOptions(samplingMode: .greedy)
        ) {
            """
            Candidate catalog (choose only exact names from this list):
            \(catalogListing(for: candidates))
            \(promptLine)

            Recommend products for this room photo:
            """
            Attachment(image).label("room-photo")
        }

        let selectedNames = Set(response.content.recommendedProductNames.map { $0.lowercased() })
        let selected = candidates.filter { selectedNames.contains($0.name.lowercased()) }
        let products = finalProducts(selected.isEmpty ? candidates : selected)
        let summary = response.content.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        return (summary.isEmpty ? productCopy(for: products) : summary, products)
    }

    private func candidates(
        for scene: RoomScene,
        explicitPrompt: Bool,
        requestedProducts: [MockProduct]
    ) -> [MockProduct] {
        guard !explicitPrompt else { return requestedProducts }

        switch scene {
        case .tableSurface:
            return requestedProducts.filter { $0.category == "Plants" }
        case .openFloor:
            return requestedProducts.filter { $0.name.localizedCaseInsensitiveContains("folding camping chair") }
        case .wall:
            return requestedProducts.filter { $0.requiredSurface == .wall }
        case .other:
            return requestedProducts.filter { !$0.name.localizedCaseInsensitiveContains("Portronics My Buddy") }
        }
    }

    private func freshCandidates(from candidates: [MockProduct]) -> [MockProduct] {
        let recentNames = RoomRecommendationHistory.recentNames()
        let fresh = candidates.filter { !recentNames.contains($0.name) }
        // A small candidate group, such as plants, may be exhausted. In that
        // case reusing it is better than returning no recommendation.
        return fresh.isEmpty ? candidates : fresh
    }

    private func fallbackCandidates(from products: [MockProduct]) -> [MockProduct] {
        let withoutLaptopTable = products.filter { !$0.name.localizedCaseInsensitiveContains("Portronics My Buddy") }
        return freshCandidates(from: withoutLaptopTable.isEmpty ? products : withoutLaptopTable)
    }

    private func fallback(from candidates: [MockProduct], recordHistory: Bool) -> (summary: String, products: [MockProduct]) {
        let products = finalProducts(candidates)
        if recordHistory { RoomRecommendationHistory.record(products) }
        return (productCopy(for: products), products)
    }

    private func catalogListing(for products: [MockProduct]) -> String {
        products.map { product in
            "- \(product.name) | Category: \(product.category) | Description: \(product.mockDescription) | Placement: \(product.requiredSurface.rawValue)"
        }
        .joined(separator: "\n")
    }

    private func finalProducts(_ candidates: [MockProduct]) -> [MockProduct] {
        var seenNames = Set<String>()
        return candidates.filter { seenNames.insert($0.name.lowercased()).inserted }
            .prefix(Self.maxResults)
            .map { $0 }
    }

    /// Only used when a model response has no text or model availability
    /// fails. This is product-specific catalog copy, never a repeated canned
    /// room summary.
    private func productCopy(for products: [MockProduct]) -> String {
        products.first?.mockDescription ?? ""
    }
}
