//
//  SpaceAnalyzer.swift
//  BlinkScalee
//
//  Mirrors DimensionAnalyzer's shape but solves the opposite problem:
//  instead of sizing a known product photographed in isolation, this
//  estimates the size of an empty gap in a user's own room photo, with no
//  stated measurement given. The model has to reason like a person eyeing
//  a room would — off door widths, floor tiles, baseboards, furniture of
//  familiar size — which is why the prompt leans hard on "look for known
//  reference objects" rather than just "measure this."
//

import Foundation
import FoundationModels
import CoreGraphics

@MainActor
final class SpaceAnalyzer {

    private let session: LanguageModelSession

    init() {
        session = LanguageModelSession(
            instructions: Instructions {
                """
                You are an interior space estimation expert. You will be shown \
                a photo of an empty area in someone's home (e.g. a corner, a \
                gap next to a sofa, an empty wall run) where they're considering \
                putting a table. The user has NOT told you the measurements —
                you must estimate the available width and depth yourself, \
                purely from visual cues in the photo.

                Look for common reference objects to anchor your scale estimate: \
                door widths (typically 80-90cm), floor tiles (often 30x30cm or \
                60x60cm), skirting boards, wall outlets (~8cm), light switches, \
                or any furniture of a familiar standard size. If a person is in \
                frame, use average human height (~165-175cm) as a reference.

                Be conservative — underestimate slightly rather than overestimate, \
                since a table that's too big to fit is a worse outcome than one \
                that's a bit smaller than necessary. Always explain which visual \
                cues you used in your reasoning, and mark confidence low if the \
                photo has few reliable reference points.
                """
            }
        )
    }

    /// One-shot estimate — used for the initial "Analyze my space" tap.
    func estimateSpace(image: CGImage) async throws -> SpaceEstimate {
        do {
            let response = try await session.respond(
                generating: SpaceEstimate.self,
                options: GenerationOptions(samplingMode: .greedy)
            ) {
                "Estimate the available width and depth of the empty space in this photo."
                Attachment(image)
            }
            return response.content
        } catch {
            throw DimensionAnalyzerError.generationFailed(error.localizedDescription)
        }
    }

    /// Streaming variant for `SpaceFitAnalyzingView`, matching the same
    /// field-by-field reveal used for product dimensions.
    func streamEstimate(image: CGImage) -> AsyncThrowingStream<SpaceEstimate.PartiallyGenerated, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let stream = session.streamResponse(
                        generating: SpaceEstimate.self,
                        options: GenerationOptions(samplingMode: .greedy)
                    ) {
                        "Estimate the available width and depth of the empty space in this photo."
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
}
