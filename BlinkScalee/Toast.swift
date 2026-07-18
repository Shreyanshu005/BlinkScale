//
//  Toast.swift
//  BlinkScalee
//
//  Lightweight toast banner for transient status messages — e.g. the AR
//  wall/floor placement mismatch warning. Replaces the old inline warning
//  card that competed for the same screen space as the dimension/info card.
//
//  Usage:
//    ContentView().toastHost()                    // once, on the root view
//    ToastCenter.shared.success("Added to cart")
//    ToastCenter.shared.error("Point your camera at a wall instead")
//    ToastCenter.shared.show("Order on the way")
//

import SwiftUI

@MainActor
@Observable
final class ToastCenter {
    static let shared = ToastCenter()

    struct Toast: Equatable {
        let message: String
        let style: Style
    }

    enum Style {
        case info, success, error

        var icon: String {
            switch self {
            case .info: "info.circle.fill"
            case .success: "checkmark.circle.fill"
            case .error: "exclamationmark.triangle.fill"
            }
        }

        var tint: Color {
            switch self {
            case .info: Color.blinkitOrange
            case .success: .green
            case .error: .red
            }
        }
    }

    private(set) var current: Toast?
    private var dismissTask: Task<Void, Never>?

    private init() {}

    func show(_ message: String, style: Style = .info, duration: Duration = .seconds(2.6)) {
        dismissTask?.cancel()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            current = Toast(message: message, style: style)
        }
        switch style {
        case .success: UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .error: UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .info: break
        }
        dismissTask = Task {
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.25)) { self.current = nil }
        }
    }

    func success(_ message: String) { show(message, style: .success) }
    func error(_ message: String) { show(message, style: .error) }
}

private struct ToastHostModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let toast = ToastCenter.shared.current {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: toast.style.icon)
                        .foregroundStyle(toast.style.tint)
                    Text(toast.message)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .glassEffect(.regular, in: Capsule())
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

extension View {
    /// Attach once to the app's root view so toasts can slide in from the top anywhere.
    func toastHost() -> some View {
        modifier(ToastHostModifier())
    }
}

#Preview {
    ZStack {
        AppPalette.background.ignoresSafeArea()
        Button("Show toast") {
            ToastCenter.shared.error("This looks like a wall item — point your camera at a wall instead of the floor to place it.")
        }
        .foregroundStyle(.white)
    }
    .toastHost()
}
