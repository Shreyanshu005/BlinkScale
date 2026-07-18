//
//  ProductDetailView.swift
//  BlinkScalee
//
//  Standard PDP, except for one button. "See it in your room" is the entire
//  pitch of this app compressed into a single tap target — it needs to feel
//  inevitable, not buried among other actions.
//

import SwiftUI

struct ProductDetailView: View {
    let product: MockProduct
    let onBack: () -> Void
    let onSeeInRoom: () -> Void

    @State private var pulse = false

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    heroImage

                    Text(product.category.uppercased())
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(product.name)
                        .font(.title2.weight(.bold))

                    Text("₹\(product.priceRupees)")
                        .font(.title3.weight(.semibold))

                    Text(product.weightOrSizeLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    seeInRoomButton
                        .padding(.top, 8)

                    Text("Not sure it'll fit? Preview it at real scale in your room before you buy.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
            }
        }
    }

    private var header: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
            }
            Spacer()
            Text("Product Details")
                .font(.headline)
            Spacer()
            Image(systemName: "chevron.left").opacity(0) // symmetry spacer
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private var heroImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor(hex: product.tintHex) ?? .systemGray).opacity(0.12))
            Image(systemName: product.imageSystemName)
                .font(.system(size: 120))
                .foregroundStyle(Color(UIColor(hex: product.tintHex) ?? .systemGray))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260)
    }

    private var seeInRoomButton: some View {
        Button(action: onSeeInRoom) {
            HStack {
                Image(systemName: "arkit")
                Text("See it in your room →")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.blinkitOrange)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .scaleEffect(pulse ? 1.02 : 1.0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

#Preview {
    ProductDetailView(product: MockProduct.all[0], onBack: {}, onSeeInRoom: {})
}
