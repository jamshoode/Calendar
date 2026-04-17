import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Color {
    init(hex: String) {
        var hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") { hex.removeFirst() }
        let scanner = Scanner(string: hex)
        var hexNumber: UInt64 = 0
        if scanner.scanHexInt64(&hexNumber) {
            let r = Double((hexNumber & 0xff0000) >> 16) / 255.0
            let g = Double((hexNumber & 0x00ff00) >> 8) / 255.0
            let b = Double(hexNumber & 0x0000ff) / 255.0
            self = Color(red: r, green: g, blue: b)
            return
        }
        self = Color.clear
    }
}

extension Color {
    static let appBackground = Color(hex: "#FFFFFF")
    static let appSurface = Color(hex: "#F7F7F8")
    static let appPrimary = Color(hex: "#0A84FF")
    static let appPrimaryVariant = Color(hex: "#0060DF")
    static let appAccent = Color(hex: "#32D74B")
    static let appMuted = Color(hex: "#8E8E93")
    static let appText = Color(hex: "#0C0C0C")
    static let neutral100 = Color(hex: "#FFFFFF")
    static let neutral200 = Color(hex: "#F2F2F4")
    static let neutral300 = Color(hex: "#E6E6E9")
    static let neutral400 = Color(hex: "#C7C7CC")
    static let neutral500 = Color(hex: "#8E8E93")
}
