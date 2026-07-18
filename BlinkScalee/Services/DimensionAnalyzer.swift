//
//  DimensionAnalyzer.swift
//  BlinkScalee
//
//  Thin wrapper around Foundation Models. This is the ONLY file that talks
//  to LanguageModelSession — every other layer depends on ProductDimensions,
//  never on the model directly, so we can swap prompting strategy or fall
//  back to a mock analyzer for demo safety without touching UI/AR code.
//

import Foundation
import FoundationModels
import CoreGraphics

enum DimensionAnalyzerError: LocalizedError {
    case modelUnavailable(String)
    case generationFailed(String)

    var errorDescription: String? {
        switch self {
        case .modelUnavailable(let reason):
            return "On-device AI isn't available right now (\(reason))."
        case .generationFailed(let reason):
            return "Couldn't analyze this product: \(reason)"
        }
    }
}

@MainActor
final class DimensionAnalyzer {

    /// Pre-flight check so callers (namely `AnalysisView`) can detect an
    /// unavailable model *before* spending time on a doomed generation call,
    /// and can distinguish "genuinely broken" from "just not ready yet" —
    /// e.g. Apple Intelligence disabled, model still downloading, or the
    /// device's Neural Engine doesn't meet the minimum bar. This is what
    /// backs the demo-safety fallback in AnalysisView.
    static var availabilityReason: String? {
        switch SystemLanguageModel.default.availability {
        case .available:
            return nil
        case .unavailable(let reason):
            return String(describing: reason)
        }
    }

    /// A single long-lived session per analyzer instance. Reusing it (rather
    /// than spinning up a fresh session per call) is what makes the "doesn't
    /// look right?" refinement flow work — the model retains context of what
    /// it already guessed and can course-correct instead of starting cold.
    private let session: LanguageModelSession

    init() {
        session = LanguageModelSession(
            instructions: Instructions {
                """
                You are a product dimension expert for an e-commerce grocery \
                and essentials app. You will be shown a product image and must \
                estimate its real-world physical dimensions in centimeters.

                Be precise and realistic — a user will place a virtual copy of \
                this object in their room using AR to judge whether it fits, so \
                accuracy matters more than being impressive. Reason from common \
                real-world product sizes (e.g. a standard 43-inch TV is roughly \
                95-100cm wide, a 1-liter bottle is roughly 25-28cm tall).

                Always choose the primitive shape (box, cylinder, sphere, or \
                lShape) that most closely matches the product's actual silhouette. \
                Report your confidence honestly — mark it low if the image is \
                ambiguous or you're unfamiliar with the exact product.
                """
            }
        )
    }

    /// One-shot analysis — used for the initial "See in Room" tap.
    func analyze(image: CGImage) async throws -> ProductDimensions {
        do {
            let response = try await session.respond(
                generating: ProductDimensions.self,
                options: GenerationOptions(samplingMode: .greedy)
            ) {
                "Analyze this product image and estimate its real-world dimensions."
                Attachment(image)
            }
            return response.content
        } catch {
            throw DimensionAnalyzerError.generationFailed(error.localizedDescription)
        }
    }

    /// Streaming variant for `AnalysisView` — yields partially-filled
    /// dimensions as the model generates them, so the UI can show fields
    /// populating one by one instead of a blank spinner.
    func streamAnalysis(image: CGImage) -> AsyncThrowingStream<ProductDimensions.PartiallyGenerated, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let stream = session.streamResponse(
                        generating: ProductDimensions.self,
                        options: GenerationOptions(samplingMode: .greedy)
                    ) {
                        "Analyze this product image and estimate its real-world dimensions."
                        Attachment(image)
                    }
                    for try await partial in stream {
                        continuation.yield(partial.content)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: DimensionAnalyzerError.generationFailed(error.localizedDescription))
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Re-analysis triggered by the "Doesn't look right?" button. Reuses the
    /// same session (and therefore the model's prior context) and injects
    /// the user's correction as added prompt context, per the plan's
    /// "re-runs analysis with added prompt context" spec.
    func refine(previous: ProductDimensions, userFeedback: String, image: CGImage) async throws -> ProductDimensions {
        do {
            let response = try await session.respond(
                generating: ProductDimensions.self,
                options: GenerationOptions(samplingMode: .greedy)
            ) {
                """
                Your previous estimate was \(previous.dimensionLabel), shape: \
                \(previous.shape.displayName). The user says: "\(userFeedback)". \
                Re-analyze the product image and provide a corrected estimate.
                """
                Attachment(image)
            }
            return response.content
        } catch {
            throw DimensionAnalyzerError.generationFailed(error.localizedDescription)
        }
    }
}
