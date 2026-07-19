//
//  BlipbluChatView.swift
//  BlinkScalee
//
//  The mascot sheet: "Blipblu", an on-device Apple Intelligence chat buddy.
//  Shows an animated greeting, a fun tagline (a preset instantly, then a
//  fresh model-generated one swapped in), and a conversational chat. When the
//  shopper asks to find something, real catalog matches render as tappable
//  cards that push the product page.
//
//  All model work goes through BlipbluChatService, which degrades gracefully
//  when Apple Intelligence isn't available, so this view never has to branch
//  on availability itself.
//

import SwiftUI

struct BlipbluChatView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var path = NavigationPath()
    @State private var messages: [BlipbluMessage] = []
    @State private var draft = ""
    @State private var isTyping = false
    @FocusState private var inputFocused: Bool

    // Typewriter greeting.
    private let greetingFull = "Hi, I'm Blipblu"
    @State private var greetingShown = ""
    @State private var didAnimateGreeting = false

    // Fun tagline: one preset shown instantly, replaced by a generated one.
    private static let presetFunLines = [
        "I love chocolate — do you? 🍫",
        "I dream in 3D furniture 🛋️",
        "I sniff out good deals a mile away 👃",
        "Houseplants are my besties 🌿",
        "I never, ever skip a snack 🍪"
    ]
    @State private var funLine = BlipbluChatView.presetFunLines.randomElement() ?? "Ready to shop? ✨"

    private let service = BlipbluChatService()

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                header
                Divider().overlay(Color.white.opacity(0.08))
                conversation
                inputBar
            }
            .background(AppPalette.background)
            // Tap anywhere (that isn't a control) to dismiss the keyboard —
            // simultaneous so product cards / buttons still register their taps.
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture().onEnded { inputFocused = false }
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(for: MockProduct.self) { product in
                ProductPageDestination(product: product)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await animateGreeting()
        }
        .task {
            await loadFunLine()
        }
    }

    // MARK: - Header (mascot + name + greeting + tagline)

    private var header: some View {
        VStack(spacing: 4) {
            Image("mascothappy")
                .resizable()
                .scaledToFit()
                .frame(width: 76, height: 76)

            Text("Blipblu")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            Text(greetingShown)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.blinkitOrange)
                // Reserve the line's height so the tagline below doesn't jump
                // as the greeting types itself in.
                .frame(minHeight: 20)

            Text(funLine)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .transition(.opacity)
                .id(funLine)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 0)
        .padding(.bottom, 12)
        .padding(.horizontal, 24)
    }

    // MARK: - Conversation list

    private var conversation: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    if messages.isEmpty {
                        emptyState
                    }
                    ForEach(messages) { message in
                        messageRow(message)
                            .id(message.id)
                    }
                    if isTyping {
                        typingIndicator
                            .id("typing")
                    }
                }
                .padding(16)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: messages.count) { scrollToBottom(proxy) }
            .onChange(of: isTyping) { scrollToBottom(proxy) }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ask me anything, or say what you need —")
                .foregroundStyle(.white.opacity(0.75))
            Text("\"find me a plant for my desk\"")
                .foregroundStyle(Color.blinkitOrange)
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    @ViewBuilder
    private func messageRow(_ message: BlipbluMessage) -> some View {
        switch message.role {
        case .user:
            HStack {
                Spacer(minLength: 40)
                Text(message.text)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.blinkitOrange.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        case .assistant:
            VStack(alignment: .leading, spacing: 10) {
                if !message.text.isEmpty {
                    Text(message.text)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                ForEach(message.products) { product in
                    chatProductCard(product)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var typingIndicator: some View {
        HStack(spacing: 6) {
            ProgressView()
                .controlSize(.small)
                .tint(.white.opacity(0.6))
            Text("Blipblu is thinking…")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.06))
        .clipShape(Capsule())
    }

    // MARK: - Product card in chat

    private func chatProductCard(_ product: MockProduct) -> some View {
        Button {
            path.append(product)
        } label: {
            HStack(spacing: 12) {
                productThumb(product)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(product.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 6) {
                        Text(product.priceRupees.asRupeeLabel)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                        if let mrp = product.mrpRupees {
                            Text(mrp.asRupeeLabel)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.4))
                                .strikethrough()
                        }
                    }
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(10)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func productThumb(_ product: MockProduct) -> some View {
        if let assetName = product.cardImageAssetName {
            Image(assetName)
                .resizable()
                .scaledToFill()
        } else {
            let tint = Color(UIColor(hex: product.tintHex) ?? .systemGray)
            ZStack {
                tint.opacity(0.18)
                Image(systemName: product.imageSystemName)
                    .font(.system(size: 22))
                    .foregroundStyle(tint)
            }
        }
    }

    // MARK: - Input bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Message Blipblu…", text: $draft, axis: .vertical)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .focused($inputFocused)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .onSubmit(send)

            Button(action: send) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(canSend ? Color.blinkitOrange : Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppPalette.background)
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isTyping
    }

    // MARK: - Actions

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isTyping else { return }

        messages.append(BlipbluMessage(role: .user, text: text, products: []))
        draft = ""
        isTyping = true

        Task {
            let result = await service.respond(to: text)
            isTyping = false
            messages.append(
                BlipbluMessage(role: .assistant, text: result.text, products: result.products)
            )
        }
    }

    private func animateGreeting() async {
        guard !didAnimateGreeting else { return }
        didAnimateGreeting = true
        greetingShown = ""
        for character in greetingFull {
            greetingShown.append(character)
            try? await Task.sleep(for: .milliseconds(55))
        }
    }

    private func loadFunLine() async {
        if let generated = await service.funGreeting() {
            withAnimation(.easeInOut(duration: 0.4)) {
                funLine = generated
            }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.2)) {
            if isTyping {
                proxy.scrollTo("typing", anchor: .bottom)
            } else if let last = messages.last?.id {
                proxy.scrollTo(last, anchor: .bottom)
            }
        }
    }
}

struct BlipbluMessage: Identifiable {
    enum Role { case user, assistant }

    let id = UUID()
    let role: Role
    let text: String
    let products: [MockProduct]
}

#Preview {
    BlipbluChatView()
}
