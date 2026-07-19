//
//  ProductSummarySheet.swift
//  BlinkScalee
//

import SwiftUI

struct ProductSummarySheet: View {
    let product: MockProduct
    @Environment(\.dismiss) private var dismiss

    @State private var summary = ""
    @State private var isLoading = true
    private let service = ProductSummaryService()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                productHeader

                Text("Summary")
                    .font(.title3.weight(.bold))

                if isLoading {
                    ProductSummaryShimmer()
                } else {
                    Text(summary)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.84))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppPalette.background)
            .navigationTitle("Product insight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: dismiss.callAsFunction)
                        .foregroundStyle(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            summary = await service.summary(for: product)
            isLoading = false
        }
    }

    private var productHeader: some View {
        HStack(spacing: 14) {
            productImage
                .frame(width: 68, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(product.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                Text(product.priceRupees.asRupeeLabel)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }
        }
    }

    @ViewBuilder
    private var productImage: some View {
        if let name = product.cardImageAssetName {
            Image(name)
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: product.imageSystemName)
                .font(.title)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.white.opacity(0.1))
        }
    }
}

private struct ProductSummaryShimmer: View {
    @State private var phase = -1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 5).frame(height: 16)
            RoundedRectangle(cornerRadius: 5).frame(height: 16)
            RoundedRectangle(cornerRadius: 5).frame(width: 210, height: 16)
        }
        .foregroundStyle(.white.opacity(0.12))
        .overlay {
            LinearGradient(
                colors: [.clear, .white.opacity(0.2), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .offset(x: phase * 420)
            .mask(
                RoundedRectangle(cornerRadius: 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
        }
        .clipped()
        .onAppear {
            withAnimation(.linear(duration: 1.15).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}
