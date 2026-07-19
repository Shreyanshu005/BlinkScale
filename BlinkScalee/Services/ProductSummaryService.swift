//
//  ProductSummaryService.swift
//  BlinkScalee
//

import CoreGraphics
import Foundation
import FoundationModels

@Generable
private struct ProductInsight: Codable {
    @Guide(description: "A friendly, useful product summary of 3 short sentences. Cover what it is, its best use or placement, and one grounded practical detail such as its size, quantity, or price. Use only the supplied catalog facts and image; do not invent specifications, availability, discounts, or claims.")
    var summary: String
}

@MainActor
final class ProductSummaryService {
    private let session = LanguageModelSession(
        instructions: Instructions {
            "You summarize catalog products for BlinkScalee. Be accurate and useful, using three short sentences so the shopper gets a meaningful overview. Only use supplied product information and the attached catalog image."
        }
    )

    func summary(for product: MockProduct) async -> String {
        guard case .available = SystemLanguageModel.default.availability else {
            return fallbackSummary(for: product)
        }

        let dims = product.referenceDimensionsCM
        let details = """
        Product name: \(product.name)
        Category: \(product.category)
        Catalog description: \(product.mockDescription)
        Size: \(dims.width) cm wide × \(dims.height) cm high × \(dims.depth) cm deep
        Quantity: \(product.weightOrSizeLabel)
        Price: \(product.priceRupees.asRupeeLabel)
        Placement: \(product.requiredSurface.displayName)
        """

        do {
            let response = try await session.respond(
                generating: ProductInsight.self,
                options: GenerationOptions(samplingMode: .greedy)
            ) {
                details
                if let image = product.catalogCGImage {
                    "Catalog product image:"
                    Attachment(image)
                }
            }
            let text = response.content.summary.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? fallbackSummary(for: product) : text
        } catch {
            return fallbackSummary(for: product)
        }
    }

    private func fallbackSummary(for product: MockProduct) -> String {
        let dims = product.referenceDimensionsCM
        return "\(product.mockDescription) It measures \(dims.width.formatted()) cm wide, \(dims.height.formatted()) cm high, and \(dims.depth.formatted()) cm deep. It is listed at \(product.priceRupees.asRupeeLabel) for \(product.weightOrSizeLabel)."
    }
}
