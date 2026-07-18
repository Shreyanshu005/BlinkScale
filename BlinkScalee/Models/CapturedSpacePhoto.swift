//
//  CapturedSpacePhoto.swift
//  BlinkScalee
//
//  Thin Identifiable/Equatable wrapper around a user-captured CGImage.
//  CGImage itself isn't Equatable, so it can't live directly inside
//  `AppState` (which needs Equatable for its SwiftUI transitions). Same
//  identity-equality trick used for `MockProduct`: each capture gets a
//  unique id, and two captures are only "equal" if they're literally the
//  same capture instance.
//

import CoreGraphics
import Foundation

struct CapturedSpacePhoto: Identifiable, Equatable {
    let id = UUID()
    let cgImage: CGImage

    static func == (lhs: CapturedSpacePhoto, rhs: CapturedSpacePhoto) -> Bool {
        lhs.id == rhs.id
    }
}
