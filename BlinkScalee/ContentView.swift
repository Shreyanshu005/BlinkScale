//
//  ContentView.swift
//  BlinkScalee
//
//  Root of the app. Deliberately has no NavigationStack — a single enum
//  drives every screen transition so the "aha moment" flow (catalog → detail
//  → analyzing → AR) reads as one continuous animated state machine rather
//  than a stack of pushed pages.
//

import SwiftUI

enum AppState: Equatable {
    case onboarding
    case home
    case catalog
    case productDetail(MockProduct)
    case analyzing(MockProduct)
    case arPreview(MockProduct, ProductDimensions)

    // Polished, pre-baked demo path — used when a product has real supplied
    // assets (photo + converted .usdz) instead of relying on live AI.
    case polishedProductPage(BlinkitProductPageContent)

    // "Find a table for my space" flow — independent of the product-preview
    // flow above; entered directly from the catalog screen.
    case spaceFitCapture
    case spaceFitAnalyzing(CapturedSpacePhoto)
    case spaceFitResult(SpaceEstimate, MockProduct?)
}

struct ContentView: View {
    // TEMPORARY for testing the polished product page + AR Quick Look
    // directly on launch, skipping the catalog. Nothing else was deleted —
    // set this back to `.catalog` (and revert the #Preview below) once
    // you're done checking the "View in your room" button.
    @State private var appState: AppState = .onboarding

    var body: some View {
        ZStack {
            switch appState {
            case .onboarding:
                OnboardingView(
                    onNext: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            appState = .home
                        }
                    }
                )
                .transition(.opacity)

            case .home:
                HomePlaceholderView(
                    onBrowseProducts: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            appState = .catalog
                        }
                    }
                )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))

            case .catalog:
                ProductCatalogView(
                    onSelectProduct: { product in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            // Route to the polished pre-baked page when real
                            // assets exist; otherwise fall through to the
                            // live-AI flow below.
                            if let polished = product.polishedPageContent {
                                appState = .polishedProductPage(polished)
                            } else {
                                appState = .productDetail(product)
                            }
                        }
                    },
                    onFindTableForSpace: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            appState = .spaceFitCapture
                        }
                    }
                )
                .transition(.opacity)

            case .productDetail(let product):
                ProductDetailView(
                    product: product,
                    onBack: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            appState = .catalog
                        }
                    },
                    onSeeInRoom: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            appState = .analyzing(product)
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))

            case .analyzing(let product):
                AnalysisView(
                    product: product,
                    onComplete: { dims in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            appState = .arPreview(product, dims)
                        }
                    },
                    onCancel: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            appState = .productDetail(product)
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))

            case .arPreview(let product, let dims):
                ARPreviewView(
                    product: product,
                    dimensions: dims,
                    onDone: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            appState = .catalog
                        }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))

            case .polishedProductPage(let content):
                BlinkitProductPageView(
                    content: content,
                    onBack: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            appState = .catalog
                        }
                    },
                    onAddToCart: {} // no cart model yet — button is decorative for the demo
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
                .ignoresSafeArea()

            case .spaceFitCapture:
                SpaceFitCaptureView(
                    onCancel: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            appState = .catalog
                        }
                    },
                    onPhotoCaptured: { photo in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            appState = .spaceFitAnalyzing(photo)
                        }
                    }
                )
                .transition(.opacity)

            case .spaceFitAnalyzing(let photo):
                SpaceFitAnalyzingView(
                    photo: photo,
                    onComplete: { estimate in
                        let match = TableMatcher.bestFit(for: estimate)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            appState = .spaceFitResult(estimate, match)
                        }
                    },
                    onCancel: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            appState = .catalog
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))

            case .spaceFitResult(let estimate, let match):
                SpaceFitResultView(
                    estimate: estimate,
                    recommendedTable: match,
                    onDone: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            appState = .catalog
                        }
                    },
                    onRetry: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            appState = .spaceFitCapture
                        }
                    }
                )
                .transition(.opacity)
            }
        }
    }
}

#Preview {
    ContentView()
}
