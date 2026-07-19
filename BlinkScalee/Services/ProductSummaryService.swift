//
//  ProductSummaryService.swift
//  BlinkScalee
//

import CoreGraphics
import Foundation
import FoundationModels

@Generable
private struct ProductInsight: Codable {
    @Guide(description: "A concise, friendly product summary in two sentences or fewer. Use only the supplied catalog facts and image; do not invent specifications, availability, discounts, or claims.")
    var summary: String
}

@MainActor
final class ProductSummaryService {
    private let session = LanguageModelSession(
        instructions: Instructions {
            "You summarize catalog products for BlinkScalee. Be accurate, useful, concise, and only use supplied product information and the attached catalog image."
        }
    )

    func summary(for product: MockProduct) async -> String {
        guard case .available = SystemLanguageModel.default.availability else {
            return product.mockDescription
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
            return text.isEmpty ? product.mockDescription : text
        } catch {
            return product.mockDescription
        }
    }
}
