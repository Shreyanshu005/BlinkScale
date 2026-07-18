//
//  HomePlaceholderView.swift
//  BlinkScalee
//

import SwiftUI

struct AppTabContainer: View {
    @Binding var selectedTab: AppTab
    let onFindForSpace: () -> Void

    // Each tab keeps its own push/pop navigation history — tapping a
    // product (or, on Home, a category tile) appends to that tab's own
    // path, giving a real system push transition and interactive
    // swipe-back instead of the app's custom cross-fade state machine
    // (still used elsewhere by the Space Fit flow, which has no
    // NavigationStack of its own).
    @State private var homePath = NavigationPath()
    @State private var categoryPath = NavigationPath()
    @State private var searchPath = NavigationPath()

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: .home) {
                NavigationStack(path: $homePath) {
                    HomePlaceholderView(
                        onSelectProduct: { homePath.append($0) },
                        onSelectCategory: { category in
                            homePath.append(CategoryRoute(name: category.name))
                        },
                        onFindForSpace: onFindForSpace
                    )
                    .navigationDestination(for: MockProduct.self) { product in
                        ProductPageDestination(product: product)
                    }
                    .navigationDestination(for: CategoryRoute.self) { route in
                        CategoryDetailView(
                            category: route.name,
                            products: MockProduct.all.filter { $0.category == route.name },
                            onSelectProduct: { homePath.append($0) }
                        )
                    }
                }
            }

            Tab("Category", systemImage: "square.grid.2x2", value: .category) {
                NavigationStack(path: $categoryPath) {
                    ProductCatalogView(onSelectProduct: { categoryPath.append($0) })
                        .navigationDestination(for: MockProduct.self) { product in
                            ProductPageDestination(product: product)
                        }
                }
            }

            Tab(value: .search, role: .search) {
                NavigationStack(path: $searchPath) {
                    SearchProductsView(onSelectProduct: { searchPath.append($0) })
                        .navigationDestination(for: MockProduct.self) { product in
                            ProductPageDestination(product: product)
                        }
                }
            }
        }
        .tint(Color.blinkitOrange)
        .toolbarBackground(AppPalette.background, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

struct HomePlaceholderView: View {
    let onSelectProduct: (MockProduct) -> Void
    let onSelectCategory: (HouseholdCategory) -> Void
    let onFindForSpace: () -> Void

    private let heroHeight: CGFloat = 220

    var body: some View {
        ScrollView {
            heroSection

            HouseholdLifestyleSection(onSelectCategory: onSelectCategory)

            TopDealsSection(onSelectProduct: onSelectProduct)
        }
        .background(AppPalette.background)
        .scrollIndicators(.hidden)
        .toolbar(.hidden, for: .navigationBar)
    }

    /// Plain page background behind the mascot — no curved/colored region.
    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            Image("mascothappy")
                .resizable()
                .scaledToFit()
                .frame(width: 180)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .frame(height: heroHeight)
        .overlay(alignment: .topTrailing) {
            scanButton
                .padding(.top, 8)
                .padding(.trailing, 20)
        }
    }

    private var scanButton: some View {
        Button(action: onFindForSpace) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
        }
        // Solid, single-color fill — no gradient/material/shadow mixed in.
        .background(Color.blinkitOrange)
        .clipShape(Circle())
        .accessibilityLabel("Scan your space")
    }
}

private struct SearchProductsView: View {
    let onSelectProduct: (MockProduct) -> Void

    @State private var searchText = ""
    // Set once an on-device Apple Intelligence search has resolved the
    // current query to specific catalog names — e.g. "show me plants" maps
    // to just the Plants category, something a plain substring match could
    // never do (nothing in the catalog literally contains that phrase).
    // Reusing `ProductIntentResolver` — the same on-device FoundationModels
    // session already built for the Space Fit flow's free-text prompt.
    @State private var aiMatchedNames: Set<String>?
    @State private var isSearchingWithAI = false

    private let intentResolver = ProductIntentResolver()

    // Same horizontalPadding/columnGap pair used by TopDealsSection/
    // CategoryProductsSection/CategoryDetailView, so Home/Category/Search
    // all compute the identical hard card width.
    private let horizontalPadding: CGFloat = 16
    private let columnGap: CGFloat = 20
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    // Measured off the grid's own ACTUAL proposed width at render time —
    // `UIScreen.main.bounds.width` turned out to be unreliable in some
    // environments (returned a value that made cards render wider than the
    // real screen), so this reads the real, current width directly instead.
    @State private var cardWidth: CGFloat?

    /// Instant substring match shown live while typing, before the user
    /// submits and triggers the smarter AI understanding below.
    private var liveResults: [MockProduct] {
        guard !searchText.isEmpty else { return [] }
        return MockProduct.all.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.category.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Once the AI has resolved the current query, its (more literal
    /// understanding of) results replace the plain substring match.
    private var results: [MockProduct] {
        guard let aiMatchedNames else { return liveResults }
        return MockProduct.all.filter { aiMatchedNames.contains($0.name) }
    }

    var body: some View {
        Group {
            if searchText.isEmpty {
                ContentUnavailableView(
                    "Search BlinkScalee",
                    systemImage: "magnifyingglass",
                    description: Text("Find furniture, plants, and appliances")
                )
            } else if isSearchingWithAI {
                ProgressView("Understanding your search…")
                    .tint(Color.blinkitOrange)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if results.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: columnGap) {
                        ForEach(results) { product in
                            ProductCard(
                                product: product,
                                width: cardWidth,
                                onSelect: { onSelectProduct(product) }
                            )
                        }
                    }
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        (proxy.size.width - columnGap) / 2
                    } action: { newValue in
                        cardWidth = newValue
                    }
                    .padding(horizontalPadding)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppPalette.background)
        .navigationTitle("Search")
        .searchable(text: $searchText, prompt: "Search products")
        .onChange(of: searchText) {
            // Any further edit invalidates the previous AI understanding —
            // fall back to the instant live filter until submitted again.
            aiMatchedNames = nil
        }
        .onSubmit(of: .search) {
            Task { await runAISearch() }
        }
    }

    private func runAISearch() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        isSearchingWithAI = true
        let matches = await intentResolver.resolveMatches(prompt: query, catalog: MockProduct.all)
        aiMatchedNames = Set(matches.map { $0.name })
        isSearchingWithAI = false
    }
}

#Preview {
    AppTabContainer(
        selectedTab: .constant(.home),
        onFindForSpace: {}
    )
}
