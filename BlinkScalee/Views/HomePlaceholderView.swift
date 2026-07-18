//
//  HomePlaceholderView.swift
//  BlinkScalee
//

import SwiftUI

struct AppTabContainer: View {
    @Binding var selectedTab: AppTab
    let onSelectProduct: (MockProduct) -> Void
    let onFindForSpace: () -> Void

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: .home) {
                NavigationStack {
                    HomePlaceholderView(selectedTab: $selectedTab)
                }
            }

            Tab("Category", systemImage: "square.grid.2x2", value: .category) {
                NavigationStack {
                    ProductCatalogView(
                        onSelectProduct: onSelectProduct,
                        onFindForSpace: onFindForSpace
                    )
                }
            }

            Tab("Profile", systemImage: "person", value: .profile) {
                NavigationStack {
                    ProfilePlaceholderView()
                }
            }

            Tab(value: .search, role: .search) {
                NavigationStack {
                    SearchPlaceholderView()
                }
            }
        }
        .tint(Color.blinkitOrange)
        .toolbarBackground(AppPalette.background, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

struct HomePlaceholderView: View {
    @Binding var selectedTab: AppTab

    /// Slightly lighter than the app background, used for the top hero region.
    private let heroTop = Color(red: 32 / 255, green: 34 / 255, blue: 40 / 255)

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                AppPalette.background
                    .ignoresSafeArea()

                mascotHero(in: proxy.size)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    selectedTab = .profile
                } label: {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.blinkitOrange)
                }
                .accessibilityLabel("Profile")
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private func mascotHero(in size: CGSize) -> some View {
        let heroHeight = min(size.height * 0.34, 300)
        let domeWidth = size.width * 1.6
        let domeHeight = heroHeight * 0.9

        return ZStack(alignment: .bottom) {
            // Flat lighter top region.
            heroTop

            // Convex dome "ground" in the dark app color; only its top arc shows.
            Ellipse()
                .fill(AppPalette.background)
                .frame(width: domeWidth, height: domeHeight)
                .offset(y: domeHeight * 0.55)

            // Small mascot standing on the dome crest.
            Image("mascothappy")
                .resizable()
                .scaledToFit()
                .frame(width: min(size.width * 0.5, 220))
                .padding(.bottom, heroHeight * 0.06)
        }
        .frame(maxWidth: .infinity)
        .frame(height: heroHeight, alignment: .bottom)
        .clipped()
        .ignoresSafeArea(edges: .top)
    }
}

private struct SearchPlaceholderView: View {
    var body: some View {
        AppPalette.background
            .ignoresSafeArea()
            .navigationTitle("Search")
    }
}

private struct ProfilePlaceholderView: View {
    var body: some View {
        AppPalette.background
            .ignoresSafeArea()
            .navigationTitle("Profile")
    }
}

#Preview {
    AppTabContainer(
        selectedTab: .constant(.home),
        onSelectProduct: { _ in },
        onFindForSpace: {}
    )
}
