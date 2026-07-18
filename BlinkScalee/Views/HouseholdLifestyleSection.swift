//
//  HouseholdLifestyleSection.swift
//  BlinkScalee
//
//  Reusable "Household & lifestyle" category shortcut grid — a heading plus
//  four tappable category cards. Self-contained so it can be dropped into any
//  screen without dragging along that screen's other layout.
//

import SwiftUI

struct HouseholdCategory: Identifiable {
    let id = UUID()
    let name: String
    let imageAssetName: String

    static let all: [HouseholdCategory] = [
        HouseholdCategory(name: "Home Decor", imageAssetName: "cat1"),
        HouseholdCategory(name: "Furniture", imageAssetName: "cat2"),
        HouseholdCategory(name: "Appliances", imageAssetName: "cat3"),
        HouseholdCategory(name: "Plants", imageAssetName: "cat4")
    ]
}

struct HouseholdLifestyleSection: View {
    var onSelectCategory: (HouseholdCategory) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Categories")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 28)

            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    ForEach(HouseholdCategory.all) { category in
                        HouseholdCategoryCard(category: category) {
                            onSelectCategory(category)
                        }
                    }
                }
                .padding(.horizontal, 28)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.vertical, 16)
    }
}

private struct HouseholdCategoryCard: View {
    let category: HouseholdCategory
    let onSelect: () -> Void

    private let cardWidth: CGFloat = 140
    private let cardHeight: CGFloat = 170

    var body: some View {
        Image(category.imageAssetName)
            .resizable()
            .scaledToFill()
            .frame(width: cardWidth, height: cardHeight)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture(perform: onSelect)
    }
}

#Preview {
    ScrollView {
        HouseholdLifestyleSection()
    }
    .background(AppPalette.background)
    .preferredColorScheme(.dark)
}
