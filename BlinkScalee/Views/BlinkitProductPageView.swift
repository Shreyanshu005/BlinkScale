//
//  BlinkitProductPageView.swift
//  BlinkScalee
//
//  Reusable Blinkit-style dark-theme product page, built to match the
//  reference screenshot exactly (Portronics laptop table PDP). Takes a
//  BlinkitProductPageContent — feed it new content to generate a new page,
//  no view code changes needed.
//

import SwiftUI

struct BlinkitProductPageView: View {
    let content: BlinkitProductPageContent
    var onBack: () -> Void = {}
    var onAddToCart: () -> Void = {}

    @State private var carouselIndex = 0
    @State private var showARQuickLook = false
    @State private var arModelMissingAlert = false

    private var tintColor: Color {
        Color(UIColor(hex: content.imageTintHex) ?? .white)
    }

    // MARK: - Palette (sampled from the reference screenshot)

    private enum Palette {
        static let background = Color(red: 0.07, green: 0.07, blue: 0.08)
        static let variantPillBackground = Color(red: 0.15, green: 0.17, blue: 0.28)
        static let variantLabelText = Color(red: 0.56, green: 0.59, blue: 0.72)
        static let viewDetailsGreen = Color(red: 0.05, green: 0.24, blue: 0.12)
        static let addToCartGreen = Color(red: 0.11, green: 0.44, blue: 0.18)
        static let miniCartGreen = Color(red: 0.10, green: 0.46, blue: 0.19)
        static let starGold = Color(red: 1.0, green: 0.78, blue: 0.25)
        static let stockAmber = Color(red: 0.92, green: 0.58, blue: 0.25)
        static let bankMagenta = Color(red: 0.53, green: 0.12, blue: 0.32)
        static let hairline = Color.white.opacity(0.08)
    }

    /// Matches the reference's "₹1,605" / "MRP ₹2,999" comma-grouped style —
    /// plain string interpolation on an Int silently drops the separator.
    private func currency(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        return "₹" + (formatter.string(from: NSNumber(value: amount)) ?? "\(amount)")
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Palette.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    imageCarousel
                    paginationDots
                    viewInRoomButton
                    variantRow
                    detailsSection
                }
            }

            bottomBar
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showARQuickLook) {
            if let url = content.arModelURL {
                ARQuickLookView(modelURL: url)
                    .ignoresSafeArea()
            }
        }
        .alert("3D model not available yet", isPresented: $arModelMissingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Add the .usdz file to the app bundle to enable \"View in your room\" for this product.")
        }
    }

    /// Sits right under the carousel per the request to put the AR entry
    /// point "at the bottom of the image." Only appears when the content
    /// actually names a model — no dead button for products without one.
    @ViewBuilder
    private var viewInRoomButton: some View {
        if content.arModelResourceName != nil {
            Button {
                if content.arModelURL != nil {
                    showARQuickLook = true
                } else {
                    arModelMissingAlert = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arkit")
                    Text("View in your room")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Palette.variantPillBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
    }

    // MARK: - Image carousel

    /// Number of slides actually being shown — real photos if supplied,
    /// otherwise the SF Symbol placeholders. Used to size `paginationDots`
    /// to whichever source is active.
    private var slideCount: Int {
        content.imageAssetNames.isEmpty ? content.imageSystemNames.count : content.imageAssetNames.count
    }

    private var imageCarousel: some View {
        ZStack(alignment: .top) {
            TabView(selection: $carouselIndex) {
                if content.imageAssetNames.isEmpty {
                    ForEach(Array(content.imageSystemNames.enumerated()), id: \.offset) { index, symbolName in
                        ZStack {
                            tintColor.opacity(0.12)
                            Image(systemName: symbolName)
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(tintColor)
                                .padding(70)
                        }
                        .tag(index)
                    }
                } else {
                    ForEach(Array(content.imageAssetNames.enumerated()), id: \.offset) { index, assetName in
                        Image(assetName)
                            .resizable()
                            .scaledToFill()
                            .clipped()
                            .tag(index)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 380)

            topControls
        }
    }

    private var topControls: some View {
        HStack {
            circleButton(systemName: "chevron.down", action: onBack)
            Spacer()
            HStack(spacing: 10) {
                circleButton(systemName: "heart", action: {})
                circleButton(systemName: "magnifyingglass", action: {})
                circleButton(systemName: "square.and.arrow.up", action: {})
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func circleButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Color.black.opacity(0.4))
                .clipShape(Circle())
        }
    }

    private var paginationDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<max(slideCount, 1), id: \.self) { index in
                Circle()
                    .fill(index == carouselIndex ? Color.white : Color.clear)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.5), lineWidth: index == carouselIndex ? 0 : 1)
                    )
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.vertical, 12)
    }

    // MARK: - Variant selectors + View details

    private var variantRow: some View {
        HStack(spacing: 10) {
            ForEach(content.variantOptions) { option in
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.label)
                        .font(.caption2)
                        .foregroundStyle(Palette.variantLabelText)
                    Text(option.value)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Palette.variantPillBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer()

            Text(content.viewDetailsLabel)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Palette.viewDetailsGreen)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    // MARK: - Details section

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            deliveryRatingRow
                .padding(.top, 20)

            Text(content.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            quantityStockRow

            priceRow

            if let bankOffer = content.bankOffer {
                bankOfferCard(bankOffer)
            }

            if let brand = content.brand {
                brandCard(brand)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 140) // clears the fixed bottom bar
    }

    private var deliveryRatingRow: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.white)
                Text(content.deliveryTimeLabel)
                    .foregroundStyle(.white)
                    .fontWeight(.semibold)
            }

            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 1, height: 16)

            HStack(spacing: 3) {
                starRating
                Text("\(content.reviewCount)")
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .font(.subheadline)
    }

    private var starRating: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: starSymbolName(for: index))
                    .font(.caption)
                    .foregroundStyle(Palette.starGold)
            }
        }
    }

    private func starSymbolName(for index: Int) -> String {
        let filled = Int(content.rating)
        let hasHalf = content.rating - Double(filled) >= 0.5
        if index < filled {
            return "star.fill"
        } else if index == filled && hasHalf {
            return "star.leadinghalf.fill"
        } else {
            return "star"
        }
    }

    private var quantityStockRow: some View {
        HStack(spacing: 10) {
            Text(content.quantityLabel)
                .foregroundStyle(.white.opacity(0.8))

            if let stockLeftLabel = content.stockLeftLabel {
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 1, height: 14)

                Capsule()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 28, height: 14)
                    .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))

                Text(stockLeftLabel)
                    .foregroundStyle(Palette.stockAmber)
                    .fontWeight(.semibold)
            }
        }
        .font(.subheadline)
    }

    private var priceRow: some View {
        HStack(spacing: 8) {
            Text(currency(content.priceRupees))
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            if let mrp = content.mrpRupees {
                Text("MRP \(currency(mrp))")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.4))
                    .strikethrough()
            }
        }
    }

    private func bankOfferCard(_ offer: BlinkitProductPageContent.BankOffer) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(Palette.hairline).frame(height: 1)
            HStack(spacing: 12) {
                Text(offer.bankInitial)
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color(UIColor(hex: offer.bankTintHex) ?? UIColor(Palette.bankMagenta)))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Buy at \(currency(offer.offerPriceRupees))")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Apply Code: \(offer.couponCode)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                }

                Spacer()
            }
            .padding(.vertical, 14)
        }
    }

    private func brandCard(_ brand: BlinkitProductPageContent.BrandInfo) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(Palette.hairline).frame(height: 1)
            HStack(spacing: 12) {
                Image(systemName: brand.iconSystemName)
                    .font(.title3)
                    .foregroundStyle(.black)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(brand.name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Text(brand.subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.vertical, 14)
        }
    }

    // MARK: - Fixed bottom bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            if content.cartItemCount > 0 {
                miniCartPill
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(content.quantityLabel)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    HStack(spacing: 6) {
                        Text(currency(content.priceRupees))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                        if let mrp = content.mrpRupees {
                            Text("MRP \(currency(mrp))")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.4))
                                .strikethrough()
                        }
                    }
                    Text("Inclusive of all taxes")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                Button(action: onAddToCart) {
                    Text("Add to cart")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(Palette.addToCartGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Palette.background)
        }
    }

    private var miniCartPill: some View {
        HStack {
            Text("View cart")
                .font(.subheadline.weight(.bold))
            Spacer()
            Text("\(content.cartItemCount) Items")
                .font(.caption)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Palette.miniCartGreen)
        .clipShape(Capsule())
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

#Preview {
    BlinkitProductPageView(content: .portronicsLaptopTable)
}
