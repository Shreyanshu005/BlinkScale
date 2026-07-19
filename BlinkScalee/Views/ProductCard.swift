//
//  ProductCard.swift
//  BlinkScalee
//
//  Single reusable product tile used everywhere a product needs to render
//  as a listing card — the main catalog grid, Space Fit's ranked matches,
//  and anywhere else products get shown side-by-side. Modeled directly on
//  Blinkit's own dark product-card design: photo, wishlist heart, optional
//  "Ad" tag, a quick-add button straddling the photo/footer seam, price +
//  strikethrough MRP, title, star rating, and delivery time. One visual,
//  reused by every page, instead of each screen inventing its own card.
//
//  Not wrapped in a `Button` itself — `onSelect` fires from a tap gesture on
//  the card's background layer, while `onAdd`/wishlist stay as their own
//  `Button`s layered on top. SwiftUI resolves overlapping hit-testing by
//  giving the front-most interactive control priority, so tapping the ADD
//  button never also triggers `onSelect`.
//

import SwiftUI

struct ProductCard: View {
    let product: MockProduct
    var badge: Badge? = nil
    /// Explicit hard width — pass the same value to every card in a grid.
    /// `.frame(maxWidth: .infinity)` alone is only a soft ceiling: if the
    /// footer row's content (label + spacer + ADD button) can't compress to
    /// fit the grid's naturally proposed column width, SwiftUI lets it
    /// report back LARGER than proposed, which is what pushed cards past
    /// the screen edge. A hard `width` forces genuine compression instead.
    /// `nil` (the default) lets the card size itself normally, for call
    /// sites that don't lay cards out in a fixed 2-column grid.
    var width: CGFloat? = nil
    var onSelect: () -> Void = {}
    var onAdd: () -> Void = {}

    enum Badge {
        case bestFit

        var label: String {
            switch self {
            case .bestFit: return "BEST FIT"
            }
        }
    }

    private var tintColor: Color {
        Color(UIColor(hex: product.tintHex) ?? .systemGray)
    }

    private var cardBackground: Color {
        Color(red: 0.07, green: 0.07, blue: 0.08)
    }

    /// Single shared horizontal inset for both the footer row and the
    /// details block, so they're guaranteed identical by construction —
    /// no risk of the two sections drifting to different literal numbers.
    private let contentInset: CGFloat = 20

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            imageArea
            footerBar
            detailsSection
        }
        .frame(width: width)
        // `.frame(width:)` alone is a PROPOSAL, not a hard clip — if any
        // nested content (e.g. the footer row's label + button) genuinely
        // can't compress to fit, the view can still report back and render
        // LARGER than this frame, and `.clipShape` below only clips to
        // whatever that (possibly oversized) final shape ends up being.
        // `.clipped()` unconditionally cuts rendering to this frame's own
        // bounds regardless of what the content wants — the actual fix for
        // cards bleeding past the screen edge on both sides.
        .clipped()
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }

    // MARK: - Image + overlays

    // Corner badges use `.overlay(alignment:)` rather than
    // `.frame(maxWidth: .infinity, maxHeight: .infinity, alignment:)` — the
    // latter inflates the child's own tappable hit area to the whole image
    // (not just its visible corner), which silently swallowed taps on the
    // photo itself before they ever reached the card's `onSelect`.
    private var imageArea: some View {
        Group {
            if let assetName = product.cardImageAssetName {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    tintColor.opacity(0.15)
                    Image(systemName: product.imageSystemName)
                        .font(.system(size: 48))
                        .foregroundStyle(tintColor)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 190)
        .clipped()
        .overlay(alignment: .bottomLeading) {
            if product.isSponsored {
                Text("Ad")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.black.opacity(0.45))
                    .clipShape(Capsule())
                    .padding(8)
            }
        }
        .overlay(alignment: .topLeading) {
            if let badge {
                Text(badge.label)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.blinkitOrange)
                    .clipShape(Capsule())
                    .padding(8)
            }
        }
    }

    // MARK: - Footer bar (quantity + quick-add)

    /// The semi-opaque strip right under the photo, holding the quantity
    /// label and the green "ADD" button. One flat HStack (no nested ZStack)
    /// so the background is unambiguously edge-to-edge on the card, with the
    /// label/button insets applied directly to themselves rather than via a
    /// separately-positioned overlay.
    private var footerBar: some View {
        HStack(spacing: 0) {
            Text(product.weightOrSizeLabel)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.leading, contentInset)

            Spacer(minLength: 12)

            // Flush against the card's own edge — no trailing inset — per
            // explicit request, unlike the text on the other side.
            addButton
        }
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(Color.white.opacity(0.1))
    }

    private var addButton: some View {
        Button(action: onAdd) {
            Text("ADD")
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(.green)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.green, lineWidth: 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Details (price, title, rating, delivery)

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            priceRow
            Text(product.name)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(2, reservesSpace: true)
            ratingRow
            deliveryRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, contentInset)
        .padding(.top, 12)
        .padding(.bottom, 14)
    }

    private var priceRow: some View {
        HStack(spacing: 6) {
            Text(product.priceRupees.asRupeeLabel)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            if let mrp = product.mrpRupees {
                Text(mrp.asRupeeLabel)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.4))
                    .strikethrough()
            }
        }
    }

    private var ratingRow: some View {
        HStack(spacing: 4) {
            HStack(spacing: 1) {
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: starSymbolName(for: index))
                        .font(.system(size: 10))
                        .foregroundStyle(Color(red: 1.0, green: 0.78, blue: 0.25))
                }
            }
            Text("\(product.reviewCount)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private func starSymbolName(for index: Int) -> String {
        let filled = Int(product.rating)
        let hasHalf = product.rating - Double(filled) >= 0.5
        if index < filled {
            return "star.fill"
        } else if index == filled && hasHalf {
            return "star.leadinghalf.fill"
        } else {
            return "star"
        }
    }

    private var deliveryRow: some View {
        HStack(spacing: 4) {
            Image(systemName: "circle.lefthalf.filled")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
            Text(product.deliveryTimeLabel)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}

#Preview {
    ScrollView {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(MockProduct.all) { product in
                ProductCard(product: product, badge: product.id == MockProduct.all.first?.id ? .bestFit : nil)
            }
        }
        .padding()
    }
    .background(.black)
}
