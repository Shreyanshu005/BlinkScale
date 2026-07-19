//
//  UserProfile.swift
//  BlinkScalee
//

import Combine
import Foundation

@MainActor
final class UserProfile: ObservableObject {
    private enum Key {
        static let displayName = "profile.displayName"
        static let avatarData = "profile.avatarData"
    }

    @Published var displayName: String {
        didSet { UserDefaults.standard.set(displayName, forKey: Key.displayName) }
    }

    @Published var avatarData: Data? {
        didSet { UserDefaults.standard.set(avatarData, forKey: Key.avatarData) }
    }

    init() {
        displayName = UserDefaults.standard.string(forKey: Key.displayName) ?? "Shopper"
        avatarData = UserDefaults.standard.data(forKey: Key.avatarData)
    }
}
