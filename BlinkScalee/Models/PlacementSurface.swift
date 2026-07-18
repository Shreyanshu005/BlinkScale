//
//  PlacementSurface.swift
//  BlinkScalee
//
//  Which real-world surface a product is meant to be placed against. Most of
//  today's catalog is floor items (tables, plants, an air fryer), but the
//  model exists so a future wall item (curtains, wall art, a wall clock) or
//  ceiling item (a pendant light) can declare it up front — and so the AR
//  flow can warn the user if they point at the wrong kind of surface (e.g.
//  trying to place a curtain on the floor) instead of silently dropping it
//  in the wrong place. Codable so it round-trips cleanly if this catalog
//  ever moves from Swift literals to a JSON file.
//
//  Note: ARKit itself only distinguishes `.horizontal`/`.vertical` plane
//  alignment — there's no native "ceiling" concept. `ARCoordinator` derives
//  floor vs. ceiling from a horizontal hit by comparing its height against
//  the camera's, so that distinction is a best-effort heuristic, not a
//  hardware-guaranteed one.
//

import Foundation

enum PlacementSurface: String, Codable, CaseIterable, Equatable {
    case floor
    case wall
    case ceiling

    var displayName: String {
        switch self {
        case .floor: return "floor"
        case .wall: return "wall"
        case .ceiling: return "ceiling"
        }
    }
}
