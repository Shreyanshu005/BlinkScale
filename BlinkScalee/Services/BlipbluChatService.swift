//
//  BlipbluChatService.swift
//  BlinkScalee
//
//  On-device chat brain for the Blipblu mascot sheet. Follows the same
//  Foundation Models pattern as DimensionAnalyzer/ProductIntentResolver: a
//  single long-lived LanguageModelSession, an availability pre-flight, and a
//  graceful fallback so the demo still works when Apple Intelligence isn't
//  ready (simulator, model downloading, feature disabled).
//
//  Two jobs:
//   1. Hold a friendly multi-turn conversation as "Blipblu".
//   2. When the shopper is trying to find something, hand the resolved query
//      to the EXISTING ProductIntentResolver so results are always validated
//      against real MockProduct entries — the model never invents products.
//

import Foundation
import FoundationModels

/// The AI contract for one chat turn: a spoken reply plus, when relevant, a
/// product-search intent. Kept alongside the service (rather than in Models/)
/// since nothing else consumes it.
@Generable
struct BlipbluReply: Codable {
    @Guide(description: "A short, warm, playful conversational reply in Blipblu's cheerful mascot voice — one or two sentences, an occasional emoji is fine.")
    var reply: String

    @Guide(description: "True only if the shopper is trying to find, shop for, or buy a product; false for greetings, thanks, chit-chat, or general questions.")
    var isProductSearch: Bool

    @Guide(description: "When isProductSearch is true, a concise description of what the shopper wants (e.g. 'a plant for my desk', 'air fryer', 'folding chair'). Empty string otherwise.")
    var productQuery: String
}

@MainActor
final class BlipbluChatService {

    /// Pre-flight so the view can skip a doomed model call and use canned
    /// copy instead. Same switch shape as `DimensionAnalyzer.availabilityReason`.
    static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    /// One long-lived session so Blipblu remembers the conversation across turns.
    private let session: LanguageModelSession

    /// Reused as-is — its own catalog validation + keyword fallback is exactly
    /// the "find me X against the real catalog" behavior we want here too.
    private let intentResolver = ProductIntentResolver()

    init() {
        session = LanguageModelSession(
            instructions: Instructions {
                """
                You are Blipblu, the cheerful shopping mascot for BlinkScalee — a \
                quick-commerce app that delivers furniture, plants, appliances, and \
                home decor in minutes and lets shoppers preview items in their room \
                with AR before buying.

                Chat in a warm, playful, concise voice: a sentence or two, an \
                occasional emoji, never a wall of text. When the shopper wants to \
                find, shop for, or buy something, set isProductSearch to true and \
                put a concise description of what they want in productQuery — the \
                app will then show them REAL matching products. For greetings, \
                thanks, or small talk, keep isProductSearch false and just reply \
                kindly. Never invent product names, prices, or availability \
                yourself; leave the actual product list to the app.
                """
            }
        )
    }

    /// One chat turn. Returns Blipblu's spoken line plus any real products to
    /// render as tappable cards beneath it.
    func respond(to message: String) async -> (text: String, products: [MockProduct]) {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return ("", []) }

        guard Self.isAvailable else { return await fallback(for: trimmed) }

        do {
            let response = try await session.respond(
                generating: BlipbluReply.self,
                options: GenerationOptions(samplingMode: .greedy)
            ) {
                "The shopper says: \"\(trimmed)\""
            }
            let content = response.content

            guard content.isProductSearch else { return (content.reply, []) }

            let query = content.productQuery.isEmpty ? trimmed : content.productQuery
            let products = await intentResolver.resolveMatches(prompt: query, catalog: MockProduct.all)
            return (content.reply, products)
        } catch {
            return await fallback(for: trimmed)
        }
    }

    /// Model-free path: lean on the resolver's keyword fallback. If it can't
    /// find a genuine match it returns the whole catalog — treat that as
    /// "no match" and reply conversationally instead of dumping everything.
    private func fallback(for message: String) async -> (text: String, products: [MockProduct]) {
        let products = await intentResolver.resolveMatches(prompt: message, catalog: MockProduct.all)
        if products.count == MockProduct.all.count {
            return ("Hi! I'm Blipblu 🐾 Tell me what you're looking for and I'll track it down for you!", [])
        }
        return ("Here's what I found for you! ✨", products)
    }

    /// One playful self-contained one-liner for the greeting area. Uses a
    /// throwaway session so it never pollutes the chat's conversation history.
    /// Returns nil on any failure so the caller keeps its preset line.
    func funGreeting() async -> String? {
        guard Self.isAvailable else { return nil }
        let greetingSession = LanguageModelSession(
            instructions: Instructions {
                "You are Blipblu, a cheerful shopping mascot. You write tiny, silly, lovable one-liners about yourself."
            }
        )
        do {
            let response = try await greetingSession.respond(
                options: GenerationOptions(samplingMode: .greedy)
            ) {
                """
                Write ONE short, playful line about yourself — silly and \
                lighthearted, in the spirit of "I love chocolate, do you?". \
                Maximum 8 words. Reply with just the line, no quotes.
                """
            }
            let cleaned = response.content
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            return cleaned.isEmpty ? nil : cleaned
        } catch {
            return nil
        }
    }
}
