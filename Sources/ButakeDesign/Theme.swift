import SwiftUI
import AppKit
import os

/// RGB hex color stored in themes (`0xRRGGBB`).
public struct HexColor: Codable, Hashable, Sendable {
    public var value: UInt32
    public init(_ value: UInt32) { self.value = value }
    public var ns: NSColor { NSColor(srgbRed: CGFloat((value >> 16) & 0xFF) / 255, green: CGFloat((value >> 8) & 0xFF) / 255, blue: CGFloat(value & 0xFF) / 255, alpha: 1) }
    public var color: Color { Color(nsColor: ns) }
    public init(_ color: Color) {
        let ns = NSColor(color).usingColorSpace(.sRGB) ?? .black
        value = UInt32(round(ns.redComponent * 255)) << 16 | UInt32(round(ns.greenComponent * 255)) << 8 | UInt32(round(ns.blueComponent * 255))
    }
}

/// One concrete palette (a light or a dark variant). `background`, `surface` and `sidebar` nil = system colors.
public struct Theme: Codable, Hashable, Sendable {
    public var name: String
    public var isDark: Bool
    public var accent: HexColor
    public var background: HexColor?
    public var surface: HexColor?
    public var sidebar: HexColor?
    public var text: HexColor?
    public var addition: HexColor
    public var deletion: HexColor
    public var modified: HexColor
    public var renamed: HexColor
    public var warning: HexColor
    public var keyword: HexColor
    public var string: HexColor
    public var comment: HexColor
    public var number: HexColor
    public var type: HexColor
    public var variable: HexColor
    public var attribute: HexColor
    public var tag: HexColor
    public var function: HexColor
    public var graph: [HexColor]

    /// Identity used to rebuild AppKit views (diff, editor) when colors change.
    public var signature: Int { hashValue }
}

extension Theme {
    public static let butakeLight = Theme(
        name: "Butake Claro", isDark: false, accent: HexColor(0x0B8147),
        addition: HexColor(0x1A8C4D), deletion: HexColor(0xD12D2D), modified: HexColor(0x2F7FD8), renamed: HexColor(0x8E44C9), warning: HexColor(0xC2620A),
        keyword: HexColor(0xAD3DA4), string: HexColor(0xC41A16), comment: HexColor(0x6C7986), number: HexColor(0x1C00CF), type: HexColor(0x3F6E74),
        variable: HexColor(0x0F68A0), attribute: HexColor(0x815F03), tag: HexColor(0x0B4F79), function: HexColor(0x326D74),
        graph: [HexColor(0x19D79F), HexColor(0x2F7FD8), HexColor(0x22C55E), HexColor(0xF59E0B), HexColor(0x14B8A6)])
    public static let butakeDark = Theme(
        name: "Butake Oscuro", isDark: true, accent: HexColor(0x19D79F),
        addition: HexColor(0x54CC87), deletion: HexColor(0xFF6B6B), modified: HexColor(0x5AA7FF), renamed: HexColor(0xC084FC), warning: HexColor(0xF5A524),
        keyword: HexColor(0xFF7AB2), string: HexColor(0xFC6A5D), comment: HexColor(0x7F8C98), number: HexColor(0xD9C97C), type: HexColor(0x9EF1DD),
        variable: HexColor(0x67B7A4), attribute: HexColor(0xFD8F3F), tag: HexColor(0x5DD8FF), function: HexColor(0x67B7A4),
        graph: [HexColor(0x19D79F), HexColor(0x5AA7FF), HexColor(0x22C55E), HexColor(0xF59E0B), HexColor(0x2DD4BF)])
    /// Dracula palette (MIT, draculatheme.com): background #282A36, current line #44475A, foreground #F8F8F2.
    public static let draculaDark = Theme(
        name: "Drácula Oscuro", isDark: true, accent: HexColor(0xBD93F9),
        background: HexColor(0x21222C), surface: HexColor(0x282A36), sidebar: HexColor(0x21222C), text: HexColor(0xF8F8F2),
        addition: HexColor(0x50FA7B), deletion: HexColor(0xFF5555), modified: HexColor(0x8BE9FD), renamed: HexColor(0xFF79C6), warning: HexColor(0xFFB86C),
        keyword: HexColor(0xFF79C6), string: HexColor(0xF1FA8C), comment: HexColor(0x6272A4), number: HexColor(0xBD93F9), type: HexColor(0x8BE9FD),
        variable: HexColor(0xF8F8F2), attribute: HexColor(0x50FA7B), tag: HexColor(0xFF79C6), function: HexColor(0x50FA7B),
        graph: [HexColor(0xBD93F9), HexColor(0x50FA7B), HexColor(0xFF79C6), HexColor(0x8BE9FD), HexColor(0xFFB86C)])
    /// Dracula's light counterpart (Alucard palette, MIT): background #FFFBEB, foreground #1F1F1F.
    public static let draculaLight = Theme(
        name: "Drácula Claro", isDark: false, accent: HexColor(0x644AC9),
        background: HexColor(0xF5F1E1), surface: HexColor(0xFFFBEB), sidebar: HexColor(0xEFEBDA), text: HexColor(0x1F1F1F),
        addition: HexColor(0x14710A), deletion: HexColor(0xCB3A2A), modified: HexColor(0x036A96), renamed: HexColor(0xA3144D), warning: HexColor(0xA34D14),
        keyword: HexColor(0xA3144D), string: HexColor(0x846E15), comment: HexColor(0x6C664B), number: HexColor(0x644AC9), type: HexColor(0x036A96),
        variable: HexColor(0x1F1F1F), attribute: HexColor(0x14710A), tag: HexColor(0xA3144D), function: HexColor(0x14710A),
        graph: [HexColor(0x644AC9), HexColor(0x14710A), HexColor(0xA3144D), HexColor(0x036A96), HexColor(0xA34D14)])
}

/// Which theme is active: family (Butake, Drácula or custom), light/dark mode and the custom overrides.
@MainActor @Observable public final class ThemeStore {
    public static let shared = ThemeStore()

    public enum Family: String, CaseIterable, Identifiable { case butake, dracula, custom; public var id: String { rawValue } }
    public enum Mode: String, CaseIterable, Identifiable { case system, light, dark; public var id: String { rawValue } }
    /// Colors the customizer can change, applied over a base family.
    public enum Slot: String, CaseIterable, Identifiable, Codable {
        case accent, background, surface, addition, deletion, modified, renamed, warning
        public var id: String { rawValue }
    }

    public var family: Family { didSet { save() } }
    public var mode: Mode { didSet { save(); applyAppearance() } }
    public var customBase: Family { didSet { save() } }
    /// Overrides per variant: "light" / "dark" → slot → color.
    public var overrides: [String: [String: HexColor]] { didSet { save() } }
    public private(set) var systemIsDark: Bool { didSet { publish() } }
    /// Product shown in the Butake theme's name ("Butake Git Claro"); each app sets its own at launch.
    public var brandName = "Butake" { didSet { publish() } }
    /// Name of the custom theme, in the app's language.
    public var customName = "Personalizado" { didSet { publish() } }

    /// Copy of `theme` readable from any thread (AppKit drawing, syntax highlighting). Views on the
    /// main thread read `theme` instead, so they re-render when it changes.
    nonisolated private static let published = OSAllocatedUnfairLock(initialState: Theme.butakeLight)
    nonisolated public static var snapshot: Theme { published.withLock { $0 } }
    /// `theme` on the main thread (observed by SwiftUI), `snapshot` anywhere else.
    nonisolated public static var current: Theme {
        Thread.isMainThread ? MainActor.assumeIsolated { shared.theme } : snapshot
    }
    private func publish() {
        let value = theme
        Self.published.withLock { $0 = value }
    }

    private init() {
        let defaults = UserDefaults.standard
        family = Family(rawValue: defaults.string(forKey: "themeFamily") ?? "") ?? .butake
        // Migrates the previous appearance setting ("system" / "light" / "dark").
        mode = Mode(rawValue: defaults.string(forKey: "themeMode") ?? defaults.string(forKey: "appearance") ?? "") ?? .system
        customBase = Family(rawValue: defaults.string(forKey: "themeCustomBase") ?? "") ?? .butake
        overrides = (defaults.data(forKey: "themeOverrides")).flatMap { try? JSONDecoder().decode([String: [String: HexColor]].self, from: $0) } ?? [:]
        systemIsDark = NSApp?.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        DistributedNotificationCenter.default().addObserver(forName: .init("AppleInterfaceThemeChangedNotification"), object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { ThemeStore.shared.refreshSystemAppearance() }
        }
        publish()
    }

    public var isDark: Bool { mode == .dark || (mode == .system && systemIsDark) }
    public var variantKey: String { isDark ? "dark" : "light" }

    /// The palette in use now.
    public var theme: Theme {
        let source = family == .custom ? customBase : family
        var base = Self.palette(source, dark: isDark)
        if source == .butake { base.name = "\(brandName) \(isDark ? "Oscuro" : "Claro")" }
        guard family == .custom else { return base }
        return Self.apply(overrides[variantKey] ?? [:], to: base, name: customName)
    }

    public static func palette(_ family: Family, dark: Bool) -> Theme {
        switch family {
        case .dracula: dark ? .draculaDark : .draculaLight
        default: dark ? .butakeDark : .butakeLight
        }
    }
    public static func apply(_ values: [String: HexColor], to base: Theme, name: String) -> Theme {
        var theme = base; theme.name = name
        for (key, color) in values {
            switch Slot(rawValue: key) {
            case .accent: theme.accent = color
            case .background: theme.background = color; theme.sidebar = color
            case .surface: theme.surface = color
            case .addition: theme.addition = color
            case .deletion: theme.deletion = color
            case .modified: theme.modified = color
            case .renamed: theme.renamed = color
            case .warning: theme.warning = color
            case nil: break
            }
        }
        return theme
    }

    public func color(for slot: Slot) -> HexColor {
        let theme = theme
        switch slot {
        case .accent: return theme.accent
        case .background: return theme.background ?? resolved(.windowBackgroundColor, dark: theme.isDark)
        case .surface: return theme.surface ?? resolved(.textBackgroundColor, dark: theme.isDark)
        case .addition: return theme.addition
        case .deletion: return theme.deletion
        case .modified: return theme.modified
        case .renamed: return theme.renamed
        case .warning: return theme.warning
        }
    }
    /// A dynamic system color as it looks in the theme's light or dark appearance.
    private func resolved(_ color: NSColor, dark: Bool) -> HexColor {
        var value = HexColor(0)
        NSAppearance(named: dark ? .darkAqua : .aqua)?.performAsCurrentDrawingAppearance {
            let rgb = color.usingColorSpace(.sRGB) ?? .gray
            value = HexColor(UInt32(round(rgb.redComponent * 255)) << 16 | UInt32(round(rgb.greenComponent * 255)) << 8 | UInt32(round(rgb.blueComponent * 255)))
        }
        return value
    }
    public func set(_ slot: Slot, _ color: HexColor) {
        if family != .custom { customBase = family; family = .custom }
        overrides[variantKey, default: [:]][slot.rawValue] = color
    }
    public func resetCustom() { overrides[variantKey] = [:] }

    /// Dark themes force the dark system appearance (and light ones the light), so controls and text match.
    public func applyAppearance() {
        NSApp.appearance = switch mode {
        case .dark: NSAppearance(named: .darkAqua)
        case .light: NSAppearance(named: .aqua)
        case .system: nil
        }
        refreshSystemAppearance()
    }
    public func refreshSystemAppearance() {
        // With an explicit app appearance, NSApp reports that one; read the system's own setting instead.
        let dark = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
        if dark != systemIsDark { systemIsDark = dark }
    }
    private func save() {
        publish()
        let defaults = UserDefaults.standard
        defaults.set(family.rawValue, forKey: "themeFamily"); defaults.set(mode.rawValue, forKey: "themeMode")
        defaults.set(customBase.rawValue, forKey: "themeCustomBase")
        defaults.set(try? JSONEncoder().encode(overrides), forKey: "themeOverrides")
    }
}
