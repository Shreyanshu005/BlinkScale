//
//  ProductIntentResolver.swift
//  BlinkScalee
//
//  Resolves the free-text "what are you looking for?" prompt from the Space
//  Fit flow against the REAL catalog. This file's only job is "which catalog
//  items is the user talking about"; it never touches dimensions or fit
//  logic.
//
//  Same anti-hallucination principle used throughout the catalog AI:
//  the model is only ever allowed to point at product names that are
//  literally present in the catalog list it was given. Anything it returns
//  that doesn't exactly match a real name is dropped, and a plain substring
//  fallback keeps the flow useful even if the model comes back empty.
//

import Foundation
import FoundationModels

@MainActor
final class ProductIntentResolver {

    private let session: LanguageModelSession

    init() {
        session = LanguageModelSession(
            instructions: Instructions {
                """
                You match a shopper's free-text request against a fixed \
                product catalog for a quick-commerce app. You'll be given the \
                full catalog as a list of "Name (Category)" entries, followed \
                by what the shopper typed in their own words — this could be \
                specific ("a table for my laptop") or vague ("something green \
                for this corner", "a snack maker").

                Return ONLY product names that appear in the catalog list, \
                copied character-for-character — never invent a name that \
                isn't in the list. If the request is vague, match every \
                catalog item whose category or purpose plausibly satisfies \
                it; casting a slightly wide net is fine. If truly nothing in \
                the catalog is relevant \
                to the request, return an empty list rather than guessing.
                """
            }
        )
    }

    /// Resolves `prompt` against `catalog`, returning only entries that are
    /// both named by the model AND really present in `catalog`. Falls back
    /// to a plain substring match (name/category vs. prompt) if the model
    /// errors out or comes back empty — same demo-safety pattern used by
    /// `DimensionAnalyzer`'s fallback dimensions.
    func resolveMatches(prompt: String, catalog: [MockProduct]) async -> [MockProduct] {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else { return catalog }

        do {
            let catalogListing = catalog
                .map { "- \($0.name) (\($0.category))" }
                .joined(separator: "\n")

            let response = try await session.respond(
                generating: ProductIntent.self,
                options: GenerationOptions(samplingMode: .greedy)
            ) {
                """
                Catalog:
                \(catalogListing)

                Shopper is looking for: "\(trimmedPrompt)"
                """
            }

            let matchedNames = Set(response.content.matchedProductNames.map { $0.lowercased() })
            let validated = catalog.filter { matchedNames.contains($0.name.lowercased()) }

            return validated.isEmpty ? Self.keywordFallback(prompt: trimmedPrompt, catalog: catalog) : validated
        } catch {
            return Self.keywordFallback(prompt: trimmedPrompt, catalog: catalog)
        }
    }

    /// Plain substring match in both directions (prompt contains category
    /// word, or product name/category contains the prompt), so short prompts
    /// like "plant" or "air fryer" still work even without the LLM.
    private static func keywordFallback(prompt: String, catalog: [MockProduct]) -> [MockProduct] {
        let needle = prompt.lowercased()
        let matches = catalog.filter { product in
            let name = product.name.lowercased()
            let category = product.category.lowercased()
            return needle.contains(category) || category.contains(needle)
                || needle.contains(name) || name.contains(needle)
        }
        // If even the keyword fallback finds nothing, don't show an empty
        // screen for a demo — surface the whole catalog rather than a dead end.
        return matches.isEmpty ? catalog : matches
    }
}
